// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ACT} from "../src/ACT.sol";
import {console} from "forge-std/console.sol";

/**
 * @title ACTScript
 * @dev Deployment script for ACT Token
 *
 * Token Configuration (passed as environment variables in command):
 * - TOKEN_NAME: Name of the token (default: "ACT Token")
 * - TOKEN_SYMBOL: Symbol of the token (default: "ACT")
 * - INITIAL_SUPPLY: Initial supply in whole tokens (default: 1000000)
 *
 * Usage with default token parameters:
 *   source .env && forge script script/ACT.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Usage with custom token parameters:
 *   source .env && TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 forge script script/ACT.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Note: Add --verify flag only if ETHERSCAN_API_KEY is set in .env
 */
contract ACTScript is Script {
    function run() public {
        // Get token configuration from environment variables with defaults
        string memory tokenName = vm.envOr("TOKEN_NAME", string("ACT Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("ACT"));
        uint256 initialSupplyWhole = vm.envOr("INITIAL_SUPPLY", uint256(1_000_000));

        // Convert to wei (18 decimals)
        uint256 initialSupply = initialSupplyWhole * 10**18;

        // Try to get private key, if not available script will use mnemonic from CLI
        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // If no private key, broadcast will use mnemonic from CLI args
            vm.startBroadcast();
        }

        // Deploy ACT token with configurable parameters
        ACT token = new ACT(tokenName, tokenSymbol, initialSupply);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployed contract address and details
        console.log("=== ACT Token Deployment ===");
        console.log("Token deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Initial supply:", initialSupply);
        console.log("Deployer/Owner address:", token.owner());
        console.log("===========================");
    }
}
