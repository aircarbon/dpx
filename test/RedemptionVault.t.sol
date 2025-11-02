// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RedemptionVault} from "../src/RedemptionVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDT
 * @dev Mock USDT token with 6 decimals (like real USDT)
 */
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        _mint(msg.sender, 1_000_000_000 * 1e6); // 1 billion USDT
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MockFutureCarbonToken
 * @dev Mock FutureCarbonToken with 18 decimals and burnFrom functionality
 */
contract MockFutureCarbonToken is ERC20Burnable {
    constructor() ERC20("Mock Future Carbon Token", "MFCT") {
        _mint(msg.sender, 100_000_000 * 1e18); // 100 million tokens
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title RedemptionVaultTest
 * @dev Comprehensive test suite for RedemptionVault contract
 */
contract RedemptionVaultTest is Test {
    // Contracts
    RedemptionVault public vault;
    MockUSDT public usdt;
    MockFutureCarbonToken public futureToken;

    // Test accounts
    address public owner;
    address public user1;
    address public user2;
    address public attacker;

    // Events to test
    event RedemptionActivated(uint256 totalStablecoin, uint256 tokenSupply, uint256 redemptionRate);
    event TokensRedeemed(address indexed user, uint256 tokenAmount, uint256 stablecoinAmount);
    event VaultPaused(address indexed by);
    event VaultUnpaused(address indexed by);

    function setUp() public {
        // Create test accounts
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        attacker = makeAddr("attacker");

        // Deploy mock tokens
        usdt = new MockUSDT();
        futureToken = new MockFutureCarbonToken();

        // Deploy RedemptionVault
        vm.prank(owner);
        vault = new RedemptionVault(address(futureToken), address(usdt), owner);

        // Distribute tokens for testing
        futureToken.transfer(user1, 10_000_000 * 1e18); // 10M tokens
        futureToken.transfer(user2, 5_000_000 * 1e18);  // 5M tokens
        futureToken.transfer(attacker, 1_000_000 * 1e18); // 1M tokens

        // Distribute USDT for testing
        usdt.transfer(owner, 10_000_000 * 1e6); // 10M USDT to owner
    }

    // ============================================
    // Constructor Tests
    // ============================================

    function test_Constructor_Success() public {
        RedemptionVault newVault = new RedemptionVault(
            address(futureToken),
            address(usdt),
            owner
        );

        assertEq(address(newVault.futureToken()), address(futureToken));
        assertEq(address(newVault.stablecoin()), address(usdt));
        assertEq(newVault.owner(), owner);
        assertFalse(newVault.redemptionActive());
        assertEq(newVault.redemptionRatePerToken(), 0);
        assertEq(newVault.totalRedeemed(), 0);
    }

    function test_Constructor_RevertsOnZeroFutureToken() public {
        vm.expectRevert("Future token cannot be zero address");
        new RedemptionVault(address(0), address(usdt), owner);
    }

    function test_Constructor_RevertsOnZeroStablecoin() public {
        vm.expectRevert("Stablecoin cannot be zero address");
        new RedemptionVault(address(futureToken), address(0), owner);
    }

    function test_Constructor_RevertsOnZeroOwner() public {
        vm.expectRevert(); // OpenZeppelin Ownable throws OwnableInvalidOwner
        new RedemptionVault(address(futureToken), address(usdt), address(0));
    }

    // ============================================
    // activateRedemption() Tests
    // ============================================

    function test_ActivateRedemption_Success() public {
        // Setup: Deposit 1M USDT to vault
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        // Get initial token supply
        uint256 tokenSupply = futureToken.totalSupply();

        // Calculate expected rate
        uint256 expectedRate = (usdtAmount * 1e18) / tokenSupply;

        // Activate redemption
        vm.expectEmit(true, true, true, true);
        emit RedemptionActivated(usdtAmount, tokenSupply, expectedRate);

        vm.prank(owner);
        vault.activateRedemption();

        // Verify state
        assertTrue(vault.redemptionActive());
        assertEq(vault.redemptionRatePerToken(), expectedRate);
    }

    function test_ActivateRedemption_OnlyOwner() public {
        // Setup: Deposit USDT
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        // Try to activate as non-owner
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker));
        vault.activateRedemption();
    }

    function test_ActivateRedemption_RevertsWhenAlreadyActivated() public {
        // Setup and activate once
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Try to activate again
        vm.prank(owner);
        vm.expectRevert("Redemption already activated");
        vault.activateRedemption();
    }

    function test_ActivateRedemption_RevertsWhenNoStablecoinDeposited() public {
        // Try to activate without depositing USDT
        vm.prank(owner);
        vm.expectRevert("No stablecoin deposited");
        vault.activateRedemption();
    }

    function test_ActivateRedemption_RevertsWhenTokenSupplyIsZero() public {
        // Create a new token with 0 supply for this test
        MockFutureCarbonToken zeroToken = new MockFutureCarbonToken();
        uint256 totalSupply = zeroToken.totalSupply();
        zeroToken.burn(totalSupply); // Burn all tokens

        // Deploy new vault with zero-supply token
        vm.prank(owner);
        RedemptionVault zeroVault = new RedemptionVault(
            address(zeroToken),
            address(usdt),
            owner
        );

        // Deposit USDT
        vm.prank(owner);
        usdt.transfer(address(zeroVault), 1_000_000 * 1e6);

        // Try to activate
        vm.prank(owner);
        vm.expectRevert("Token supply is zero");
        zeroVault.activateRedemption();
    }

    function test_ActivateRedemption_RevertsWhenRateTooLow() public {
        // Edge case: Very small USDT amount compared to huge token supply
        // 1 wei of USDT / 100M tokens = rate rounds to 0
        vm.prank(owner);
        usdt.transfer(address(vault), 1); // 1 wei USDT

        vm.prank(owner);
        vm.expectRevert("Redemption rate too low");
        vault.activateRedemption();
    }

    function test_ActivateRedemption_DifferentRatios() public {
        // Test various USDT/token ratios
        uint256[] memory usdtAmounts = new uint256[](3);
        usdtAmounts[0] = 500_000 * 1e6;   // 500k USDT
        usdtAmounts[1] = 2_000_000 * 1e6; // 2M USDT
        usdtAmounts[2] = 100_000 * 1e6;   // 100k USDT

        for (uint256 i = 0; i < usdtAmounts.length; i++) {
            // Deploy new vault for each test
            vm.prank(owner);
            RedemptionVault testVault = new RedemptionVault(
                address(futureToken),
                address(usdt),
                owner
            );

            // Deposit USDT
            vm.prank(owner);
            usdt.transfer(address(testVault), usdtAmounts[i]);

            // Activate
            vm.prank(owner);
            testVault.activateRedemption();

            // Verify rate calculation
            uint256 expectedRate = (usdtAmounts[i] * 1e18) / futureToken.totalSupply();
            assertEq(testVault.redemptionRatePerToken(), expectedRate);
        }
    }

    // ============================================
    // swap() Tests - Success Cases
    // ============================================

    function test_Swap_Success() public {
        // Setup: Activate redemption
        uint256 usdtAmount = 1_000_000 * 1e6; // 1M USDT
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        // User1 approves vault to burn their tokens
        uint256 redeemAmount = 1_000_000 * 1e18; // 1M tokens
        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        // Calculate expected USDT
        uint256 rate = vault.redemptionRatePerToken();
        uint256 expectedUsdt = (redeemAmount * rate) / 1e18;

        // Get initial balances
        uint256 initialUserUsdt = usdt.balanceOf(user1);
        uint256 initialUserTokens = futureToken.balanceOf(user1);
        uint256 initialVaultUsdt = usdt.balanceOf(address(vault));
        uint256 initialSupply = futureToken.totalSupply();

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit TokensRedeemed(user1, redeemAmount, expectedUsdt);

        // Swap
        vm.prank(user1);
        vault.swap(redeemAmount);

        // Verify balances
        assertEq(usdt.balanceOf(user1), initialUserUsdt + expectedUsdt);
        assertEq(futureToken.balanceOf(user1), initialUserTokens - redeemAmount);
        assertEq(usdt.balanceOf(address(vault)), initialVaultUsdt - expectedUsdt);
        assertEq(futureToken.totalSupply(), initialSupply - redeemAmount);
        assertEq(vault.totalRedeemed(), expectedUsdt);
    }

    function test_Swap_PartialRedemption() public {
        // Setup
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        // User1 redeems half their tokens
        uint256 user1Balance = futureToken.balanceOf(user1);
        uint256 redeemAmount = user1Balance / 2;

        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vault.swap(redeemAmount);

        // Verify user still has tokens left
        assertEq(futureToken.balanceOf(user1), user1Balance - redeemAmount);
        assertTrue(futureToken.balanceOf(user1) > 0);
    }

    function test_Swap_MultipleUsers() public {
        // Setup
        uint256 usdtAmount = 10_000_000 * 1e6; // 10M USDT
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 rate = vault.redemptionRatePerToken();

        // User1 redeems
        uint256 user1Amount = 5_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), user1Amount);
        vm.prank(user1);
        vault.swap(user1Amount);

        uint256 user1Usdt = (user1Amount * rate) / 1e18;
        assertEq(usdt.balanceOf(user1), user1Usdt);

        // User2 redeems
        uint256 user2Amount = 3_000_000 * 1e18;
        vm.prank(user2);
        futureToken.approve(address(vault), user2Amount);
        vm.prank(user2);
        vault.swap(user2Amount);

        uint256 user2Usdt = (user2Amount * rate) / 1e18;
        assertEq(usdt.balanceOf(user2), user2Usdt);

        // Verify total redeemed
        assertEq(vault.totalRedeemed(), user1Usdt + user2Usdt);
    }

    function test_Swap_ExactVaultBalance() public {
        // Setup with exact amount that can be redeemed
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 rate = vault.redemptionRatePerToken();

        // Calculate exact token amount that matches vault balance
        // tokenAmount = (usdtAmount * 1e18) / rate
        uint256 tokenAmount = (usdtAmount * 1e18) / rate;

        // Mint exact amount needed to user1
        futureToken.mint(user1, tokenAmount);

        vm.prank(user1);
        futureToken.approve(address(vault), tokenAmount);

        vm.prank(user1);
        vault.swap(tokenAmount);

        // Vault should have very little or no USDT left (accounting for rounding)
        assertTrue(usdt.balanceOf(address(vault)) < 100); // Less than 100 wei
    }

    // ============================================
    // swap() Tests - Failure Cases
    // ============================================

    function test_Swap_RevertsBeforeActivation() public {
        // Try to swap before activation
        uint256 redeemAmount = 1_000_000 * 1e18;

        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vm.expectRevert("Redemption not activated");
        vault.swap(redeemAmount);
    }

    function test_Swap_RevertsWhenPaused() public {
        // Setup and activate
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Pause
        vm.prank(owner);
        vault.pause();

        // Try to swap
        uint256 redeemAmount = 1_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vm.expectRevert();
        vault.swap(redeemAmount);
    }

    function test_Swap_RevertsOnZeroAmount() public {
        // Setup
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Try to swap 0 tokens
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        vault.swap(0);
    }

    function test_Swap_RevertsWithoutApproval() public {
        // Setup
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Try to swap without approval
        uint256 redeemAmount = 1_000_000 * 1e18;

        vm.prank(user1);
        vm.expectRevert(); // ERC20 insufficient allowance
        vault.swap(redeemAmount);
    }

    function test_Swap_RevertsWhenInsufficientVaultBalance() public {
        // Setup with small USDT amount
        uint256 usdtAmount = 100_000 * 1e6; // Only 100k USDT
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 rate = vault.getRedemptionRate();

        // Calculate token amount that would require more USDT than available
        // We need: (tokenAmount * rate) / 1e18 > 100_000 * 1e6
        // So: tokenAmount > (100_000 * 1e6 * 1e18) / rate
        uint256 maxTokenAmount = (usdtAmount * 1e18) / rate;
        uint256 redeemAmount = maxTokenAmount + 1_000_000 * 1e18; // Try to redeem more

        // Make sure user1 has enough tokens
        futureToken.mint(user1, redeemAmount);

        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vm.expectRevert("Insufficient stablecoin in vault");
        vault.swap(redeemAmount);
    }

    function test_Swap_RevertsWhenStablecoinAmountTooLow() public {
        // Edge case: Token amount so small that USDT amount rounds to 0
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Try to swap 1 wei of tokens (will likely round to 0 USDT)
        vm.prank(user1);
        futureToken.approve(address(vault), 1);

        vm.prank(user1);
        vm.expectRevert("Stablecoin amount too low");
        vault.swap(1);
    }

    // ============================================
    // Pause/Unpause Tests
    // ============================================

    function test_Pause_Success() public {
        vm.expectEmit(true, false, false, false);
        emit VaultPaused(owner);

        vm.prank(owner);
        vault.pause();

        assertTrue(vault.paused());
    }

    function test_Pause_OnlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker));
        vault.pause();
    }

    function test_Unpause_Success() public {
        // Pause first
        vm.prank(owner);
        vault.pause();

        // Unpause
        vm.expectEmit(true, false, false, false);
        emit VaultUnpaused(owner);

        vm.prank(owner);
        vault.unpause();

        assertFalse(vault.paused());
    }

    function test_Unpause_OnlyOwner() public {
        vm.prank(owner);
        vault.pause();

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker));
        vault.unpause();
    }

    function test_Pause_PreventsSwap() public {
        // Setup
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Pause
        vm.prank(owner);
        vault.pause();

        // Try to swap
        uint256 redeemAmount = 1_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vm.expectRevert();
        vault.swap(redeemAmount);
    }

    function test_Unpause_AllowsSwap() public {
        // Setup
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        // Pause then unpause
        vm.prank(owner);
        vault.pause();

        vm.prank(owner);
        vault.unpause();

        // Swap should work
        uint256 redeemAmount = 1_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        vm.prank(user1);
        vault.swap(redeemAmount); // Should not revert
    }

    // ============================================
    // View Functions Tests
    // ============================================

    function test_GetRedemptionRate_BeforeActivation() public {
        assertEq(vault.getRedemptionRate(), 0);
    }

    function test_GetRedemptionRate_AfterActivation() public {
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 expectedRate = (usdtAmount * 1e18) / futureToken.totalSupply();
        assertEq(vault.getRedemptionRate(), expectedRate);
    }

    function test_GetAvailableStablecoin_BeforeDeposit() public {
        assertEq(vault.getAvailableStablecoin(), 0);
    }

    function test_GetAvailableStablecoin_AfterDeposit() public {
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        assertEq(vault.getAvailableStablecoin(), usdtAmount);
    }

    function test_GetAvailableStablecoin_AfterSwap() public {
        // Setup
        uint256 usdtAmount = 1_000_000 * 1e6;
        vm.prank(owner);
        usdt.transfer(address(vault), usdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        // Swap
        uint256 redeemAmount = 1_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), redeemAmount);

        uint256 rate = vault.getRedemptionRate();
        uint256 expectedUsdt = (redeemAmount * rate) / 1e18;

        vm.prank(user1);
        vault.swap(redeemAmount);

        assertEq(vault.getAvailableStablecoin(), usdtAmount - expectedUsdt);
    }

    function test_IsRedemptionActive_BeforeActivation() public {
        assertFalse(vault.isRedemptionActive());
    }

    function test_IsRedemptionActive_AfterActivation() public {
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        assertTrue(vault.isRedemptionActive());
    }

    // ============================================
    // Edge Cases & Integration Tests
    // ============================================

    function test_EdgeCase_VeryLargeAmounts() public {
        // Test with very large amounts (close to max supply)
        uint256 largeUsdtAmount = 100_000_000 * 1e6; // 100M USDT

        vm.prank(owner);
        usdt.mint(owner, largeUsdtAmount);

        vm.prank(owner);
        usdt.transfer(address(vault), largeUsdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        // Redeem large amount
        uint256 largeTokenAmount = 50_000_000 * 1e18; // 50M tokens
        vm.prank(user1);
        futureToken.mint(user1, largeTokenAmount);

        vm.prank(user1);
        futureToken.approve(address(vault), largeTokenAmount);

        vm.prank(user1);
        vault.swap(largeTokenAmount);

        // Verify no overflow and correct calculation
        assertTrue(usdt.balanceOf(user1) > 0);
    }

    function test_EdgeCase_PrecisionWithSmallAmounts() public {
        // Test precision with small amounts
        uint256 smallUsdtAmount = 1000 * 1e6; // 1000 USDT
        vm.prank(owner);
        usdt.transfer(address(vault), smallUsdtAmount);

        vm.prank(owner);
        vault.activateRedemption();

        // Redeem small amount
        uint256 smallTokenAmount = 100 * 1e18; // 100 tokens
        vm.prank(user1);
        futureToken.approve(address(vault), smallTokenAmount);

        vm.prank(user1);
        vault.swap(smallTokenAmount);

        // Verify user received some USDT (not rounded to 0)
        assertTrue(usdt.balanceOf(user1) > 0);
    }

    function test_Integration_CompleteRedemptionSequence() public {
        // Complete flow: deposit, activate, multiple swaps, verify final state
        uint256 totalUsdt = 5_000_000 * 1e6; // 5M USDT
        vm.prank(owner);
        usdt.transfer(address(vault), totalUsdt);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 initialSupply = futureToken.totalSupply();
        uint256 rate = vault.getRedemptionRate();

        // User1 redeems 40% of tokens
        uint256 user1Amount = 4_000_000 * 1e18;
        vm.prank(user1);
        futureToken.approve(address(vault), user1Amount);
        vm.prank(user1);
        vault.swap(user1Amount);

        // User2 redeems 30% of tokens
        uint256 user2Amount = 3_000_000 * 1e18;
        vm.prank(user2);
        futureToken.approve(address(vault), user2Amount);
        vm.prank(user2);
        vault.swap(user2Amount);

        // Attacker redeems 10% of tokens
        uint256 attackerAmount = 1_000_000 * 1e18;
        vm.prank(attacker);
        futureToken.approve(address(vault), attackerAmount);
        vm.prank(attacker);
        vault.swap(attackerAmount);

        // Verify total redeemed
        uint256 totalTokensRedeemed = user1Amount + user2Amount + attackerAmount;
        uint256 expectedTotalUsdt = (totalTokensRedeemed * rate) / 1e18;
        assertEq(vault.totalRedeemed(), expectedTotalUsdt);

        // Verify supply decreased
        assertEq(futureToken.totalSupply(), initialSupply - totalTokensRedeemed);

        // Verify vault has remaining USDT
        assertTrue(vault.getAvailableStablecoin() > 0);
        assertEq(vault.getAvailableStablecoin(), totalUsdt - expectedTotalUsdt);
    }

    function test_Integration_RateRemainsConstant() public {
        // Verify that redemption rate stays constant even as swaps happen
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 initialRate = vault.getRedemptionRate();

        // Multiple swaps
        for (uint256 i = 0; i < 3; i++) {
            uint256 amount = 100_000 * 1e18;
            vm.prank(user1);
            futureToken.approve(address(vault), amount);
            vm.prank(user1);
            vault.swap(amount);

            // Rate should not change
            assertEq(vault.getRedemptionRate(), initialRate);
        }
    }

    function test_MathVerification_RateCalculation() public {
        // Verify the math: rate = (usdt * 1e18) / tokenSupply
        uint256 usdtAmount = 2_000_000 * 1e6; // 2M USDT with 6 decimals

        // Create new token with specific supply for this test
        MockFutureCarbonToken testToken = new MockFutureCarbonToken();
        uint256 currentSupply = testToken.totalSupply();
        uint256 desiredSupply = 10_000_000 * 1e18; // 10M tokens

        // Burn excess or mint deficit
        if (currentSupply > desiredSupply) {
            testToken.burn(currentSupply - desiredSupply);
        } else if (currentSupply < desiredSupply) {
            testToken.mint(address(this), desiredSupply - currentSupply);
        }

        // Deploy new vault for this test
        vm.prank(owner);
        RedemptionVault testVault = new RedemptionVault(
            address(testToken),
            address(usdt),
            owner
        );

        vm.prank(owner);
        usdt.transfer(address(testVault), usdtAmount);

        vm.prank(owner);
        testVault.activateRedemption();

        // Expected: (2_000_000 * 1e6 * 1e18) / (10_000_000 * 1e18) = 200_000 (0.2 USDT per token)
        uint256 expectedRate = (usdtAmount * 1e18) / desiredSupply;
        assertEq(testVault.getRedemptionRate(), expectedRate);
    }

    function test_MathVerification_SwapCalculation() public {
        // Verify the math: usdtAmount = (tokenAmount * rate) / 1e18
        vm.prank(owner);
        usdt.transfer(address(vault), 1_000_000 * 1e6);

        vm.prank(owner);
        vault.activateRedemption();

        uint256 rate = vault.getRedemptionRate();
        uint256 tokenAmount = 500_000 * 1e18; // 500k tokens

        // Expected USDT = (500_000 * 1e18 * rate) / 1e18
        uint256 expectedUsdt = (tokenAmount * rate) / 1e18;

        vm.prank(user1);
        futureToken.approve(address(vault), tokenAmount);

        uint256 balanceBefore = usdt.balanceOf(user1);

        vm.prank(user1);
        vault.swap(tokenAmount);

        uint256 balanceAfter = usdt.balanceOf(user1);
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, expectedUsdt);
    }
}
