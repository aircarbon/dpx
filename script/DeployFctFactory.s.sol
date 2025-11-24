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
 * Configuration Environment Variables:
 * - PRIVATE_KEY: Private key for deployment (takes priority)
 * - MNEMONIC: Mnemonic phrase for deployment (used if PRIVATE_KEY not set)
 * - MNEMONIC_INDEX: Index for mnemonic derivation (default: 0)
 * - OWNER_ADDRESS: Address of the owner (company multisig wallet)
 *   - If not provided, deployer becomes the owner
 *
 * Usage with private key:
 *   source .env && forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * Usage with mnemonic (default index 0):
 *   source .env && forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * Usage with mnemonic (specific index):
 *   source .env && MNEMONIC_INDEX=1 forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * Usage with custom owner (recommended for production):
 *   source .env && OWNER_ADDRESS=0x... forge script script/DeployFctFactory.s.sol --rpc-url sepolia --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
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
        // Get deployer address from private key or mnemonic
        address deployerAddress;
        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            // Using private key - derive address and start broadcast
            deployerPrivateKey = pk;
            deployerAddress = vm.addr(pk);
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // Using mnemonic from CLI - derive address from mnemonic
            try vm.envString("MNEMONIC") returns (string memory mnemonic) {
                // Get mnemonic index (default to 0)
                uint32 mnemonicIndex = uint32(vm.envOr("MNEMONIC_INDEX", uint256(0)));
                deployerPrivateKey = vm.deriveKey(mnemonic, mnemonicIndex);
                deployerAddress = vm.addr(deployerPrivateKey);
                vm.startBroadcast(deployerPrivateKey);
            } catch {
                // No env variables, use default broadcast (for testing)
                vm.startBroadcast();
                deployerAddress = msg.sender;
            }
        }

        // Step 1: Deploy the FctFactory implementation contract
        console.log("Step 1: Deploying FctFactory implementation...");
        FctFactory implementation = new FctFactory();
        console.log("Implementation deployed at:", address(implementation));

        // Get owner address from environment, otherwise use deployer
        address ownerAddress;
        try vm.envAddress("OWNER_ADDRESS") returns (address addr) {
            // Don't use OWNER_ADDRESS if it's set to zero
            if (addr != address(0)) {
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

        console.log("\n=== DPX Platform Deployment ===");
        console.log("Network:", block.chainid);
        console.log("Deployer:", deployerAddress);
        console.log("Owner:", ownerAddress);
        console.log("========================================\n");

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
