// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RegistryFactory} from "../src/RegistryFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployDPXScript
 * @dev Deployment script for DPX Platform (RegistryFactory) using UUPS proxy pattern
 *
 * Configuration:
 * - OWNER_ADDRESS: Address of the owner (company multisig wallet)
 *   - If not provided, deployer becomes the owner
 *
 * Usage with deployer as owner:
 *   source .env && forge script script/DeployDPX.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
 *
 * Usage with custom owner (recommended for production):
 *   source .env && OWNER_ADDRESS=0x... forge script script/DeployDPX.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
 *
 * Usage with mnemonic:
 *   source .env && forge script script/DeployDPX.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Note: Add --verify --etherscan-api-key $ETHERSCAN_API_KEY if you want to verify on Etherscan
 *
 * IMPORTANT: Save the proxy address - this is the address users will interact with!
 * The implementation address can change during upgrades, but the proxy address stays the same.
 *
 * After deployment:
 * 1. Transfer ownership to multisig (if not done during deployment)
 * 2. Verify contracts on Etherscan
 * 3. Test basic functionality (propose, approve, deployVault)
 */
contract DeployDPXScript is Script {
    function run() public {
        // Get configuration from environment variables
        address ownerAddress;

        // Try to get owner address from environment, otherwise use deployer
        try vm.envAddress("OWNER_ADDRESS") returns (address addr) {
            ownerAddress = addr;
            console.log("Using OWNER_ADDRESS from env:", ownerAddress);
        } catch {
            // Owner will be set to deployer (msg.sender)
            // We'll log this after startBroadcast so we know who the deployer is
            ownerAddress = address(0); // Temporary, will be set to msg.sender
            console.log("OWNER_ADDRESS not set, will use deployer address");
        }

        // Try to get private key, if not available script will use mnemonic from CLI
        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // If no private key, broadcast will use mnemonic from CLI args
            vm.startBroadcast();
        }

        // If owner address was not provided, use deployer
        if (ownerAddress == address(0)) {
            ownerAddress = msg.sender;
            console.log("Owner will be deployer:", ownerAddress);
        }

        console.log("\n=== Starting DPX Platform Deployment ===");
        console.log("Network:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("Owner:", ownerAddress);
        console.log("========================================\n");

        // Step 1: Deploy the RegistryFactory implementation contract
        console.log("Step 1: Deploying RegistryFactory implementation...");
        RegistryFactory implementation = new RegistryFactory();
        console.log("Implementation deployed at:", address(implementation));

        // Step 2: Encode the initializer function call
        console.log("\nStep 2: Encoding initializer data...");
        bytes memory initData = abi.encodeWithSelector(
            RegistryFactory.initialize.selector,
            ownerAddress
        );

        // Step 3: Deploy the ERC1967Proxy contract with the implementation address and initializer
        console.log("\nStep 3: Deploying ERC1967Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // Stop broadcasting
        vm.stopBroadcast();

        // Get the proxy address (this is what users interact with!)
        address proxyAddress = address(proxy);

        // Wrap the proxy address with the RegistryFactory interface for easier interaction
        RegistryFactory factory = RegistryFactory(proxyAddress);

        // Log the deployed addresses and details
        console.log("\n========================================================");
        console.log("       DPX PLATFORM DEPLOYMENT SUCCESSFUL");
        console.log("========================================================");
        console.log("");
        console.log("PROXY ADDRESS (MAIN):");
        console.log("   ", proxyAddress);
        console.log("");
        console.log("Implementation Address:");
        console.log("   ", address(implementation));
        console.log("");
        console.log("Owner Address:");
        console.log("   ", factory.owner());
        console.log("");
        console.log("Initial State:");
        console.log("   Project Count:", factory.getProjectCount());
        console.log("   Next Project ID:", factory.getNextProjectId());
        console.log("");
        console.log("========================================================");
        console.log("                 IMPORTANT NOTES");
        console.log("========================================================");
        console.log("");
        console.log("[+] Use the PROXY address for all interactions!");
        console.log("[+] The proxy address will remain constant through upgrades");
        console.log("[+] Save this address: ", proxyAddress);
        console.log("");
        console.log("Next Steps:");
        console.log("   1. Verify contracts on Etherscan (if not done with --verify)");
        console.log("   2. Transfer ownership to multisig if needed");
        console.log("   3. Test basic operations:");
        console.log("      - Propose a test project");
        console.log("      - Approve and deploy token");
        console.log("      - Deploy vault for testing");
        console.log("");
        console.log("Interact with RegistryFactory:");
        console.log("   cast call ", proxyAddress, " \"getProjectCount()\"");
        console.log("");
        console.log("========================================================");
    }
}
