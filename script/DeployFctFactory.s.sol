// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {FctFactory} from "../src/FctFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployFctFactoryScript
 * @dev Deployment script for DPX Platform (FctFactory) using UUPS proxy pattern
 *
 * Configuration:
 * - OWNER_ADDRESS: Address of the owner (company multisig wallet)
 *   - If not provided, deployer becomes the owner
 *
 * Usage with private key:
 *   source .env && forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
 *
 * Usage with mnemonic (derive private key first):
 *   source .env && DERIVED_KEY=$(cast wallet private-key "$MNEMONIC" --mnemonic-index 0) && \
 *   forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --private-key $DERIVED_KEY
 *
 * Usage with custom owner (recommended for production):
 *   source .env && OWNER_ADDRESS=0x... forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
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
contract DeployFctFactoryScript is Script {
    function run() public {
        // Calculate Foundry's default sender address (should NOT be used as owner)
        // Same calculation as in forge-std: address(uint160(uint256(keccak256("foundry default caller"))))
        address FOUNDRY_DEFAULT_SENDER = address(uint160(uint256(keccak256("foundry default caller"))));

        // Start broadcast - Foundry will use whatever was passed via CLI:
        // - --private-key flag
        // - --mnemonics flag
        // - --account flag
        // - or default to the foundry default sender if nothing was provided
        vm.startBroadcast();

        // Get deployer address - Foundry already knows this from CLI args
        address deployerAddress = msg.sender;

        // Validate we're not using the Foundry default sender
        require(
            deployerAddress != FOUNDRY_DEFAULT_SENDER,
            "ERROR: Using Foundry default sender! Please provide --private-key, --mnemonics, or --account"
        );

        // Get owner address from environment, otherwise use deployer
        address ownerAddress;
        try vm.envAddress("OWNER_ADDRESS") returns (address addr) {
            // Don't use OWNER_ADDRESS if it's set to the Foundry default or zero
            if (addr != FOUNDRY_DEFAULT_SENDER && addr != address(0)) {
                ownerAddress = addr;
                console.log("Using OWNER_ADDRESS from env:", ownerAddress);
            } else {
                ownerAddress = deployerAddress;
                console.log("OWNER_ADDRESS is invalid, using deployer address instead");
            }
        } catch {
            // Owner will be set to deployer (msg.sender)
            ownerAddress = deployerAddress;
            console.log("OWNER_ADDRESS not set, using deployer address");
        }

        console.log("\n=== Starting DPX Platform Deployment ===");
        console.log("Network:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("Owner:", ownerAddress);
        console.log("========================================\n");

        // Step 1: Deploy the FctFactory implementation contract
        console.log("Step 1: Deploying FctFactory implementation...");
        FctFactory implementation = new FctFactory();
        console.log("Implementation deployed at:", address(implementation));

        // Step 2: Encode the initializer function call
        console.log("\nStep 2: Encoding initializer data...");
        bytes memory initData = abi.encodeWithSelector(
            FctFactory.initialize.selector,
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

        // Wrap the proxy address with the FctFactory interface for easier interaction
        FctFactory factory = FctFactory(proxyAddress);

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
        console.log("Interact with FctFactory:");
        console.log("   cast call ", proxyAddress, " \"getProjectCount()\"");
        console.log("");
        console.log("========================================================");
    }
}
