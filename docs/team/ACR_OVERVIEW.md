# ACR Governance Token System

Complete documentation for the ACR governance token, Governor contract, and DAO setup.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Token Features](#token-features)
- [Deployment Guide](#deployment-guide)
- [Testing](#testing)
- [Upgrading the Token](#upgrading-the-token)
- [Interacting with Contracts](#interacting-with-contracts)
- [Production Workflow](#production-workflow)

## Overview

The ACR system provides a complete on-chain governance solution built on Avalanche using Foundry and OpenZeppelin Contracts. It consists of two main smart contracts:

1. **ACR Token (ACR in production)** - An upgradeable ERC-20 governance token with voting capabilities
2. **ACRGovernor** - An OpenZeppelin Governor contract for DAO governance

### Key Components

- **Governance Token**: ERC-20 token with voting power (ERC20Votes)
- **DAO Integration**: Compatible with Tally for on-chain governance
- **Treasury Management**: Multi-signature wallet support via Safe Global
- **Vesting Support**: Integration with Hedgey Finance for token vesting
- **Upgradeability**: UUPS proxy pattern for future upgrades

## Architecture

### ACR Token Contract

**Location**: `src/ACR.sol`

**Extends OpenZeppelin Contracts**:
- `Initializable` - Initialization pattern for upgradeable contracts
- `ERC20Upgradeable` - Standard ERC-20 implementation
- `ERC20BurnableUpgradeable` - Token burning functionality
- `ERC20PausableUpgradeable` - Emergency pause capability
- `OwnableUpgradeable` - Access control
- `ERC20PermitUpgradeable` - Gasless approvals (EIP-2612)
- `ERC20VotesUpgradeable` - On-chain voting with delegation
- `UUPSUpgradeable` - Upgradeability pattern

**Custom Functions**:
- `initialize(string name, string symbol, uint256 initialSupply)` - Initialize the token
- `mint(address to, uint256 amount)` - Mint new tokens (owner only)
- `pause()` / `unpause()` - Pause/unpause transfers (owner only)
- `_authorizeUpgrade(address)` - Control upgrades (owner only)

### ACRGovernor Contract

**Location**: `src/ACRGovernor.sol`

**Extends OpenZeppelin Contracts**:
- `Governor` - Core governance functionality
- `GovernorSettings` - Configurable parameters
- `GovernorCountingSimple` - Simple voting (For/Against/Abstain)
- `GovernorVotes` - Token-weighted voting
- `GovernorVotesQuorumFraction` - Percentage-based quorum

**Governor Parameters**:
These are configured via environment variables in `.env`:
- `VOTING_DELAY` - Delay before voting starts (in blocks)
- `VOTING_PERIOD` - Duration of voting period (in blocks)
- `PROPOSAL_THRESHOLD` - Minimum tokens required to create proposal
- `QUORUM_PERCENTAGE` - Percentage of total supply required for quorum (e.g., 4 for 4%)

**Example Governor Configuration**:
```bash
# In .env file
VOTING_DELAY=1              # Voting starts 1 block after proposal
VOTING_PERIOD=50400         # ~1 week on Avalanche (12s blocks)
PROPOSAL_THRESHOLD=0        # Anyone can propose
QUORUM_PERCENTAGE=4         # 4% quorum
```

## Token Features

### ERC-20 Standard Features
- ✅ Full ERC-20 compliance
- ✅ 18 decimal precision
- ✅ Standard transfer, approve, and allowance functions

### Advanced Features
- ✅ **Burnable**: Token holders can burn their own tokens
- ✅ **Mintable**: Owner can mint new tokens
- ✅ **Pausable**: Owner can pause/unpause all token transfers
- ✅ **Permit (ERC-2612)**: Gasless approvals via off-chain signatures
- ✅ **Voting/Governance (ERC20Votes)**:
  - On-chain governance with vote delegation
  - Historical balance tracking via checkpoints
  - Self-delegation required to activate voting power
- ✅ **Upgradeable (UUPS)**:
  - Fix bugs without redeployment
  - Add new features while preserving state
  - Token address never changes
  - Gas-efficient proxy pattern

### Security Features
- Owner-based access control
- Pausable for emergency situations
- Owner-controlled upgrades only
- Battle-tested OpenZeppelin implementation

## Deployment Guide

### Prerequisites

1. Configure environment variables in `.env`:
```bash
# Wallet credentials (choose one)
PRIVATE_KEY=your_private_key_here
# OR
MNEMONIC="your twelve word seed phrase"

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key

# Contract verification (optional)
ETHERSCAN_API_KEY=your_etherscan_api_key

# Governor parameters
VOTING_DELAY=1
VOTING_PERIOD=50400
PROPOSAL_THRESHOLD=0
QUORUM_PERCENTAGE=4
```

2. Source the environment file:
```bash
source .env
```

### Deploy ACR Token

#### Local Deployment (Anvil)

```bash
# Terminal 1: Start local node
anvil

# Terminal 2: Deploy with default parameters (ACR Token, ACR, 1,000,000 supply)
forge script script/Deploy.s.sol --rpc-url anvil --broadcast

# Deploy with custom parameters
TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 \
  forge script script/Deploy.s.sol --rpc-url anvil --broadcast
```

#### Testnet Deployment (Sepolia)

**Without verification:**
```bash
source .env

# Deploy with default parameters
forge script script/Deploy.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Deploy with custom parameters
TOKEN_NAME="ACX RWA" TOKEN_SYMBOL="ACR" INITIAL_SUPPLY=1000000000 \
  forge script script/Deploy.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

**With verification:**
```bash
source .env

TOKEN_NAME="ACX RWA" TOKEN_SYMBOL="ACR" INITIAL_SUPPLY=0 \
  forge script script/Deploy.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

**IMPORTANT**: The deployment outputs TWO addresses:
1. **Proxy Address** - This is the address users interact with (SAVE THIS!)
2. **Implementation Address** - Internal address, users don't need this

Always use the **Proxy Address** for all interactions!

### Deploy Governor Contract

After deploying the ACR token, deploy the Governor contract:

```bash
source .env

# Set the token address from previous deployment
ACR_TOKEN_ADDRESS="0xYourTokenProxyAddress" \
  forge script script/ACRGovernor.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

### Supported Networks

| Network | RPC Alias | Faucet | Block Explorer |
|---------|-----------|--------|----------------|
| **Sepolia** | `sepolia` | [Sepolia Faucet](https://sepoliafaucet.com/) | [Etherscan](https://sepolia.etherscan.io/) |
| **Avalanche Fuji** | `fuji` | [Avalanche Faucet](https://faucet.avax.network/) | [SnowTrace](https://testnet.snowtrace.io/) |
| **Local Anvil** | `anvil` | N/A (built-in) | N/A |

For Avalanche Fuji deployment with Blockscout verification:
```bash
source .env

TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=1000000 \
  forge script script/Deploy.s.sol \
  --rpc-url fuji \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://api.routescan.io/v2/network/testnet/evm/43113/etherscan \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

## Testing

### Run All Tests

```bash
# Run all tests
forge test

# Run with increased verbosity
forge test -vv

# Run with full verbosity (shows stack traces)
forge test -vvv
```

### Run Specific Test Contracts

```bash
# Run ACR token tests
forge test --match-contract ACRTest -vv

# Run basic ACR tests
forge test --match-contract ACRBasic -vv

# Run Governor tests
forge test --match-contract ACRGovernor -vv
```

### Run Specific Tests

```bash
# Test token initialization
forge test --match-test test_Initialization -vv

# Test minting
forge test --match-test test_Mint -vv

# Test upgradeability
forge test --match-test test_UpgradeToNewImplementation -vvv

# Test voting delegation
forge test --match-test test_Delegation -vv
```

### Gas Reporting

```bash
forge test --gas-report
```

### Test Coverage

```bash
forge coverage
```

## Upgrading the Token

The ACR token uses the UUPS (Universal Upgradeable Proxy Standard) pattern for upgrades.

### Benefits of Upgradeability

- ✅ Fix bugs without redeployment
- ✅ Add new features while preserving state
- ✅ Token address never changes
- ✅ Gas-efficient (UUPS pattern)
- ✅ Owner-controlled upgrades only

### How to Upgrade

```bash
source .env

# Set the proxy address (the address from initial deployment)
export PROXY_ADDRESS=0xYourProxyAddressHere

# Run the upgrade script
forge script script/Upgrade.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

### What Happens During Upgrade

1. New implementation contract is deployed
2. Proxy is updated to point to new implementation
3. All state (balances, ownership, etc.) is preserved
4. Users continue using the same proxy address
5. New logic/features become available immediately

### Testing Upgrades

```bash
# Run all upgrade tests
forge test --match-test test_Upgrade -vvv

# Run specific upgrade test
forge test --match-test test_UpgradeToNewImplementation -vvv
```

## Interacting with Contracts

Use Foundry's `cast` tool to interact with deployed contracts.

### Setup

Always source your environment file first:
```bash
source .env
```

### Understanding Output Decoding

`cast call` returns raw ABI-encoded hex data. To decode it:

1. **For strings**: Use `xargs cast --to-ascii`
2. **For numbers**: Use `cast --to-dec` or `cast --from-wei`
3. **For addresses/booleans**: Use `xargs cast abi-decode`

### Read Operations (No Gas Required)

#### Get Token Information

```bash
# Token name
cast call <TOKEN_ADDRESS> "name()" --rpc-url sepolia | xargs cast --to-ascii

# Token symbol
cast call <TOKEN_ADDRESS> "symbol()" --rpc-url sepolia | xargs cast --to-ascii

# Decimals
cast call <TOKEN_ADDRESS> "decimals()" --rpc-url sepolia | cast --to-dec

# Total supply (in tokens)
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url sepolia | cast --from-wei
```

#### Check Balances and Allowances

```bash
# Check balance (in tokens)
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)(uint256)" \
  0xYourAddress \
  --rpc-url sepolia | cast --from-wei

# Check allowance
cast call <TOKEN_ADDRESS> \
  "allowance(address,address)(uint256)" \
  0xOwnerAddress \
  0xSpenderAddress \
  --rpc-url sepolia | cast --from-wei
```

#### Check Contract State

```bash
# Check owner
cast call <TOKEN_ADDRESS> "owner()" --rpc-url sepolia | \
  xargs cast abi-decode "owner()(address)"

# Check if paused
cast call <TOKEN_ADDRESS> "paused()" --rpc-url sepolia | \
  xargs cast abi-decode "paused()(bool)"
```

#### Check Voting Power

```bash
# Get current voting power (in tokens)
cast call <TOKEN_ADDRESS> \
  "getVotes(address)(uint256)" \
  0xYourAddress \
  --rpc-url sepolia | cast --from-wei

# Get past voting power at specific block
cast call <TOKEN_ADDRESS> \
  "getPastVotes(address,uint256)(uint256)" \
  0xYourAddress \
  12345678 \
  --rpc-url sepolia | cast --from-wei

# Check delegate
cast call <TOKEN_ADDRESS> \
  "delegates(address)(address)" \
  0xYourAddress \
  --rpc-url sepolia | xargs cast abi-decode "delegates(address)(address)"
```

### Write Operations (Require Gas)

#### Token Transfers

```bash
# Transfer tokens (amount in wei)
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  0xRecipientAddress \
  $(cast --to-wei 1000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Transfer from (requires approval)
cast send <TOKEN_ADDRESS> \
  "transferFrom(address,address,uint256)" \
  0xFromAddress \
  0xToAddress \
  $(cast --to-wei 1000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Approvals

```bash
# Approve spender
cast send <TOKEN_ADDRESS> \
  "approve(address,uint256)" \
  0xSpenderAddress \
  $(cast --to-wei 1000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Minting (Owner Only)

```bash
# Mint tokens to address
cast send <TOKEN_ADDRESS> \
  "mint(address,uint256)" \
  0xRecipientAddress \
  $(cast --to-wei 1000000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Burning

```bash
# Burn your own tokens
cast send <TOKEN_ADDRESS> \
  "burn(uint256)" \
  $(cast --to-wei 500) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Pause/Unpause (Owner Only)

```bash
# Pause token transfers
cast send <TOKEN_ADDRESS> "pause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Unpause token transfers
cast send <TOKEN_ADDRESS> "unpause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Vote Delegation

**IMPORTANT**: You must delegate voting power (even to yourself) to activate it for governance!

```bash
# Delegate to yourself
cast send <TOKEN_ADDRESS> \
  "delegate(address)" \
  <YOUR_OWN_ADDRESS> \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Delegate to another address
cast send <TOKEN_ADDRESS> \
  "delegate(address)" \
  0xDelegateAddress \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Ownership Transfer (Owner Only)

```bash
# Transfer ownership
cast send <TOKEN_ADDRESS> \
  "transferOwnership(address)" \
  0xNewOwnerAddress \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

### Helper Aliases

Add these to your `~/.bashrc` or `~/.zshrc` for convenience:

```bash
# Set your token address
export TOKEN_ADDRESS=0xYourTokenAddress
export RPC_URL=sepolia

# Read operations
alias token-name='cast call $TOKEN_ADDRESS "name()" --rpc-url $RPC_URL | xargs cast --to-ascii'
alias token-symbol='cast call $TOKEN_ADDRESS "symbol()" --rpc-url $RPC_URL | xargs cast --to-ascii'
alias token-supply='cast call $TOKEN_ADDRESS "totalSupply()" --rpc-url $RPC_URL | cast --from-wei'
alias token-balance='cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $1 --rpc-url $RPC_URL | cast --from-wei'
alias token-votes='cast call $TOKEN_ADDRESS "getVotes(address)(uint256)" $1 --rpc-url $RPC_URL | cast --from-wei'

# Usage:
# token-name
# token-balance 0xYourAddress
# token-votes 0xYourAddress
```

## Production Workflow

For a complete step-by-step guide on launching the ACR token in production, including:
- Creating multisig Treasury wallets
- Deploying and configuring the token
- Setting up DAO on Tally
- Creating vesting schedules with Hedgey
- Delegating voting power
- Creating and voting on proposals

See: **[ACR Deployment Workflow](ACR_DEPLOYMENT.md)**

## Additional Resources

- [OpenZeppelin Contracts Documentation](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Tally Documentation](https://docs.tally.xyz/)
- [Safe Global Documentation](https://docs.safe.global/)
- [Hedgey Finance Documentation](https://docs.hedgey.finance/)

## Contract Source Files

- Token Contract: [`src/ACR.sol`](../src/ACR.sol)
- Governor Contract: [`src/ACRGovernor.sol`](../src/ACRGovernor.sol)
- Deployment Script: [`script/Deploy.s.sol`](../script/Deploy.s.sol)
- Governor Deployment: [`script/ACRGovernor.s.sol`](../script/ACRGovernor.s.sol)
- Upgrade Script: [`script/Upgrade.s.sol`](../script/Upgrade.s.sol)
- Test Suite: [`test/ACR.t.sol`](../test/ACR.t.sol), [`test/ACRGovernor.t.sol`](../test/ACRGovernor.t.sol)
