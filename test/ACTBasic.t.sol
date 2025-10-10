// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ACT} from "../src/ACT.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ACTBasicTest
 * @dev Basic test suite for ACT Token
 */
contract ACTBasicTest is Test {
    ACT public token;
    address public deployer;
    address public user1;
    address public user2;
    uint256 public initialSupply = 1_000_000 * 10**18;

    function setUp() public {
        deployer = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy token with initial supply
        token = new ACT("ACT Token", "ACT", initialSupply);
    }

    function test_InitialSupply() public {
        assertEq(token.totalSupply(), initialSupply);
        assertEq(token.balanceOf(deployer), initialSupply);
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
        assertEq(token.balanceOf(deployer), initialSupply - transferAmount);
    }

    function test_Approve() public {
        uint256 approvalAmount = 500 * 10**18;

        token.approve(user1, approvalAmount);

        assertEq(token.allowance(deployer, user1), approvalAmount);
    }

    function test_TransferFrom() public {
        uint256 transferAmount = 1000 * 10**18;

        // Approve user1 to spend tokens
        token.approve(user1, transferAmount);

        // Impersonate user1 and transfer from deployer to user2
        vm.prank(user1);
        token.transferFrom(deployer, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(deployer), initialSupply - transferAmount);
        assertEq(token.allowance(deployer, user1), 0);
    }

    function testFuzz_Transfer(uint256 amount) public {
        // Bound the amount to be within the initial supply
        amount = bound(amount, 0, initialSupply);

        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(deployer), initialSupply - amount);
    }

    function test_RevertTransferInsufficientBalance() public {
        uint256 transferAmount = initialSupply + 1;

        vm.expectRevert();
        token.transfer(user1, transferAmount);
    }

    function test_RevertTransferFromInsufficientAllowance() public {
        uint256 transferAmount = 1000 * 10**18;

        // Don't approve, try to transfer
        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(deployer, user2, transferAmount);
    }
}
