// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ACT} from "../src/ACT.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ACTTest
 * @dev Comprehensive test suite for ACT Token
 */
contract ACTTest is Test {
    ACT public token;
    address public owner;
    address public user1;
    address public user2;
    uint256 public initialSupply = 1_000_000 * 10**18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Snapshot(uint256 id);
    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy token with initial supply
        token = new ACT("ACT Token", "ACT", initialSupply);
    }

    // ========== Basic ERC20 Tests ==========

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
    }

    function test_TokenMetadata() public view {
        assertEq(token.name(), "ACT Token");
        assertEq(token.symbol(), "ACT");
        assertEq(token.decimals(), 18);
    }

    function test_Transfer() public {
        uint256 transferAmount = 1000 * 10**18;

        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), initialSupply - transferAmount);
    }

    // ========== Ownable Tests ==========

    function test_Owner() public view {
        assertEq(token.owner(), owner);
    }

    function test_TransferOwnership() public {
        token.transferOwnership(user1);
        assertEq(token.owner(), user1);
    }

    function test_RevertTransferOwnershipNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transferOwnership(user2);
    }

    // ========== Mintable Tests ==========

    function test_Mint() public {
        uint256 mintAmount = 100 * 10**18;
        uint256 balanceBefore = token.balanceOf(user1);
        uint256 totalSupplyBefore = token.totalSupply();

        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), balanceBefore + mintAmount);
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount);
    }

    function test_RevertMintNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, 100 * 10**18);
    }

    // ========== Burnable Tests ==========

    function test_Burn() public {
        uint256 burnAmount = 100 * 10**18;
        uint256 balanceBefore = token.balanceOf(owner);
        uint256 totalSupplyBefore = token.totalSupply();

        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), balanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
    }

    function test_BurnFrom() public {
        uint256 burnAmount = 100 * 10**18;

        // Transfer tokens to user1
        token.transfer(user1, burnAmount * 2);

        // User1 approves owner to burn tokens
        vm.prank(user1);
        token.approve(owner, burnAmount);

        uint256 user1BalanceBefore = token.balanceOf(user1);
        uint256 totalSupplyBefore = token.totalSupply();

        // Owner burns from user1
        token.burnFrom(user1, burnAmount);

        assertEq(token.balanceOf(user1), user1BalanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
    }

    // ========== Pausable Tests ==========

    function test_Pause() public {
        token.pause();

        vm.expectRevert();
        token.transfer(user1, 100);
    }

    function test_Unpause() public {
        token.pause();
        token.unpause();

        // Should work after unpause
        token.transfer(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }

    function test_RevertPauseNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }

    function test_RevertUnpauseNotOwner() public {
        token.pause();

        vm.prank(user1);
        vm.expectRevert();
        token.unpause();
    }

    // ========== Checkpoint Tests (via ERC20Votes) ==========
    // Note: ERC20Snapshot was removed in OpenZeppelin v5.x
    // ERC20Votes provides checkpoint functionality instead

    function test_Checkpoints() public {
        // User1 must self-delegate to activate checkpoints
        vm.prank(user1);
        token.delegate(user1);

        // Transfer some tokens to user1
        token.transfer(user1, 1000 * 10**18);
        uint256 checkpoint1 = block.number;

        // Move to next block and transfer more
        vm.roll(block.number + 1);
        token.transfer(user1, 500 * 10**18);

        // Check current balance
        assertEq(token.balanceOf(user1), 1500 * 10**18);

        // Check voting power at previous block (checkpoint)
        assertEq(token.getPastVotes(user1, checkpoint1), 1000 * 10**18);
    }

    function test_MultipleCheckpoints() public {
        vm.prank(user1);
        token.delegate(user1);

        token.transfer(user1, 1000 * 10**18);
        uint256 checkpoint1 = block.number;

        vm.roll(block.number + 1);
        token.transfer(user1, 500 * 10**18);
        uint256 checkpoint2 = block.number;

        vm.roll(block.number + 1);
        token.transfer(user1, 250 * 10**18);

        assertEq(token.getPastVotes(user1, checkpoint1), 1000 * 10**18);
        assertEq(token.getPastVotes(user1, checkpoint2), 1500 * 10**18);
        assertEq(token.getVotes(user1), 1750 * 10**18);
    }

    function test_TotalSupplyCheckpoints() public {
        uint256 initialTotalSupply = token.totalSupply();
        uint256 checkpoint1 = block.number;

        vm.roll(block.number + 1);
        token.mint(user1, 1000 * 10**18);

        assertEq(token.getPastTotalSupply(checkpoint1), initialTotalSupply);
        assertEq(token.totalSupply(), initialTotalSupply + 1000 * 10**18);
    }

    // ========== Voting/Delegation Tests ==========

    function test_Delegation() public {
        // Transfer tokens to user1
        token.transfer(user1, 1000 * 10**18);

        // User1 delegates to user2
        vm.prank(user1);
        token.delegate(user2);

        // Check voting power
        assertEq(token.getVotes(user2), 1000 * 10**18);
        assertEq(token.getVotes(user1), 0);
    }

    function test_SelfDelegation() public {
        // Transfer tokens to user1
        token.transfer(user1, 1000 * 10**18);

        // User1 self-delegates
        vm.prank(user1);
        token.delegate(user1);

        // Check voting power
        assertEq(token.getVotes(user1), 1000 * 10**18);
    }

    function test_VotingPowerChangesWithBalance() public {
        // User1 self-delegates
        vm.prank(user1);
        token.delegate(user1);

        // Transfer tokens to user1
        token.transfer(user1, 1000 * 10**18);
        assertEq(token.getVotes(user1), 1000 * 10**18);

        // Transfer more tokens
        token.transfer(user1, 500 * 10**18);
        assertEq(token.getVotes(user1), 1500 * 10**18);
    }

    // ========== Permit Tests ==========

    function test_Nonces() public view {
        assertEq(token.nonces(owner), 0);
        assertEq(token.nonces(user1), 0);
    }

    function test_DomainSeparator() public view {
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        assertTrue(domainSeparator != bytes32(0));
    }

    // ========== Fuzz Tests ==========

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, initialSupply);

        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), initialSupply - amount);
    }

    function testFuzz_Mint(uint256 amount) public {
        // ERC20Votes has a safe supply limit to prevent checkpoint overflow
        // Max safe supply is ~10^59 (much less than uint256 max)
        uint256 maxSafeSupply = type(uint208).max;
        amount = bound(amount, 0, maxSafeSupply - initialSupply);

        uint256 totalSupplyBefore = token.totalSupply();
        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), totalSupplyBefore + amount);
    }

    function testFuzz_Burn(uint256 amount) public {
        amount = bound(amount, 0, initialSupply);

        uint256 totalSupplyBefore = token.totalSupply();
        token.burn(amount);

        assertEq(token.balanceOf(owner), initialSupply - amount);
        assertEq(token.totalSupply(), totalSupplyBefore - amount);
    }

    // ========== Integration Tests ==========

    function test_IntegrationPauseAndCheckpoints() public {
        // User1 self-delegates to activate checkpoints
        vm.prank(user1);
        token.delegate(user1);

        uint256 checkpoint1 = block.number;

        // Transfer tokens
        vm.roll(block.number + 1);
        token.transfer(user1, 1000 * 10**18);
        uint256 checkpoint2 = block.number;

        // Pause
        token.pause();

        // Transfers should fail
        vm.expectRevert();
        token.transfer(user1, 100);

        // Unpause
        token.unpause();

        // Transfers should work again
        vm.roll(block.number + 1);
        token.transfer(user1, 100 * 10**18);

        // Check checkpoints still work
        assertEq(token.getPastVotes(user1, checkpoint1), 0);
        assertEq(token.getPastVotes(user1, checkpoint2), 1000 * 10**18);
        assertEq(token.getVotes(user1), 1100 * 10**18);
    }

    function test_IntegrationBurnMintCheckpoints() public {
        // Create initial checkpoint
        uint256 checkpoint1 = block.number;
        uint256 supply1 = token.totalSupply();

        // Burn some tokens
        vm.roll(block.number + 1);
        token.burn(100 * 10**18);
        uint256 checkpoint2 = block.number;

        // Mint some tokens
        vm.roll(block.number + 1);
        token.mint(user1, 200 * 10**18);

        // Check current and historical supplies
        assertEq(token.totalSupply(), initialSupply + (100 * 10**18));
        assertEq(token.getPastTotalSupply(checkpoint1), supply1);
        assertEq(token.getPastTotalSupply(checkpoint2), initialSupply - (100 * 10**18));
    }
}
