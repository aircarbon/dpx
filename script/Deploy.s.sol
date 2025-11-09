// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ACR} from "../src/ACR.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployScript
 * @dev Deployment script for ACR Token using UUPS proxy pattern
 *
 * Token Configuration (passed as environment variables in command):
 * - TOKEN_NAME: Name of the token (default: "ACR Token")
 * - TOKEN_SYMBOL: Symbol of the token (default: "ACR")
 * - INITIAL_SUPPLY: Initial supply in whole tokens (default: 1000000)
 *
 * Usage with default token parameters:
 *   source .env && forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Usage with custom token parameters:
 *   source .env && TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Note: Add --verify flag only if ETHERSCAN_API_KEY is set in .env
 *
 * IMPORTANT: Save the proxy address - this is the address users will interact with!
 * The implementation address can change during upgrades, but the proxy address stays the same.
 */
contract DeployScript is Script {
    function run() public {
        // Get token configuration from environment variables with defaults
        string memory tokenName = vm.envOr("TOKEN_NAME", string("ACR Token"));
        string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("ACR"));
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

        // Step 1: Deploy the implementation contract
        ACR implementation = new ACR();
        console.log("Implementation deployed at:", address(implementation));

        // Step 2: Encode the initializer function call
        bytes memory initData = abi.encodeWithSelector(
            ACR.initialize.selector,
            tokenName,
            tokenSymbol,
            initialSupply
        );

        // Step 3: Deploy the ERC1967Proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // Stop broadcasting
        vm.stopBroadcast();

        // Get the proxy address (this is what users interact with!)
        address proxyAddress = address(proxy);

        // Wrap the proxy address with the ACR interface for easier interaction
        ACR token = ACR(proxyAddress);

        // Log the deployed addresses and details
        console.log("\n=== ACR Token Deployment ===");
        console.log("Proxy address (MAIN):", proxyAddress);
        console.log("Implementation address:", address(implementation));
        console.log("---");
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Initial supply:", initialSupply);
        console.log("Deployer/Owner address:", token.owner());
        console.log("\n!!! IMPORTANT: Use the PROXY address for all interactions !!!");
        console.log("Proxy address:", proxyAddress);
        console.log("========================================\n");
    }
}
