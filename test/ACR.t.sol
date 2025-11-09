// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ACR} from "../src/ACR.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ACRTest
 * @dev Comprehensive test suite for ACR Token
 * Tests initialization, all token features, and upgrade functionality
 */
contract ACRTest is Test {
    ACR public token;
    ACR public implementation;
    ERC1967Proxy public proxy;

    address public owner;
    address public user1;
    address public user2;
    uint256 public initialSupply = 1_000_000 * 10**18;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy implementation
        implementation = new ACR();

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(
            ACR.initialize.selector,
            "ACR Token",
            "ACR",
            initialSupply
        );

        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Wrap proxy with interface
        token = ACR(address(proxy));
    }

    // ========== Initialization Tests ==========

    function test_Initialization() public view {
        assertEq(token.name(), "ACR Token");
        assertEq(token.symbol(), "ACR");
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(owner), initialSupply);
        assertEq(token.owner(), owner);
    }

    function test_CannotInitializeTwice() public {
        vm.expectRevert();
        token.initialize("New Token", "NEW", 1000);
    }

    function test_CannotInitializeImplementation() public {
        ACR newImpl = new ACR();
        vm.expectRevert();
        newImpl.initialize("Test", "TST", 1000);
    }

    // ========== Basic ERC20 Tests ==========

    function test_Transfer() public {
        uint256 transferAmount = 1000 * 10**18;
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), initialSupply - transferAmount);
    }

    function test_Approve() public {
        uint256 approvalAmount = 500 * 10**18;
        token.approve(user1, approvalAmount);
        assertEq(token.allowance(owner, user1), approvalAmount);
    }

    // ========== Mint Tests ==========

    function test_Mint() public {
        uint256 mintAmount = 100 * 10**18;
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }

    function test_RevertMintNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user1, 100 * 10**18);
    }

    // ========== Pause Tests ==========

    function test_Pause() public {
        token.pause();
        vm.expectRevert();
        token.transfer(user1, 100);
    }

    function test_Unpause() public {
        token.pause();
        token.unpause();
        token.transfer(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }

    function test_RevertPauseNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.pause();
    }

    // ========== Upgrade Tests ==========

    function test_UpgradeToNewImplementation() public {
        // Record state before upgrade
        string memory nameBefore = token.name();
        string memory symbolBefore = token.symbol();
        uint256 supplyBefore = token.totalSupply();
        uint256 balanceBefore = token.balanceOf(owner);
        address ownerBefore = token.owner();

        // Deploy new implementation
        ACR newImplementation = new ACR();

        // Upgrade
        token.upgradeToAndCall(address(newImplementation), "");

        // Verify state preserved after upgrade
        assertEq(token.name(), nameBefore);
        assertEq(token.symbol(), symbolBefore);
        assertEq(token.totalSupply(), supplyBefore);
        assertEq(token.balanceOf(owner), balanceBefore);
        assertEq(token.owner(), ownerBefore);

        // Verify token still works
        token.transfer(user1, 1000);
        assertEq(token.balanceOf(user1), 1000);
    }

    function test_RevertUpgradeNotOwner() public {
        ACR newImplementation = new ACR();

        vm.prank(user1);
        vm.expectRevert();
        token.upgradeToAndCall(address(newImplementation), "");
    }

    function test_UpgradePreservesComplexState() public {
        // Create complex state
        token.transfer(user1, 5000 * 10**18);
        token.transfer(user2, 3000 * 10**18);

        vm.prank(user1);
        token.delegate(user1); // Activate voting

        // Mint some tokens
        token.mint(user2, 1000 * 10**18);

        // Record balances and votes
        uint256 user1Balance = token.balanceOf(user1);
        uint256 user2Balance = token.balanceOf(user2);
        uint256 user1Votes = token.getVotes(user1);

        // Perform upgrade
        ACR newImpl = new ACR();
        token.upgradeToAndCall(address(newImpl), "");

        // Verify all state preserved
        assertEq(token.balanceOf(user1), user1Balance);
        assertEq(token.balanceOf(user2), user2Balance);
        assertEq(token.getVotes(user1), user1Votes);

        // Verify functionality still works
        vm.prank(user1);
        token.transfer(user2, 100);
        assertEq(token.balanceOf(user2), user2Balance + 100);
    }

    // ========== Voting Tests ==========

    function test_Delegation() public {
        token.transfer(user1, 1000 * 10**18);

        vm.prank(user1);
        token.delegate(user2);

        assertEq(token.getVotes(user2), 1000 * 10**18);
        assertEq(token.getVotes(user1), 0);
    }

    function test_VotingAfterUpgrade() public {
        // Setup voting before upgrade
        token.transfer(user1, 1000 * 10**18);
        vm.prank(user1);
        token.delegate(user1);

        uint256 votesBefore = token.getVotes(user1);

        // Upgrade
        ACR newImpl = new ACR();
        token.upgradeToAndCall(address(newImpl), "");

        // Votes should be preserved
        assertEq(token.getVotes(user1), votesBefore);

        // Should still be able to delegate after upgrade
        vm.prank(user1);
        token.delegate(user2);
        assertEq(token.getVotes(user2), 1000 * 10**18);
    }

    // ========== Burn Tests ==========

    function test_Burn() public {
        uint256 burnAmount = 100 * 10**18;
        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), initialSupply - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    function test_BurnAfterUpgrade() public {
        // Upgrade first
        ACR newImpl = new ACR();
        token.upgradeToAndCall(address(newImpl), "");

        // Burn should still work
        uint256 burnAmount = 100 * 10**18;
        token.burn(burnAmount);

        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    // ========== Integration Test ==========

    function test_CompleteWorkflowWithUpgrade() public {
        // Initial operations
        token.transfer(user1, 10000 * 10**18);
        token.mint(user2, 5000 * 10**18);

        vm.prank(user1);
        token.delegate(user1);

        // Pause
        token.pause();

        // Upgrade while paused
        ACR newImpl = new ACR();
        token.upgradeToAndCall(address(newImpl), "");

        // Unpause
        token.unpause();

        // Verify everything still works
        vm.prank(user1);
        token.transfer(user2, 1000 * 10**18);

        assertEq(token.balanceOf(user1), 9000 * 10**18);
        assertEq(token.balanceOf(user2), 6000 * 10**18);
    }
}
