// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Minimal interface to fetch protocol fee from deployed contract
interface ISwapERC20 {
    function protocolFee() external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @title CreateSwapSignature
 * @notice Script to generate EIP-712 signatures for SwapERC20 orders
 * @dev Uses local variables for order parameters, only reads MNEMONIC from environment
 *
 * Usage:
 *   source .env && forge script script/CreateSwapSignature.s.sol --rpc-url anvil
 *
 * Note: This script does NOT broadcast transactions, it only generates signatures
 */
contract CreateSwapSignature is Script {
    // ==============================================================================
    // EIP-712 CONSTANTS (from SwapERC20 contract)
    // ==============================================================================

    bytes32 private constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "OrderERC20(uint256 nonce,uint256 expiry,address signerWallet,address signerToken,uint256 signerAmount,",
            "uint256 protocolFee,address senderWallet,address senderToken,uint256 senderAmount)"
        )
    );

    bytes32 private constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    string private constant DOMAIN_NAME = "SWAP_ERC20";
    string private constant DOMAIN_VERSION = "4.3";

    // ==============================================================================
    // ORDER PARAMETERS - CUSTOMIZE THESE LOCALLY
    // ==============================================================================

    // Network configuration
    uint256 private constant CHAIN_ID = 11155111;  // Sepolia
    uint256 private constant MNEMONIC_INDEX = 1;  // Which account from mnemonic

    // SwapERC20 contract address - REPLACE WITH YOUR DEPLOYED CONTRACT
    address private constant SWAP_CONTRACT = 0xC376d2eD499B835E92b025067Ce96bF0FAAba71e;

    // Order parameters
    uint256 private constant NONCE = 3;
    uint256 private constant EXPIRY = 9999999997;  // Far future for testing

    // Signer (the one creating and signing the order)
    address private constant SIGNER_WALLET = 0x5Cd5F76686B86CB66494FeA4040b9Dea83129F81;  // Signer account
    address private constant SIGNER_TOKEN = 0xa0d34260E7fD4a84e15cD9BC2E1C51AbBA51A498;   // Example token A
    uint256 private constant SIGNER_AMOUNT = 20 ether;  // 1 token (18 decimals)

    // Protocol fee is fetched from the deployed contract (not hardcoded)

    // Sender (the one who will execute the swap)
    address private constant SENDER_WALLET = 0x0000000000000000000000000000000000000000;  // Sender account
    address private constant SENDER_TOKEN = 0x817AF3CEa0921CF33ACF0CA6456012a92b4c9261;   // Example token B
    uint256 private constant SENDER_AMOUNT = 70 ether;  // 2 tokens (18 decimals)

    // ==============================================================================
    // MAIN SCRIPT
    // ==============================================================================

    function run() public {
        console.log("======================================================================");
        console.log("SwapERC20 Signature Generator");
        console.log("======================================================================");
        console.log("");

        // Step 0: Fetch protocol fee from deployed contract
        ISwapERC20 swapContract = ISwapERC20(SWAP_CONTRACT);
        uint256 protocolFee = swapContract.protocolFee();
        console.log("[0/6] Fetched protocol fee from contract:");
        console.log("      Protocol Fee:", protocolFee, "bps");
        console.log("");

        // Print order details
        _logOrderDetails(protocolFee);

        // Step 1: Derive private key from mnemonic
        string memory mnemonic = vm.envString("MNEMONIC");
        uint256 signerPrivateKey = vm.deriveKey(mnemonic, uint32(MNEMONIC_INDEX));
        address derivedAddress = vm.addr(signerPrivateKey);

        console.log("[1/6] Derived signer address from mnemonic:");
        console.log("      Address:", derivedAddress);

        // Verify the derived address matches the signer wallet
        if (derivedAddress != SIGNER_WALLET) {
            console.log("");
            console.log("WARNING: Derived address does not match SIGNER_WALLET!");
            console.log("         Expected:", SIGNER_WALLET);
            console.log("         Got:     ", derivedAddress);
            console.log("         Update SIGNER_WALLET constant or use different mnemonic index");
        }
        console.log("");

        // Step 2: Compute domain separator
        bytes32 domainSeparator = _computeDomainSeparator();
        console.log("[2/6] Computed EIP-712 domain separator:");
        console.logBytes32(domainSeparator);
        console.log("");

        console.log("[2.5/6] Order typehash:");
        console.logBytes32(ORDER_TYPEHASH);
        console.log("");

        // Step 3: Compute struct hash
        bytes32 structHash = _computeStructHash(protocolFee);
        console.log("[3/6] Computed order struct hash:");
        console.logBytes32(structHash);
        console.log("");

        // Step 4: Compute EIP-712 digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );
        console.log("[4/6] Computed EIP-712 digest:");
        console.logBytes32(digest);
        console.log("");

        // Step 5: Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        console.log("[5/6] Generated signature:");
        console.log("      v:", v);
        console.log("      r:");
        console.logBytes32(r);
        console.log("      s:");
        console.logBytes32(s);
        console.log("");

        // Step 6: Verify signature recovery
        address recovered = ecrecover(digest, v, r, s);
        console.log("[6/6] Signature verification:");
        console.log("      Recovered address:", recovered);
        console.log("      Expected address: ", derivedAddress);
        console.log("      Valid:            ", recovered == derivedAddress);
        console.log("");

        // Output the cast command
        _printCastCommand(protocolFee, v, r, s);

        // Output notes
        _printNotes(protocolFee);
    }

    // ==============================================================================
    // HELPER FUNCTIONS
    // ==============================================================================

    function _computeDomainSeparator() private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                CHAIN_ID,
                SWAP_CONTRACT
            )
        );
    }

    function _computeStructHash(uint256 protocolFee) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                NONCE,
                EXPIRY,
                SIGNER_WALLET,
                SIGNER_TOKEN,
                SIGNER_AMOUNT,
                protocolFee,
                SENDER_WALLET,
                SENDER_TOKEN,
                SENDER_AMOUNT
            )
        );
    }

    function _logOrderDetails(uint256 protocolFee) private pure {
        console.log("Order Parameters:");
        console.log("  Chain ID:        ", CHAIN_ID);
        console.log("  Swap Contract:   ", SWAP_CONTRACT);
        console.log("  Nonce:           ", NONCE);
        console.log("  Expiry:          ", EXPIRY);
        console.log("");
        console.log("  Signer Wallet:   ", SIGNER_WALLET);
        console.log("  Signer Token:    ", SIGNER_TOKEN);
        console.log("  Signer Amount:   ", SIGNER_AMOUNT);
        console.log("");
        console.log("  Protocol Fee:    ", protocolFee, "bps (fetched from contract)");
        console.log("");
        console.log("  Sender Wallet:   ", SENDER_WALLET);
        console.log("  Sender Token:    ", SENDER_TOKEN);
        console.log("  Sender Amount:   ", SENDER_AMOUNT);
        console.log("");
    }

    function _printCastCommand(uint256 protocolFee, uint8 v, bytes32 r, bytes32 s) private pure {
        bool isAnySender = SENDER_WALLET == address(0);
        string memory functionName = isAnySender ? "swapAnySender" : "swap";

        console.log("======================================================================");
        console.log(functionName, "Function Parameters");
        console.log("======================================================================");
        console.log("The other party should call", functionName, "with these exact values:");
        console.log("");
        console.log("recipient (address):      ", vm.toString(SENDER_WALLET));
        console.log("nonce (uint256):          ", NONCE);
        console.log("expiry (uint256):         ", EXPIRY);
        console.log("signerWallet (address):   ", vm.toString(SIGNER_WALLET));
        console.log("signerToken (address):    ", vm.toString(SIGNER_TOKEN));
        console.log("signerAmount (uint256):   ", SIGNER_AMOUNT);
        console.log("senderToken (address):    ", vm.toString(SENDER_TOKEN));
        console.log("senderAmount (uint256):   ", SENDER_AMOUNT);
        console.log("v (uint8):                ", v);
        console.log("r (bytes32):              ", vm.toString(r));
        console.log("s (bytes32):              ", vm.toString(s));
        console.log("");

        console.log("======================================================================");
        console.log("Cast Command to Execute", functionName, ":");
        console.log("======================================================================");
        console.log("");

        if (isAnySender) {
            // swapAnySender - any wallet can execute
            console.log("# ANY wallet can execute this swap");
            console.log("# Replace <RECIPIENT_ADDRESS> with who should receive the tokens");
            console.log("# Replace <YOUR_MNEMONIC_INDEX> with your account index");
            console.log("");
            console.log("cast send", vm.toString(SWAP_CONTRACT), "\\");
            console.log("  \"swapAnySender(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)\" \\");
            console.log("  <RECIPIENT_ADDRESS> \\");
            console.log("  ", vm.toString(NONCE), "\\");
            console.log("  ", vm.toString(EXPIRY), "\\");
            console.log("  ", vm.toString(SIGNER_WALLET), "\\");
            console.log("  ", vm.toString(SIGNER_TOKEN), "\\");
            console.log("  ", vm.toString(SIGNER_AMOUNT), "\\");
            console.log("  ", vm.toString(SENDER_TOKEN), "\\");
            console.log("  ", vm.toString(SENDER_AMOUNT), "\\");
            console.log("  ", vm.toString(v), "\\");
            console.log("  ", vm.toString(r), "\\");
            console.log("  ", vm.toString(s), "\\");
            console.log("  --rpc-url sepolia \\");
            console.log("  --mnemonic \"$MNEMONIC\" \\");
            console.log("  --mnemonic-index <YOUR_MNEMONIC_INDEX>");
        } else {
            // swap - only SENDER_WALLET can execute
            console.log("# ONLY the sender wallet can execute this swap");
            console.log("# Must use the mnemonic index that controls:", vm.toString(SENDER_WALLET));
            console.log("");
            console.log("cast send", vm.toString(SWAP_CONTRACT), "\\");
            console.log("  \"swap(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)\" \\");
            console.log("  ", vm.toString(SENDER_WALLET), "\\");
            console.log("  ", vm.toString(NONCE), "\\");
            console.log("  ", vm.toString(EXPIRY), "\\");
            console.log("  ", vm.toString(SIGNER_WALLET), "\\");
            console.log("  ", vm.toString(SIGNER_TOKEN), "\\");
            console.log("  ", vm.toString(SIGNER_AMOUNT), "\\");
            console.log("  ", vm.toString(SENDER_TOKEN), "\\");
            console.log("  ", vm.toString(SENDER_AMOUNT), "\\");
            console.log("  ", vm.toString(v), "\\");
            console.log("  ", vm.toString(r), "\\");
            console.log("  ", vm.toString(s), "\\");
            console.log("  --rpc-url sepolia \\");
            console.log("  --mnemonic \"$MNEMONIC\" \\");
            console.log("  --mnemonic-index <SENDER_MNEMONIC_INDEX>");
        }
        console.log("");
    }

    function _printNotes(uint256 protocolFee) private pure {
        bool isAnySender = SENDER_WALLET == address(0);

        console.log("======================================================================");
        console.log("Important Notes:");
        console.log("======================================================================");
        console.log("1. The signer (", vm.toString(SIGNER_WALLET), ") has signed this order");
        console.log("");

        if (isAnySender) {
            console.log("2. Mode: swapAnySender");
            console.log("   - SENDER_WALLET is zero address (0x0)");
            console.log("   - ANY wallet can execute this swap");
            console.log("   - Executor must provide recipient address in the call");
            console.log("   - Executor needs to approve SwapERC20 for", SENDER_AMOUNT, "of", SENDER_TOKEN);
        } else {
            console.log("2. Mode: swap");
            console.log("   - SENDER_WALLET:", vm.toString(SENDER_WALLET));
            console.log("   - ONLY this specific wallet can execute the swap");
            console.log("   - Recipient is fixed to SENDER_WALLET");
            console.log("   - Sender must approve SwapERC20 for", SENDER_AMOUNT, "of", SENDER_TOKEN);
        }
        console.log("");

        console.log("3. Token approvals required:");
        console.log("   - Signer must approve SwapERC20 for", SIGNER_AMOUNT, "of", SIGNER_TOKEN);
        console.log("   - Executor must approve SwapERC20 for", SENDER_AMOUNT, "of", SENDER_TOKEN);
        console.log("");

        console.log("4. Both parties must have sufficient token balances");
        console.log("5. Nonce", NONCE, "must not have been used before by the signer");
        console.log("6. Swap must be executed before expiry timestamp:", EXPIRY);
        console.log("7. Protocol fee will be deducted from signer amount:", protocolFee, "bps");
        console.log("======================================================================");
        console.log("");
    }
}
