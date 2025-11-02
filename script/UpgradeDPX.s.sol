// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RegistryFactory} from "../src/RegistryFactory.sol";
import {console} from "forge-std/console.sol";

/**
 * @title UpgradeDPXScript
 * @dev Script to upgrade an existing DPX RegistryFactory proxy to a new implementation
 *
 * The upgrade allows adding new features to the RegistryFactory while:
 * - Keeping the same proxy address
 * - Preserving all existing data (projects, tokens, vaults)
 * - Maintaining registry mappings
 *
 * Required Environment Variable:
 * - PROXY_ADDRESS: The address of the deployed RegistryFactory proxy contract
 *
 * Usage:
 *   source .env && PROXY_ADDRESS=0x... forge script script/UpgradeDPX.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
 *
 * Usage with mnemonic:
 *   source .env && PROXY_ADDRESS=0x... forge script script/UpgradeDPX.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * Note: Add --verify --etherscan-api-key $ETHERSCAN_API_KEY if you want to verify the new implementation
 *
 * IMPORTANT NOTES:
 * 1. Only the owner of the proxy can perform upgrades
 * 2. The proxy address stays the same - users continue using the same address
 * 3. Storage layout MUST be preserved:
 *    - Do NOT reorder existing state variables
 *    - Do NOT change types of existing state variables
 *    - Do NOT remove existing state variables
 *    - Only ADD new state variables at the END or use the __gap
 * 4. Always test upgrades on testnet first!
 * 5. Consider using a timelock or multisig for mainnet upgrades
 * 6. All existing projects, tokens, and vaults remain accessible
 *
 * Storage Safety:
 * The RegistryFactory uses:
 * - Enums (ProjectStatus)
 * - Structs (Project)
 * - Mappings (projects, tokenToProjectId)
 * - uint256 (projectIdCounter)
 * - Storage gap (uint256[50] __gap)
 *
 * When upgrading, you can:
 * ✓ Add new functions
 * ✓ Add new state variables at the end (reduce __gap accordingly)
 * ✓ Modify function logic
 * ✗ Reorder state variables
 * ✗ Change state variable types
 * ✗ Remove state variables
 *
 * WARNING: If you deploy a new implementation with incompatible storage layout,
 * you can brick the proxy and lose all data! Always follow upgrade safety guidelines.
 *
 * Verification:
 * After upgrade, verify that:
 * - getProjectCount() returns the same count
 * - Existing projects are still accessible via getProject()
 * - Owner remains the same
 * - All existing tokens/vaults are still mapped correctly
 */
contract UpgradeDPXScript is Script {
    function run() public {
        // Get the proxy address from environment variable
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        require(proxyAddress != address(0), "PROXY_ADDRESS environment variable not set");

        console.log("\n=== Starting DPX Platform Upgrade ===");
        console.log("Network:", block.chainid);
        console.log("Proxy address:", proxyAddress);
        console.log("======================================\n");

        // Try to get private key, if not available script will use mnemonic from CLI
        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // If no private key, broadcast will use mnemonic from CLI args
            vm.startBroadcast();
        }

        // Get the existing proxy contract
        RegistryFactory proxy = RegistryFactory(proxyAddress);

        // Verify that the caller is the owner
        address owner = proxy.owner();
        console.log("Current owner:", owner);
        console.log("Upgrading from:", msg.sender);

        require(msg.sender == owner, "Only owner can upgrade");

        // Get current state before upgrade
        console.log("\nState Before Upgrade:");
        uint256 projectCountBefore = proxy.getProjectCount();
        console.log("   Project Count:", projectCountBefore);
        console.log("   Next Project ID:", proxy.getNextProjectId());

        // Step 1: Deploy the new implementation contract
        console.log("\nStep 1: Deploying new RegistryFactory implementation...");
        RegistryFactory newImplementation = new RegistryFactory();
        console.log("New implementation deployed at:", address(newImplementation));

        // Step 2: Upgrade the proxy to point to the new implementation
        // Note: upgradeToAndCall with empty data just upgrades without calling any function
        console.log("\nStep 2: Upgrading proxy to new implementation...");
        proxy.upgradeToAndCall(address(newImplementation), "");

        // Stop broadcasting
        vm.stopBroadcast();

        // Verify the upgrade was successful
        console.log("\n========================================================");
        console.log("            UPGRADE SUCCESSFUL");
        console.log("========================================================");
        console.log("");
        console.log("Proxy Address (unchanged):");
        console.log("   ", proxyAddress);
        console.log("");
        console.log("New Implementation Address:");
        console.log("   ", address(newImplementation));
        console.log("");
        console.log("Owner (should be unchanged):");
        console.log("   ", proxy.owner());
        console.log("");

        // Verify storage preservation
        console.log("State After Upgrade:");
        uint256 projectCountAfter = proxy.getProjectCount();
        console.log("   Project Count:", projectCountAfter);
        console.log("   Next Project ID:", proxy.getNextProjectId());
        console.log("");

        // Additional verification
        console.log("========================================================");
        console.log("               VERIFICATION");
        console.log("========================================================");
        console.log("");

        if (projectCountBefore == projectCountAfter) {
            console.log("[+] Project count preserved correctly");
        } else {
            console.log("[!] WARNING: Project count changed!");
            console.log("  Before:", projectCountBefore);
            console.log("  After:", projectCountAfter);
        }

        if (proxy.owner() == owner) {
            console.log("[+] Owner preserved correctly");
        } else {
            console.log("[!] WARNING: Owner changed!");
        }

        console.log("");
        console.log("Post-Upgrade Checklist:");
        console.log("   1. Test querying existing projects");
        console.log("   2. Test creating new projects");
        console.log("   3. Verify all new features work correctly");
        console.log("   4. Monitor for any unexpected behavior");
        console.log("");
        console.log("Test with cast:");
        console.log("   cast call ", proxyAddress, " \"getProjectCount()\"");
        console.log("");
        console.log("========================================================");
    }
}
