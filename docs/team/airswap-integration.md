# AirSwap SwapERC20 Integration Guide

## Overview

This project integrates **AirSwap SwapERC20 v5.0.0** for atomic ERC20 token swaps using off-chain signed orders. We deploy our own SwapERC20 instance to collect protocol fees from all token swaps on the platform.

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
| **With mnemonic** | `forge script script/DeploySwapERC20.s.sol --rpc-url <network> --broadcast --mnemonics "$MNEMONIC"` |
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

# OR using MNEMONIC from .env
forge script script/DeploySwapERC20.s.sol --rpc-url sepolia --broadcast --verify --mnemonics "$MNEMONIC"
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

## Updating Configuration

After deployment, you can update parameters (owner only):

```bash
# Update protocol fee
cast send $SWAP_ADDRESS \
  "setProtocolFee(uint256)" \
  50 \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY

# Update fee wallet
cast send $SWAP_ADDRESS \
  "setProtocolFeeWallet(address)" \
  0xNewFeeWallet \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY

# Update staking contract (for bonus calculations)
cast send $SWAP_ADDRESS \
  "setStaking(address)" \
  0xStakingContract \
  --rpc-url fuji \
  --private-key $PRIVATE_KEY
```

## Testing

### Fork Testing

Test your deployed SwapERC20 instance using Foundry's fork testing:

```bash
# Set your deployed contract address
export SWAP_ADDRESS=0xYourDeployedSwapAddress

# Fork Fuji testnet (where your contract is deployed)
forge test --fork-url $FUJI_RPC_URL --match-test testSwap -vvv

# Fork Avalanche mainnet (for production testing)
forge test --fork-url $AVALANCHE_RPC_URL --match-test testSwap -vvv
```

### Manual Testing with Cast

```bash
# Check deployment
cast call $SWAP_ADDRESS "owner()" --rpc-url $FUJI_RPC_URL

# Calculate fees
cast call $SWAP_ADDRESS \
  "calculateProtocolFee(address,uint256)" \
  0xUserAddress \
  1000000000000000000000 \
  --rpc-url $FUJI_RPC_URL | cast --to-dec

# Check nonce usage
cast call $SWAP_ADDRESS \
  "nonceUsed(address,uint256)" \
  0xSignerAddress \
  1 \
  --rpc-url $FUJI_RPC_URL
```

## Key SwapERC20 Features

### Three Swap Methods

1. **`swap()`** - Standard swap with known sender
2. **`swapAnySender()`** - Swap where sender can be anyone
3. **`swapLight()`** - Gas-optimized swap (recipient is msg.sender)

### Protocol Fees

- Configurable protocol fee (default: 30 basis points = 0.3%)
- Lower fees for stakers via `bonusScale` and `bonusMax`
- Check fee before swapping: `calculateProtocolFee(wallet, amount)`

### Nonce Management

- Each order has a unique nonce to prevent replay attacks
- Nonces are bit-packed in groups of 256 for gas efficiency
- Check if used: `nonceUsed(wallet, nonce)`

### Order Validation

Before executing a swap, validate the order using `check()`:

```bash
# Via cast
cast call $SWAP_ADDRESS \
  "check(address,uint256,uint256,address,address,uint256,address,uint256,uint8,bytes32,bytes32)" \
  $SENDER_WALLET \
  $NONCE \
  $EXPIRY \
  $SIGNER_WALLET \
  $SIGNER_TOKEN \
  $SIGNER_AMOUNT \
  $SENDER_TOKEN \
  $SENDER_AMOUNT \
  $V \
  $R \
  $S \
  --rpc-url $FUJI_RPC_URL
```

Or in Solidity tests:

```solidity
bytes32[] memory errors = swap.check(
    senderWallet,
    nonce,
    expiry,
    signerWallet,
    signerToken,
    signerAmount,
    senderToken,
    senderAmount,
    v,
    r,
    s
);

require(errors.length == 0, "Invalid order");
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
  --private-key $PRIVATE_KEY

# Update fee wallet
cast send $SWAP_ADDRESS \
  "setProtocolFeeWallet(address)" \
  0xNewFeeWallet \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Set staking contract
cast send $SWAP_ADDRESS \
  "setStaking(address)" \
  0xStakingContract \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Transfer ownership
cast send $SWAP_ADDRESS \
  "transferOwnership(address)" \
  0xNewOwner \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY
```

### User Functions

```bash
# Authorize another address to sign on your behalf
cast send $SWAP_ADDRESS \
  "authorize(address)" \
  0xAuthorizedSigner \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Revoke authorization
cast send $SWAP_ADDRESS \
  "revoke()" \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY

# Cancel nonces
cast send $SWAP_ADDRESS \
  "cancel(uint256[])" \
  "[123,124,125]" \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY
```

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
