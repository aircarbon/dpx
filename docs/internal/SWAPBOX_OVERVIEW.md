# SwapBox Integration Guide

## Overview

**SwapBox** is our protocol for atomic, non-custodial ERC20 token swaps between users, enabling trustless peer-to-peer token exchanges without intermediaries. SwapBox is powered by **AirSwap's SwapERC20 smart contract** (v5.0.0), a well-audited and battle-tested protocol widely used for the same purpose. This project integrates **AirSwap SwapERC20 v5.0.0** for atomic ERC20 token swaps using off-chain signed orders. We deploy our own SwapERC20 instance to collect protocol fees from all token swaps on the platform.

**Key Points:**
- ✅ **Deploy your own instance** - Collect protocol fees via your designated fee wallet
- ✅ **Dependencies pinned** at v5.0.0 via git submodules (version locked)
- ✅ **Interface for CLI/testing** - `ISwapERC20.sol` enables `cast` interactions and Foundry tests
- ✅ **Non-upgradeable** - The contract is immutable

## Version Anchoring

The following dependencies are **pinned via git submodules** to prevent breaking changes:

| Dependency | Version | Commit Hash | Location |
|------------|---------|-------------|----------|
| AirSwap Protocols | v5.0.0 | `28156e5115218a444d35f35162162f643e5ccb91` | `lib/airswap-protocols/` |
| Solady | v0.0.173 | `e7024bee47b1623f436ee491ca9458a6dc8abce9` | `lib/solady/` |

### Why This Matters

- ✅ **Version locked**: Even if AirSwap updates their GitHub, we use v5.0.0
- ✅ **Reproducible builds**: Same code every time
- ✅ **Audited version**: v5.0.0 is audited and battle-tested

## Project Structure

```
├── lib/
│   ├── airswap-protocols/   # v5.0.0 (git submodule)
│   └── solady/              # v0.0.173 (git submodule)
├── src/
│   └── interfaces/
│       └── ISwapERC20.sol   # Interface for CLI interactions and testing
└── foundry.toml             # Remappings configured
```

## About the ISwapERC20 Interface

The `ISwapERC20.sol` interface is **NOT deployed** and does **NOT participate in deployments**. It serves these purposes:

1. **Foundry CLI Interactions** - Enables type-safe contract calls via `cast`

2. **Testing** - Allows writing Foundry tests that interact with your deployed SwapERC20

3. **Development Reference** - Provides function signatures and documentation

### Extended Interface

Our `ISwapERC20.sol` is **extended beyond the official AirSwap interface** to include all public functions from the SwapERC20 contract. This provides complete access for contract management via `cast` commands:

**Additional functions included:**
- ✅ **Administrative setters** - `setProtocolFee()`, `setProtocolFeeLight()`, `setProtocolFeeWallet()`, `setBonusScale()`, `setBonusMax()`, `setStaking()`
- ✅ **State getters** - `protocolFee()`, `protocolFeeLight()`, `protocolFeeWallet()`, `bonusScale()`, `bonusMax()`, `stakingToken()`
- ✅ **Ownership management** - `owner()`, `transferOwnership()`, `renounceOwnership()`, plus advanced handover functions from Solady's Ownable
- ✅ **Bonus calculation** - `calculateBonus()` for staking rewards

This extension enables full contract administration and monitoring without needing to reference multiple interfaces.

**Important**: Our custom DPX smart contracts (ACR, FutureCarbonToken, RedemptionVault) do NOT interact with SwapERC20 directly. The interface is purely for manual operations, testing, and future integration if needed.

## Deployment Guide

Deploy your own SwapERC20 instance to collect protocol fees from token swaps on your platform.


### Prerequisites

1. Configure environment variables in `.env`:
```bash
# Wallet credentials (choose one)
PRIVATE_KEY=your_private_key_here
# OR
MNEMONIC="your twelve word seed phrase"

# RPC URLs
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
AVALANCHE_RPC_URL=https://api.avax.network/ext/bc/C/rpc
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key

# Contract verification
SNOWTRACE_API_KEY=your_snowtrace_api_key
SNOWTRACE_FUJI_API_KEY=your_snowtrace_fuji_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key

# SwapERC20 deployment parameters
PROTOCOL_FEE=30
PROTOCOL_FEE_LIGHT=7
PROTOCOL_FEE_WALLET=0xfeeWalletAddress
BONUS_SCALE=4
BONUS_MAX=50
```

**Authentication Notes:**
- **PRIVATE_KEY** (recommended): Script auto-reads from `.env`, no CLI flags needed
- **MNEMONIC**: Requires `--mnemonics "$MNEMONIC"` CLI flag (Foundry doesn't auto-read from `.env`)

SwapERC20 requires these constructor parameters at deployment:

| Parameter | Environment Variable | Default | Description | Max Value |
|-----------|---------------------|---------|-------------|-----------|
| `protocolFee` | `PROTOCOL_FEE` | 30 | Fee in basis points for standard swaps (0.3%) | 10000 |
| `protocolFeeLight` | `PROTOCOL_FEE_LIGHT` | 7 | Fee in basis points for `swapLight()` (0.07%) | 10000 |
| `protocolFeeWallet` | `PROTOCOL_FEE_WALLET` | 0xfeeWalletAddress | Address to receive protocol fees | - |
| `bonusScale` | `BONUS_SCALE` | 4 | Staking bonus scale factor | 77 |
| `bonusMax` | `BONUS_MAX` | 50 | Maximum bonus percentage (50%) | 100 |


2. Source the environment file:
```bash
source .env
```

### Deployment Options

The deployment script (`script/DeploySwapERC20.s.sol`) reads all constructor parameters from your `.env` file, keeping commands clean and simple.

**Choose your deployment method:**

| Use Case | Command |
|----------|---------|
| **With PRIVATE_KEY from .env** | `forge script script/DeploySwapERC20.s.sol --rpc-url <network> --broadcast` |
| **With explicit private key** | `forge script script/DeploySwapERC20.s.sol --rpc-url <network> --broadcast --private-key $PRIVATE_KEY` |
| **With mnemonic (account 0)** | `forge script script/DeploySwapERC20.s.sol --rpc-url <network> --broadcast --mnemonics "$MNEMONIC"` |
| **With mnemonic (custom index)** | `forge script script/DeploySwapERC20.s.sol --rpc-url <network> --broadcast --mnemonics "$MNEMONIC" --mnemonic-indexes 1` |
| **With verification** | Add `--verify` flag to any command above |
| **Local testing (Anvil)** | `forge script script/DeploySwapERC20.s.sol --rpc-url anvil --broadcast` |

### Network Deployment Examples

All constructor parameters are read from `.env`. Choose authentication method based on what you have configured.

**Avalanche Fuji Testnet:**
```bash
source .env
# Using PRIVATE_KEY from .env (recommended)
forge script script/DeploySwapERC20.s.sol --rpc-url fuji --broadcast --verify

# OR using MNEMONIC from .env
forge script script/DeploySwapERC20.s.sol --rpc-url fuji --broadcast --verify --mnemonics "$MNEMONIC"
```

**Ethereum Sepolia Testnet:**
```bash
source .env
# Using PRIVATE_KEY from .env (recommended)
forge script script/DeploySwapERC20.s.sol --rpc-url sepolia --broadcast --verify

# OR using MNEMONIC from .env (account index 0, default)
forge script script/DeploySwapERC20.s.sol --rpc-url sepolia --broadcast --verify --mnemonics "$MNEMONIC"

# OR using MNEMONIC with custom account index (e.g., index 1)
forge script script/DeploySwapERC20.s.sol --rpc-url sepolia --broadcast --verify --mnemonics "$MNEMONIC" --mnemonic-indexes 1
```

**Avalanche Mainnet:**
```bash
source .env
# Using PRIVATE_KEY from .env (recommended)
forge script script/DeploySwapERC20.s.sol --rpc-url avalanche --broadcast --verify

# OR using MNEMONIC from .env
forge script script/DeploySwapERC20.s.sol --rpc-url avalanche --broadcast --verify --mnemonics "$MNEMONIC"
```

**Local Anvil (testing):**
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy (PRIVATE_KEY not required for local)
source .env
forge script script/DeploySwapERC20.s.sol --rpc-url anvil --broadcast
```

## Interacting with Deployed Contract

Use Foundry's `cast` tool to interact with your deployed SwapERC20.

### Query Functions

```bash
# Get owner
cast call $SWAP_ADDRESS "owner()" --rpc-url $FUJI_RPC_URL

# Get protocol fee settings
cast call $SWAP_ADDRESS "protocolFee()" --rpc-url $FUJI_RPC_URL | cast --to-dec
cast call $SWAP_ADDRESS "protocolFeeLight()" --rpc-url $FUJI_RPC_URL | cast --to-dec

# Get fee wallet
cast call $SWAP_ADDRESS "protocolFeeWallet()" --rpc-url $FUJI_RPC_URL

# Calculate fee for specific amount
cast call $SWAP_ADDRESS \
  "calculateProtocolFee(address,uint256)" \
  0xWalletAddress \
  $(cast --to-wei 1000) \
  --rpc-url $FUJI_RPC_URL | cast --from-wei

# Check if nonce is used
cast call $SWAP_ADDRESS \
  "nonceUsed(address,uint256)" \
  0xSignerAddress \
  123 \
  --rpc-url $FUJI_RPC_URL

# Check authorization
cast call $SWAP_ADDRESS \
  "authorized(address)" \
  0xWalletAddress \
  --rpc-url $FUJI_RPC_URL
```

### Administrative Functions (Owner Only)

```bash
# Set protocol fee (basis points)
# With mnemonic:
cast send $SWAP_ADDRESS \
  "setProtocolFee(uint256)" \
  50 \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# OR with PRIVATE_KEY:
cast send $SWAP_ADDRESS \
  "setProtocolFee(uint256)" \
  50 \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Set protocol fee light
cast send $SWAP_ADDRESS \
  "setProtocolFeeLight(uint256)" \
  10 \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Update fee wallet
cast send $SWAP_ADDRESS \
  "setProtocolFeeWallet(address)" \
  0xNewFeeWallet \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Set staking contract
cast send $SWAP_ADDRESS \
  "setStaking(address)" \
  0xStakingContract \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Transfer ownership
cast send $SWAP_ADDRESS \
  "transferOwnership(address)" \
  0xNewOwner \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0
```

**Note:** Replace `--private-key $PRIVATE_KEY` with `--mnemonic "$MNEMONIC" --mnemonic-index 0` (or other index) for any command above.

### User Functions

```bash
# Authorize another address to sign on your behalf
cast send $SWAP_ADDRESS \
  "authorize(address)" \
  0xAuthorizedSigner \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Revoke authorization
cast send $SWAP_ADDRESS \
  "revoke()" \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Cancel nonces
cast send $SWAP_ADDRESS \
  "cancel(uint256[])" \
  "[123,124,125]" \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Execute a private swap (only specific sender can execute)
cast send $SWAP_ADDRESS \
  "swap(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1 \
  9999999999 \
  0x5Cd5F76686B86CB66494FeA4040b9Dea83129F81 \
  0xa0d34260E7fD4a84e15cD9BC2E1C51AbBA51A498 \
  200000000000000000000 \
  0x817AF3CEa0921CF33ACF0CA6456012a92b4c9261 \
  800000000000000000000 \
  28 \
  0xc61ce6783d4fdcf95446557e1477568ea465b7b656b43f90cabf48c055bc0ed5 \
  0x2d055626b34ec3e7a694668fc9a0b7ab31a067e48f708021441eeef4d48cb704 \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Execute a public swap (anyone can execute)
cast send $SWAP_ADDRESS \
  "swapAnySender(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  1 \
  9999999999 \
  0x5Cd5F76686B86CB66494FeA4040b9Dea83129F81 \
  0xa0d34260E7fD4a84e15cD9BC2E1C51AbBA51A498 \
  200000000000000000000 \
  0x817AF3CEa0921CF33ACF0CA6456012a92b4c9261 \
  800000000000000000000 \
  28 \
  0xc61ce6783d4fdcf95426557a1477568ea465b8b656b43f90cbbf48c055bc3ed3 \
  0x2d055626b34eb3e7a694668fc9a0b7ab31a077e48f708021401aeef4d48cb604 \
  --rpc-url $FUJI_RPC_URL \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0

# Validate an order before executing (read-only, no gas)
cast call $SWAP_ADDRESS \
  "check(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)(bytes32[])" \
  0x0000000000000000000000000000000000000000 \
  1 \
  9999999999 \
  0x5Cd5F76686B86CB66494FeA4040b9Dea83129F81 \
  0xa0d34260E7fD4a84e15cD9BC2E1C51AbBA51A498 \
  200000000000000000000 \
  0x817AF3CEa0921CF33ACF0CA6456012a92b4c9261 \
  800000000000000000000 \
  28 \
  0xc61ce6783d4fdcf95446557e1477568ea493b7b656b43f90cbbf48c055bc3ed3 \
  0x2d055626b34ec3e7a694668fc9a0b7ab31a871e48f708021401eeef4d48cb604 \
  --rpc-url $FUJI_RPC_URL
```

**Note:** Replace `--private-key $PRIVATE_KEY` with `--mnemonic "$MNEMONIC" --mnemonic-index 0` (or other index) for any command above.

## Swap Workflow & Signature Generation

SwapERC20 enables atomic token swaps between two parties using off-chain signatures. This section explains the complete workflow from creating a signed order to executing the swap.

### Overview: Two-Party System

**Two parties are involved:**
1. **Signer** - Creates and signs order offering to swap tokens (creates off-chain signature)
2. **Sender** - Executes the swap by providing their tokens and signature (executes an on-chain transaction)

### Complete Workflow

#### Step 0: Token Approvals

Both parties MUST approve the SwapERC20 contract to spend their tokens before any swap can succeed. Without these approvals, the swap transaction will fail!

**Important:** The signer must approve not just the `signerAmount`, but also account for protocol fees. Use the `calculateProtocolFee(address, uint256)` function on the SwapERC20 contract to determine the exact fee amount (see "Query Functions" section above for usage example). For example, if protocol fee is 1% and the signer wants to transfer 100 USDC tokens, they should approve 101 USDC tokens.

#### Step 1: Signer Creates a Signed Order (off-chain signature)

The signer specifies all terms of the swap and creates an EIP-712 signature. The signature includes these parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| **Chain ID** | Network where swap will execute | `11155111` (Sepolia) |
| **Contract Address** | Your deployed SwapERC20 address | `0xC376d2eD...` |
| **Nonce** | Unique number to prevent replay attacks | `1`, `2`, `3`, ... |
| **Expiry** | Order expiration (seconds since Unix epoch) | `1735689600` (Jan 1, 2025) |
| **Signer Wallet** | Address of the signer | `0x5Cd5F76...` |
| **Signer Token** | Token the signer is offering | `0xa0d342...` (USDC) |
| **Signer Amount** | Amount the signer is offering | `200000000000000000000` (200 tokens) |
| **Sender Wallet** | **Who can execute** (see below) | `0x0` or specific address |
| **Sender Token** | Token the signer wants to receive | `0x817AF3...` (DAI) |
| **Sender Amount** | Amount the signer wants to receive | `800000000000000000000` (800 tokens) |

**Critical Decision: Sender Wallet Address**

The `senderWallet` field determines who can execute the swap:

| Sender Wallet Value | Who Can Execute | Function to Use | Use Case |
|---------------------|-----------------|-----------------|----------|
| **`0x0000...0000`** (zero address) | **Anyone** | `swapAnySender()` | Public order book, any counterparty accepted |
| **Specific address** (e.g., `0x7099...`) | **Only that address** | `swap()` | Private swap with known counterparty |

**Example scenarios:**
- ✅ **Public swap**: Set `senderWallet = 0x0` - First person to execute gets the swap
- ✅ **Private swap**: Set `senderWallet = 0x70997970...` - Only this specific wallet can execute

#### Step 2: Generate the Signature

Use the provided script to generate the EIP-712 signature:

**Edit the script parameters inside the script:**

Open `script/CreateSwapSignature.s.sol` and customize these constants:

```solidity
// Network configuration
uint256 private constant CHAIN_ID = 11155111;        // Sepolia
uint256 private constant MNEMONIC_INDEX = 1;         // Your signer account index
address private constant SWAP_CONTRACT = 0xC376d2eD499B835E92b025067Ce96bF0FAAba71e;

// Order parameters
uint256 private constant NONCE = 1;                  // Increment for each new order or use any unused nonce
uint256 private constant EXPIRY = 9999999999;        // Far future for testing

// Signer details (what you're offering)
address private constant SIGNER_WALLET = 0x5Cd5F76686B86CB66494FeA4040b9Dea83129F81;
address private constant SIGNER_TOKEN = 0xa0d34260E7fD4a84e15cD9BC2E1C51AbBA51A498;
uint256 private constant SIGNER_AMOUNT = 200 ether;

// Sender details (what you want in return)
address private constant SENDER_WALLET = 0x0000000000000000000000000000000000000000;  // 0x0 = anyone
address private constant SENDER_TOKEN = 0x817AF3CEa0921CF33ACF0CA6456012a92b4c9261;
uint256 private constant SENDER_AMOUNT = 800 ether;
```

**Run the script:**

```bash
source .env
forge script script/CreateSwapSignature.s.sol --rpc-url sepolia
```

**Script output includes:**
- ✅ All order parameters
- ✅ Protocol fee fetched from contract (automatically included in signature)
- ✅ Signature components: `v`, `r`, `s`
- ✅ Ready-to-use cast command
- ✅ Signature validation (recovered address matches signer)

**Save these signature values - the sender needs them:**

#### Step 3: Sender Executes the Swap

The sender uses the signature to execute the swap on-chain.

**Which function to use?**

| Signature Type | Function | Who Can Execute |
|----------------|----------|-----------------|
| `senderWallet = 0x0` | `swapAnySender()` | Anyone with the signature |
| `senderWallet = specific address` | `swap()` | Only that specific address |

**A) Using swapAnySender() (for public orders)**

When the signature has `senderWallet = 0x0`, anyone can execute the swap.

**Function signature:**
```solidity
function swapAnySender(
    address recipient,    // Who receives the signer's tokens
    uint256 nonce,        // From the signature
    uint256 expiry,       // From the signature
    address signerWallet, // From the signature
    address signerToken,  // From the signature
    uint256 signerAmount, // From the signature
    address senderToken,  // From the signature
    uint256 senderAmount, // From the signature
    uint8 v,              // From the signature
    bytes32 r,            // From the signature
    bytes32 s             // From the signature
)
```

**What to pass:**
- **`recipient`**: Any address you choose (who will receive the signer's tokens)
- **All other parameters**: Use exact values from the signer's order and signature
- **Who executes the transaction**: Can be anyone (they pay gas and provide `senderAmount` of `senderToken`)

**B) Using swap() (for private orders)**

When the signature has `senderWallet = specific address`, only that address can execute.

**Function signature:**
```solidity
function swap(
    address recipient,    // Who receives the signer's tokens
    uint256 nonce,        // From the signature
    uint256 expiry,       // From the signature
    address signerWallet, // From the signature
    address signerToken,  // From the signature
    uint256 signerAmount, // From the signature
    address senderToken,  // From the signature
    uint256 senderAmount, // From the signature
    uint8 v,              // From the signature
    bytes32 r,            // From the signature
    bytes32 s             // From the signature
)
```

**What to pass:**
- **`recipient`**: Any address you choose (who will receive the signer's tokens)
- **All other parameters**: Use exact values from the signer's order and signature
- **Who executes the transaction**: Must be the address specified in `senderWallet` in the signature

**Important notes about the recipient parameter:**
- ✅ **Recipient can be ANY address** - it's not part of the signature, so the executor chooses
- ✅ Common choices:
  - Same as sender wallet (most common pattern, you execute and receive the tokens)
  - Third-party address (you execute, someone else receives)
- ⚠️ **Never use `0x0` as recipient** - tokens will be permanently lost!

### Token Flow During Swap

When the swap executes, here's what happens:

1. **Sender → Signer**: `senderAmount` of `senderToken` (what signer wanted)
2. **Signer → Recipient**: `signerAmount` of `signerToken` (what signer offered)
3. **Signer → Protocol Fee Wallet**: Protocol fee (deducted from signer's amount)

**Example:**
- Signer offers: 200 USDC
- Sender pays: 800 DAI
- Recipient receives: 200 USDC
- Signer receives: 800 DAI
- Protocol fee wallet receives 1 USDC (0.5% protocol fee (example))

### Validating Orders Before Execution

Before executing a swap, you can validate the order without spending gas using the `check()` function.

**Function signature:**
```solidity
function check(
    address senderWallet,
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
) external view returns (bytes32[] memory)
```

**What to pass:**
- **All parameters**: Use exact values from the signer's order and signature

**Interpreting results:**
- **`[]` (empty array)** = ✅ Order is valid and ready to execute
- **Non-empty array** = ❌ Contains error codes (decode with `cast --to-ascii`)

**Common errors returned:**
- `SignatureInvalid` - Wrong signature or parameters don't match what was signed
- `SignerAllowanceLow` - Signer hasn't approved tokens to the SwapERC20 contract
- `SenderAllowanceLow` - Sender hasn't approved tokens to the SwapERC20 contract
- `SignerBalanceLow` - Signer has insufficient token balance
- `SenderBalanceLow` - Sender has insufficient token balance
- `NonceAlreadyUsed` - This nonce was already used by the signer
- `OrderExpired` - Current time is past the expiry timestamp

### Best Practices

**For Signers:**
- ✅ Use sequential nonces (1, 2, 3, ...) to track orders
- ✅ Set realistic expiry times (use Unix timestamp calculators)
- ✅ Approve tokens before sharing the signature
- ✅ Verify your order with `check()` before sharing
- ⚠️ Never reuse nonces - each order needs a unique nonce

**For Senders:**
- ✅ Validate the order with `check()` before executing
- ✅ Approve tokens before attempting to execute
- ✅ Double-check you're using the correct function (swap vs swapAnySender)
- ✅ Ensure you have sufficient balance
- ⚠️ Be aware of protocol fees (deducted from signer's amount)

**Security Considerations:**
- 🔒 Signatures are deterministic - same parameters = same signature
- 🔒 Each nonce can only be used once per signer
- 🔒 Orders can be cancelled before execution using `cancel(uint256[])`
- 🔒 Always verify amounts and token addresses before signing or executing

## Updating Dependencies (If Needed)

To update to a newer AirSwap version in the future:

```bash
# Update to specific version
cd lib/airswap-protocols
git fetch
git checkout v5.1.0  # or desired version
cd ../..
git add lib/airswap-protocols
git commit -m "Update AirSwap to v5.1.0"

# Update Solady if needed
cd lib/solady
git fetch
git checkout v0.0.180  # or desired version
cd ../..
git add lib/solady
git commit -m "Update Solady to v0.0.180"
```

## Resources

- **AirSwap Documentation**: https://about.airswap.io/
- **GitHub Repository**: https://github.com/airswap/airswap-protocols
- **Solady Documentation**: https://github.com/vectorized/solady
- **EIP-712 Specification**: https://eips.ethereum.org/EIPS/eip-712
