// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Interface for burnable ERC20 tokens
 * Used to burn FutureCarbonTokens during redemption
 */
interface IERC20Burnable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * @title RedemptionVault
 * @dev Holds stablecoin proceeds from carbon credit sales and facilitates token redemption.
 *
 * Each project gets its own RedemptionVault that is deployed separately from the token
 * (only when the project nears completion and actual carbon credits are sold).
 *
 * Features:
 * - Stores stablecoin (USDT or other) from carbon credit sales
 * - Calculates pro-rata redemption rate based on deposited stablecoin and token supply
 * - Executes token-for-stablecoin swaps (burns future tokens, sends stablecoin)
 * - Supports partial redemptions (users can redeem any amount)
 * - Pausable for emergency control
 * - Reentrancy protection
 *
 * Redemption Formula:
 *   redemptionRatePerToken = totalStablecoin / futureTokenTotalSupply
 *   userReceives = userTokenAmount * redemptionRatePerToken / 1e18
 *
 * Example:
 *   - Total USDT: 1,000,000 USDT (1,000,000 * 1e6)
 *   - Total token supply: 10,000,000 tokens (10,000,000 * 1e18)
 *   - Rate: 1,000,000e6 * 1e18 / 10,000,000e18 = 0.1e6 USDT per token
 *   - User has 5,000 tokens → receives: 5,000e18 * 0.1e6 / 1e18 = 500e6 USDT
 *
 * Lifecycle:
 * 1. Deployed by RegistryFactory when project nears completion
 * 2. Owner (company) deposits stablecoin proceeds
 * 3. Owner calls activateRedemption() to calculate rate and enable swaps
 * 4. Token holders call swap() to redeem their tokens
 * 5. Vault burns future tokens and sends stablecoin to users
 *
 * IMPORTANT: This contract is NOT upgradeable. Redemption logic is immutable
 * to ensure predictability and trust for token holders.
 */
contract RedemptionVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    /// @notice The FutureCarbonToken that can be redeemed
    IERC20Burnable public immutable futureToken;

    /// @notice The stablecoin (e.g., USDT) that users receive when redeeming
    IERC20 public immutable stablecoin;

    /// @notice Redemption rate: amount of stablecoin (in stablecoin decimals) per token (in 1e18)
    /// @dev Calculated as: totalStablecoin * 1e18 / futureTokenTotalSupply
    uint256 public redemptionRatePerToken;

    /// @notice Whether redemption has been activated
    bool public redemptionActive;

    /// @notice Total amount of stablecoin redeemed so far
    uint256 public totalRedeemed;

    // ============ Events ============

    /// @notice Emitted when redemption is activated
    event RedemptionActivated(uint256 totalStablecoin, uint256 tokenSupply, uint256 redemptionRate);

    /// @notice Emitted when tokens are swapped for stablecoin
    event TokensRedeemed(address indexed user, uint256 tokenAmount, uint256 stablecoinAmount);

    /// @notice Emitted when the contract is paused
    event VaultPaused(address indexed by);

    /// @notice Emitted when the contract is unpaused
    event VaultUnpaused(address indexed by);

    // ============ Constructor ============

    /**
     * @dev Constructor sets the immutable token references
     * @param _futureToken Address of the FutureCarbonToken contract
     * @param _stablecoin Address of the stablecoin contract (e.g., USDT)
     * @param _owner Address of the owner (company multisig wallet)
     *
     * NOTE: Once deployed, these addresses cannot be changed.
     */
    constructor(address _futureToken, address _stablecoin, address _owner) Ownable(_owner) {
        require(_futureToken != address(0), "Future token cannot be zero address");
        require(_stablecoin != address(0), "Stablecoin cannot be zero address");
        require(_owner != address(0), "Owner cannot be zero address");

        futureToken = IERC20Burnable(_futureToken);
        stablecoin = IERC20(_stablecoin);
    }

    // ============ Owner Functions ============

    /**
     * @dev Activates redemption by calculating the redemption rate
     * Only callable by owner (company multisig)
     *
     * IMPORTANT: Before calling this function, the owner must deposit
     * the stablecoin proceeds into this contract via transfer.
     *
     * This function:
     * 1. Checks the stablecoin balance in this contract
     * 2. Checks the total supply of future tokens
     * 3. Calculates the redemption rate
     * 4. Activates redemption
     *
     * NOTE: This can only be called once. Once activated, redemption cannot be deactivated.
     */
    function activateRedemption() external onlyOwner {
        require(!redemptionActive, "Redemption already activated");

        uint256 stablecoinBalance = stablecoin.balanceOf(address(this));
        require(stablecoinBalance > 0, "No stablecoin deposited");

        uint256 tokenSupply = futureToken.totalSupply();
        require(tokenSupply > 0, "Token supply is zero");

        // Calculate redemption rate: stablecoin amount per token
        // Formula: (stablecoinBalance * 1e18) / tokenSupply
        // This gives us the rate in stablecoin decimals per 1e18 token
        redemptionRatePerToken = (stablecoinBalance * 1e18) / tokenSupply;
        require(redemptionRatePerToken > 0, "Redemption rate too low");

        redemptionActive = true;

        emit RedemptionActivated(stablecoinBalance, tokenSupply, redemptionRatePerToken);
    }

    /**
     * @dev Pauses all redemptions
     * Only callable by owner
     *
     * Use in case of emergency or security issues.
     */
    function pause() external onlyOwner {
        _pause();
        emit VaultPaused(msg.sender);
    }

    /**
     * @dev Unpauses redemptions
     * Only callable by owner
     */
    function unpause() external onlyOwner {
        _unpause();
        emit VaultUnpaused(msg.sender);
    }

    // ============ User Functions ============

    /**
     * @dev Swap future tokens for stablecoin (redemption)
     * Users can redeem any amount of their tokens (partial redemption supported)
     *
     * @param tokenAmount Amount of future tokens to redeem (in 1e18)
     *
     * Process:
     * 1. CHECKS: Validate redemption is active, amount > 0, user has approval
     * 2. EFFECTS: Calculate stablecoin amount, update totalRedeemed
     * 3. INTERACTIONS: Burn tokens (via burnFrom), transfer stablecoin
     *
     * NOTE: User must approve this contract to spend their tokens before calling.
     * Alternatively, users can use EIP-2612 permit() for gasless approval.
     */
    function swap(uint256 tokenAmount) external nonReentrant whenNotPaused {
        // ============ CHECKS ============
        require(redemptionActive, "Redemption not activated");
        require(tokenAmount > 0, "Amount must be greater than 0");

        // Calculate stablecoin amount to send
        // Formula: (tokenAmount * redemptionRatePerToken) / 1e18
        uint256 stablecoinAmount = (tokenAmount * redemptionRatePerToken) / 1e18;
        require(stablecoinAmount > 0, "Stablecoin amount too low");

        // Check vault has enough stablecoin
        uint256 availableStablecoin = stablecoin.balanceOf(address(this));
        require(stablecoinAmount <= availableStablecoin, "Insufficient stablecoin in vault");

        // ============ EFFECTS ============
        totalRedeemed += stablecoinAmount;

        // ============ INTERACTIONS ============
        // Burn the future tokens from user (requires prior approval or EIP-2612 permit)
        // This calls burnFrom on the FutureCarbonToken, which:
        // 1. Checks that this vault has approval to spend user's tokens
        // 2. Burns the tokens from user's balance
        // 3. Reduces total supply
        // The user must approve this vault before calling swap(), or use permit()
        futureToken.burnFrom(msg.sender, tokenAmount);

        // Transfer stablecoin to user
        stablecoin.safeTransfer(msg.sender, stablecoinAmount);

        emit TokensRedeemed(msg.sender, tokenAmount, stablecoinAmount);
    }

    // ============ View Functions ============

    /**
     * @dev Returns the current redemption rate
     * @return Rate of stablecoin per token (in stablecoin decimals per 1e18 tokens)
     */
    function getRedemptionRate() external view returns (uint256) {
        return redemptionRatePerToken;
    }

    /**
     * @dev Returns the available stablecoin balance in the vault
     * @return Available stablecoin balance
     */
    function getAvailableStablecoin() external view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }

    /**
     * @dev Checks if redemption is currently active
     * @return True if redemption is active
     */
    function isRedemptionActive() external view returns (bool) {
        return redemptionActive;
    }
}
