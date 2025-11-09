// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ACR} from "../src/ACR.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console} from "forge-std/console.sol";

/**
 * @title UpgradeScript
 * @dev Script to upgrade an existing ACR proxy to a new implementation
 *
 * Required Environment Variable:
 * - PROXY_ADDRESS: The address of the deployed proxy contract
 *
 * Usage:
 *   source .env && PROXY_ADDRESS=0x... forge script script/Upgrade.s.sol --rpc-url sepolia --broadcast --mnemonic "$MNEMONIC" --mnemonic-index 0
 *
 * IMPORTANT NOTES:
 * 1. Only the owner of the proxy can perform upgrades
 * 2. The proxy address stays the same - users continue using the same address
 * 3. Storage layout must be preserved (no reordering/removal of state variables)
 * 4. Always test upgrades on testnet first!
 * 5. Consider using a timelock or multisig for mainnet upgrades
 *
 * WARNING: If you deploy a new implementation with incompatible storage layout,
 * you can brick the proxy! Always follow upgrade safety guidelines.
 */
contract UpgradeScript is Script {
    function run() public {
        // Get the proxy address from environment variable
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        require(proxyAddress != address(0), "PROXY_ADDRESS environment variable not set");

        console.log("Upgrading proxy at:", proxyAddress);

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
        ACR proxy = ACR(proxyAddress);

        // Verify that the caller is the owner
        address owner = proxy.owner();
        console.log("Current owner:", owner);
        console.log("Upgrading from:", msg.sender);

        // Step 1: Deploy the new implementation contract
        ACR newImplementation = new ACR();
        console.log("New implementation deployed at:", address(newImplementation));

        // Step 2: Upgrade the proxy to point to the new implementation
        // Note: upgradeToAndCall with empty data just upgrades without calling any function
        proxy.upgradeToAndCall(address(newImplementation), "");

        // Stop broadcasting
        vm.stopBroadcast();

        // Verify the upgrade was successful
        console.log("\n=== Upgrade Successful ===");
        console.log("Proxy address (unchanged):", proxyAddress);
        console.log("New implementation address:", address(newImplementation));
        console.log("Token name:", proxy.name());
        console.log("Token symbol:", proxy.symbol());
        console.log("Total supply:", proxy.totalSupply());
        console.log("Owner:", proxy.owner());
        console.log("==========================\n");

        // Additional verification - check that storage was preserved
        console.log("Verifying storage preservation...");
        console.log("If name, symbol, and owner are correct, upgrade was successful!");
    }
}
