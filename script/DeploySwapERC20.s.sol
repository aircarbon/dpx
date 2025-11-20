// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SwapERC20} from "@airswap/swap-erc20/SwapERC20.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeploySwapERC20Script
 * @dev Deployment script for AirSwap SwapERC20 v5.0.0
 *
 * SwapERC20 Configuration (passed as environment variables):
 * - PROTOCOL_FEE: Fee in basis points for standard swaps (default: 30 = 0.3%)
 * - PROTOCOL_FEE_LIGHT: Fee in basis points for swapLight() (default: 7 = 0.07%)
 * - PROTOCOL_FEE_WALLET: Address to receive protocol fees (REQUIRED)
 * - BONUS_SCALE: Staking bonus scale factor (default: 4)
 * - BONUS_MAX: Maximum bonus percentage (default: 50 = 50%)
 *
 * Usage with default parameters:
 *   source .env && forge script script/DeploySwapERC20.s.sol --rpc-url fuji --broadcast --verify
 *
 * Usage with custom parameters:
 *   source .env && PROTOCOL_FEE=50 PROTOCOL_FEE_LIGHT=10 forge script script/DeploySwapERC20.s.sol --rpc-url fuji --broadcast --verify
 *
 * Alternative using private key:
 *   source .env && forge script script/DeploySwapERC20.s.sol --rpc-url fuji --broadcast --verify --private-key $PRIVATE_KEY
 *
 * For Anvil local testing:
 *   anvil
 *   source .env && forge script script/DeploySwapERC20.s.sol --rpc-url anvil --broadcast
 *
 * IMPORTANT: SwapERC20 is NOT upgradeable - constructor parameters are immutable!
 * After deployment, save the contract address and only certain parameters can be updated via setter functions.
 */
contract DeploySwapERC20Script is Script {
    function run() public {
        // Get SwapERC20 configuration from environment variables with defaults
        uint256 protocolFee = vm.envOr("PROTOCOL_FEE", uint256(30)); // 0.3%
        uint256 protocolFeeLight = vm.envOr("PROTOCOL_FEE_LIGHT", uint256(7)); // 0.07%
        address protocolFeeWallet = vm.envAddress("PROTOCOL_FEE_WALLET"); // REQUIRED
        uint256 bonusScale = vm.envOr("BONUS_SCALE", uint256(4));
        uint256 bonusMax = vm.envOr("BONUS_MAX", uint256(50)); // 50%

        // Validate parameters before deployment
        require(protocolFee < 10000, "Protocol fee must be < 10000 basis points");
        require(protocolFeeLight < 10000, "Protocol fee light must be < 10000 basis points");
        require(protocolFeeWallet != address(0), "Protocol fee wallet cannot be zero address");
        require(bonusMax <= 100, "Bonus max cannot exceed 100%");
        require(bonusScale <= 77, "Bonus scale cannot exceed 77");

        // Try to get private key, if not available script will use mnemonic from CLI
        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // If no private key, broadcast will use mnemonic from CLI args
            vm.startBroadcast();
        }

        // Deploy SwapERC20 contract
        SwapERC20 swapContract = new SwapERC20(
            protocolFee,
            protocolFeeLight,
            protocolFeeWallet,
            bonusScale,
            bonusMax
        );

        // Stop broadcasting
        vm.stopBroadcast();

        // Get the deployed address
        address swapAddress = address(swapContract);

        // Log the deployed addresses and details
        console.log("\n=== AirSwap SwapERC20 v5.0.0 Deployment ===");
        console.log("Contract address:", swapAddress);
        console.log("---");
        console.log("Protocol Fee:", protocolFee, "basis points");
        console.log("Protocol Fee Light:", protocolFeeLight, "basis points");
        console.log("Protocol Fee Wallet:", protocolFeeWallet);
        console.log("Bonus Scale:", bonusScale);
        console.log("Bonus Max:", bonusMax);
        console.log("Owner:", swapContract.owner());
        console.log("---");
        console.log("\n!!! Save this address for future interactions !!!");
        console.log("export SWAP_ADDRESS=", swapAddress);
        console.log("\nVerify ownership:");
        console.log('cast call', swapAddress, '"owner()" --rpc-url <network>');
        console.log("========================================\n");
    }
}
