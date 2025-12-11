# DPX Platform - Carbon Credit Tokenization

Complete documentation for the DPX (Decentralized Project Exchange) platform smart contracts.

## Table of Contents

- [Overview](#overview)
- [Architecture Components](#architecture-components)
- [Deployment Guide](#deployment-guide)
- [Interacting with Contracts](#interacting-with-contracts)
- [Testing](#testing)
- [Upgrading FctFactory](#upgrading-fctfactory)
- [Contract Source Files](#contract-source-files)
- [Additional Resources](#additional-resources)

## Overview

The DPX (Decentralized Project Exchange) system enables tokenization of future carbon credits. Project developers can mint tokens representing future carbon credits, which investors can purchase. Once the project completes and real carbon credits are issued and sold, token holders can redeem their tokens for USDT proportional to the sale proceeds.

### How It Works

1. **Project Creation**: Platform owner creates a carbon credit project with name, symbol, supply, vintage year, registry code, and metadata
2. **Token Deployment**: A FutureCarbonToken contract (extended ERC-20 token) is automatically deployed with the project details
3. **Token Trading**: Investors trade standard ERC-20 compatible tokens on any platform, including our [SwapBox](SWAPBOX_OVERVIEW.md) for peer-to-peer atomic swaps
4. **Carbon Credit Delivery**: Real carbon credits are delivered off-chain, sold for proceeds (typically USDT)
5. **Vault Deployment & Funding**: Owner brings sale proceeds on-chain, deploys RedemptionVault, and funds it with USDT
6. **Redemption**: Vault is activated and token holders redeem their tokens for pro-rata USDT distribution

## Architecture Components

### 1. FctFactory (Upgradeable via Proxy)

**Purpose**: Central factory contract for deploying and managing all project tokens and redemption vaults.

**Upgradeability**: UUPS proxy pattern - Implementation can be upgraded to add new features

**Key Responsibilities**:
- Create new projects (owner-only)
- Deploy `FutureCarbonToken` contracts with project metadata (vintage year, registry code, custom metadata)
- Deploy corresponding `RedemptionVault` contracts (separately, when needed)
- Maintain registry mappings: `token address -> project ID`, `project ID -> vault address`
- Store immutable project information (name, symbol, supply, vintage year, registry code)
- Provide discovery functions for querying all projects

**Extends OpenZeppelin Contracts**:
- `Initializable` - Initialization pattern for upgradeable contracts
- `UUPSUpgradeable` - Upgradeable proxy pattern
- `OwnableUpgradeable` - Access control

**Custom Business Logic**:
- Project creation with immediate token deployment
- Token and vault deployment
- Project registry and discovery
- Reverse lookup mappings for tokens and vaults

---

### 2. FutureCarbonToken (Non-Upgradeable)

**Purpose**: ERC-20 token representing future carbon credits for a specific project.

**Upgradeability**: Not upgradeable - Each project gets an immutable token contract

**Key Features**:
- Standard ERC-20 token with transfer, approve, and allowance
- Gasless approvals via EIP-2612 permit (approve by signature, no gas cost)
- Mintable by owner (typically only at deployment)
- Initial supply minted to a specified receiver address (can differ from owner)
- Burnable (required for redemption process)
- Pausable (emergency stop for transfers)
- 18 decimals (standard ERC-20 precision)
- Immutable project metadata: vintage year, registry code, custom key-value pairs

**Extends OpenZeppelin Contracts**:
- `ERC20` - Standard ERC-20 implementation
- `ERC20Permit` - Gasless approvals via signatures (EIP-2612)
- `ERC20Burnable` - Burn functionality
- `ERC20Pausable` - Pause/unpause transfers
- `Ownable` - Access control

**Custom Business Logic**:
- Custom `mint()` function (owner-only wrapper around `_mint`)
- Custom `pause()`/`unpause()` functions (owner-only wrappers)
- Required `_update()` override for multiple inheritance
- Metadata storage and retrieval: `vintageYear`, `projectRegistryCode`, and custom metadata array
- Getter functions: `getVintageYear()`, `getProjectRegistryCode()`, `getMetadataEntries()`, `getProjectMetadata()`

---

### 3. RedemptionVault (Non-Upgradeable)

**Purpose**: Holds proceeds from carbon credit sales (typically stablecoins like USDT or USDC) and facilitates token redemption.

**Upgradeability**: Not upgradeable - Each vault is specific to one project with immutable redemption logic

**Key Responsibilities**:
- Store proceeds from carbon credit sales (configurable token, typically stablecoins like USDT or USDC)
- Calculate pro-rata redemption rate: `redemptionRatePerToken = totalProceeds / futureTokenTotalSupply`
- Execute token-for-proceeds swaps
- Burn redeemed FutureCarbonTokens (prevents double-redemption)
- Track redemption statistics

**Extends OpenZeppelin Contracts**:
- `Ownable` - Access control for admin functions
- `Pausable` - Emergency pause functionality
- `IERC20` (interface) - For interacting with tokens

**Custom Business Logic**:
- `activateRedemption()` - Calculate and set redemption rate based on deposited USDT
- `swap()` - Execute token-to-USDT redemption (burns tokens, transfers USDT)
- Pro-rata distribution calculation
- Redemption lifecycle management

**Example Redemption**:
- Total USDT deposited: 1,000,000 USDT
- Total token supply: 10,000,000 tokens
- Redemption rate: 0.1 USDT per token
- User has 5,000 tokens → receives 500 USDT

---

## Deployment Guide

### Prerequisites

1. Configure environment variables in `.env`:
```bash
# Wallet credentials (choose one)
MNEMONIC="your twelve word seed phrase"
# OR
PRIVATE_KEY=your_private_key_here

# RPC URLs
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
AVALANCHE_RPC_URL=https://api.avax.network/ext/bc/C/rpc
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key

# Contract verification
SNOWTRACE_API_KEY=your_snowtrace_api_key
SNOWTRACE_FUJI_API_KEY=your_snowtrace_fuji_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key

# Optional: Owner address (multisig recommended for production)
OWNER_ADDRESS=0xYourMultisigAddress
```

2. Source the environment file:
```bash
source .env
```

### Deploy DPX Platform (FctFactory)

The FctFactory is deployed using the UUPS proxy pattern for upgradeability.

**Choose your deployment method:**

| Use Case | Command |
|----------|---------|
| **With mnemonic (account 0)** | `forge script script/DeployFctFactory.s.sol --rpc-url <network> --broadcast --mnemonics "$MNEMONIC"` |
| **With mnemonic (custom index)** | `forge script script/DeployFctFactory.s.sol --rpc-url <network> --broadcast --mnemonics "$MNEMONIC" --mnemonic-indexes 1` |
| **With PRIVATE_KEY from .env** | `forge script script/DeployFctFactory.s.sol --rpc-url <network> --broadcast --private-key $PRIVATE_KEY` |
| **With custom owner (production)** | Add `OWNER_ADDRESS=0xMultisig` before command |
| **With verification** | Add `--verify --etherscan-api-key $ETHERSCAN_API_KEY` to any command above |
| **Local testing (Anvil)** | `forge script script/DeployFctFactory.s.sol --rpc-url anvil --broadcast` |

### Network Deployment Examples

**Ethereum Sepolia Testnet:**
```bash
source .env

# Using mnemonic (account 0, recommended)
forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC"

# With custom owner and verification (production)
OWNER_ADDRESS=0xYourMultisigAddress \
  forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --mnemonics "$MNEMONIC"

# Using mnemonic with custom account index
forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 1
```

**Local Anvil (testing):**
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
source .env
forge script script/DeployFctFactory.s.sol --rpc-url anvil --broadcast
```

**IMPORTANT**: The deployment outputs TWO addresses:
1. **Proxy Address** - This is the main address users and developers interact with (SAVE THIS!)
2. **Implementation Address** - Internal contract, users don't need this

Always use the **Proxy Address** for all interactions!

### Post-Deployment Steps

1. **Verify contracts on Etherscan** (if not done with `--verify` flag)
2. **Transfer ownership to multisig** (if not done during deployment):
   ```bash
   cast send <PROXY_ADDRESS> \
     "transferOwnership(address)" \
     0xMultisigAddress \
     --rpc-url sepolia \
     --mnemonics "$MNEMONIC" \
     --mnemonic-index 0
   ```
3. **Test basic functionality**:
   - Create a test project
   - Verify token deployment
   - Deploy vault and test redemption flow

## Interacting with Contracts

Use Foundry's `cast` tool to interact with deployed contracts.

### Setup

```bash
source .env
export FACTORY_ADDRESS=0xYourProxyAddress
export SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
```

### 1. Project Management (FctFactory)

#### Query Functions

```bash
# Get total project count
cast call $FACTORY_ADDRESS "getProjectCount()" --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get next project ID
cast call $FACTORY_ADDRESS "getNextProjectId()" --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get project details by ID
cast call $FACTORY_ADDRESS \
  "getProject(uint256)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL

# Returns: (projectId, name, symbol, initialSupply, tokenAddress, vaultAddress, createdAt, vintageYear, projectRegistryCode)

# Get all projects (may be gas-intensive)
cast call $FACTORY_ADDRESS "getAllProjects()" --rpc-url $SEPOLIA_RPC_URL

# Get token address for project
cast call $FACTORY_ADDRESS \
  "getTokenForProject(uint256)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL | xargs cast abi-decode "getTokenForProject(uint256)(address)"

# Get project ID for token
cast call $FACTORY_ADDRESS \
  "getProjectIdForToken(address)" \
  0xTokenAddress \
  --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get vault address for token
cast call $FACTORY_ADDRESS \
  "getVaultForToken(address)" \
  0xTokenAddress \
  --rpc-url $SEPOLIA_RPC_URL | xargs cast abi-decode "getVaultForToken(address)(address)"

# Check if project exists
cast call $FACTORY_ADDRESS \
  "projectIdExists(uint256)" \
  0 \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Create Project (Owner Only)

```bash
# Create project with empty metadata
# Parameters: name, symbol, initialSupply, receiver, vintageYear, registryCode, metadata
# With mnemonic:
cast send $FACTORY_ADDRESS \
  "createProject(string,string,uint256,address,uint256,string,(string,string)[])" \
  "Future Carbon Credit - Alpha" \
  "FCC-ALPHA" \
  $(cast --to-wei 1000000) \
  0xReceiverAddress \
  2025 \
  "VCS-1234-2025" \
  "[]" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# OR with PRIVATE_KEY:
cast send $FACTORY_ADDRESS \
  "createProject(string,string,uint256,address,uint256,string,(string,string)[])" \
  "Future Carbon Credit - Alpha" \
  "FCC-ALPHA" \
  $(cast --to-wei 1000000) \
  0xReceiverAddress \
  2025 \
  "VCS-1234-2025" \
  "[]" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Note: This automatically deploys the FutureCarbonToken with the provided metadata
# The initial supply is minted to the specified receiver address
# Returns: (projectId, tokenAddress)
```

#### Deploy Vault for Project (Owner Only)

```bash
# Deploy RedemptionVault for a project
# With mnemonic:
cast send $FACTORY_ADDRESS \
  "deployVault(uint256,address)" \
  0 \
  0xUSDTAddress \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# OR with PRIVATE_KEY:
cast send $FACTORY_ADDRESS \
  "deployVault(uint256,address)" \
  0 \
  0xUSDTAddress \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Note:** Replace `--private-key $PRIVATE_KEY` with `--mnemonics "$MNEMONIC" --mnemonic-index 0` (or other index) for any command above.

---

### 2. RedemptionVault Interactions

#### Query Functions

```bash
# Check if redemption is active
cast call <VAULT_ADDRESS> \
  "isRedemptionActive()" \
  --rpc-url $SEPOLIA_RPC_URL | xargs cast abi-decode "isRedemptionActive()(bool)"

# Get redemption rate per token
cast call <VAULT_ADDRESS> \
  "getRedemptionRate()" \
  --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get available stablecoin in vault
cast call <VAULT_ADDRESS> \
  "getAvailableStablecoin()" \
  --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get total amount redeemed
cast call <VAULT_ADDRESS> \
  "totalRedeemed()" \
  --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get FutureCarbonToken address
cast call <VAULT_ADDRESS> \
  "futureToken()" \
  --rpc-url $SEPOLIA_RPC_URL

# Get stablecoin address
cast call <VAULT_ADDRESS> \
  "stablecoin()" \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Activate Redemption (Owner Only)

```bash
# Step 1: Deposit stablecoin to the vault
cast send <USDT_ADDRESS> \
  "transfer(address,uint256)" \
  <VAULT_ADDRESS> \
  1000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Step 2: Activate redemption (calculates rate)
cast send <VAULT_ADDRESS> \
  "activateRedemption()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0
```

#### Redeem Tokens (Token Holders)

```bash
# Step 1: Approve vault to burn your tokens
cast send <TOKEN_ADDRESS> \
  "approve(address,uint256)" \
  <VAULT_ADDRESS> \
  $(cast --to-wei 1000) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Step 2: Swap tokens for stablecoin
cast send <VAULT_ADDRESS> \
  "swap(uint256)" \
  $(cast --to-wei 1000) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0
```

#### Administrative Functions (Owner Only)

```bash
# Pause redemptions
cast send <VAULT_ADDRESS> \
  "pause()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Unpause redemptions
cast send <VAULT_ADDRESS> \
  "unpause()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0
```

**Note:** Replace `--mnemonics "$MNEMONIC" --mnemonic-index 0` with `--private-key $PRIVATE_KEY` for any command above.

---

### 3. FutureCarbonToken Interactions

FutureCarbonToken is a standard ERC-20 with additional features.

#### Query Functions

```bash
# Get token name
cast call <TOKEN_ADDRESS> "name()" --rpc-url $SEPOLIA_RPC_URL | xargs cast --to-ascii

# Get token symbol
cast call <TOKEN_ADDRESS> "symbol()" --rpc-url $SEPOLIA_RPC_URL | xargs cast --to-ascii

# Get total supply
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url $SEPOLIA_RPC_URL | cast --from-wei

# Get token decimals
cast call <TOKEN_ADDRESS> "decimals()" --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Check balance of an address
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)" \
  0xUserAddress \
  --rpc-url $SEPOLIA_RPC_URL | cast --from-wei

# Check allowance
cast call <TOKEN_ADDRESS> \
  "allowance(address,address)" \
  0xOwnerAddress \
  0xSpenderAddress \
  --rpc-url $SEPOLIA_RPC_URL | cast --from-wei

# Get vintage year
cast call <TOKEN_ADDRESS> "getVintageYear()" --rpc-url $SEPOLIA_RPC_URL | cast --to-dec

# Get project registry code
cast call <TOKEN_ADDRESS> "getProjectRegistryCode()" --rpc-url $SEPOLIA_RPC_URL | xargs cast --to-ascii

# Get all metadata entries
cast call <TOKEN_ADDRESS> "getMetadataEntries()" --rpc-url $SEPOLIA_RPC_URL

# Get comprehensive project metadata
cast call <TOKEN_ADDRESS> "getProjectMetadata()" --rpc-url $SEPOLIA_RPC_URL
```

#### Token Transfers

```bash
# Transfer tokens
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  0xRecipient \
  $(cast --to-wei 100) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Approve spender
cast send <TOKEN_ADDRESS> \
  "approve(address,uint256)" \
  0xSpenderAddress \
  $(cast --to-wei 1000) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Transfer from (requires approval)
cast send <TOKEN_ADDRESS> \
  "transferFrom(address,address,uint256)" \
  0xFromAddress \
  0xToAddress \
  $(cast --to-wei 100) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0
```

#### Administrative Functions (Owner Only)

```bash
# Mint new tokens
cast send <TOKEN_ADDRESS> \
  "mint(address,uint256)" \
  0xRecipient \
  $(cast --to-wei 1000) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Burn tokens (owner only)
cast send <TOKEN_ADDRESS> \
  "burn(uint256)" \
  $(cast --to-wei 500) \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Pause transfers
cast send <TOKEN_ADDRESS> \
  "pause()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0

# Unpause transfers
cast send <TOKEN_ADDRESS> \
  "unpause()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --mnemonics "$MNEMONIC" \
  --mnemonic-index 0
```

**Note:** Replace `--mnemonics "$MNEMONIC" --mnemonic-index 0` with `--private-key $PRIVATE_KEY` for any command above.

## Testing

The DPX platform has comprehensive test coverage for all contracts and workflows.

### Run All DPX Tests

```bash
# Run all DPX-related tests
forge test --match-contract FctFactory -vv
forge test --match-contract RedemptionVault -vv

# Run with increased verbosity
forge test --match-contract FctFactory -vvv
forge test --match-contract RedemptionVault -vvv
```

### Run Specific Test Categories

```bash
# FctFactory tests
forge test --match-contract FctFactory --match-test test_Initialization -vv
forge test --match-contract FctFactory --match-test test_CreateProject -vv
forge test --match-contract FctFactory --match-test test_DeployVault -vv
forge test --match-contract FctFactory --match-test test_Upgrade -vv

# RedemptionVault tests
forge test --match-contract RedemptionVault --match-test test_Constructor -vv
forge test --match-contract RedemptionVault --match-test test_ActivateRedemption -vv
forge test --match-contract RedemptionVault --match-test test_Swap -vv
forge test --match-contract RedemptionVault --match-test test_Pause -vv
```

### Run Integration Tests

```bash
# Complete project lifecycle tests
forge test --match-test test_CompleteProjectLifecycle -vvv
forge test --match-test test_MultipleProjectsLifecycle -vvv
forge test --match-test test_Integration_CompleteRedemptionSequence -vvv
```

### Gas Reporting

```bash
forge test --match-contract FctFactory --gas-report
forge test --match-contract RedemptionVault --gas-report
```

### Test Coverage

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage for specific contracts
forge coverage --match-contract FctFactory
forge coverage --match-contract RedemptionVault
```

### Key Test Scenarios

The test suite covers:

**FctFactory**:
- ✅ Initialization and ownership
- ✅ Project creation with validation (owner-only)
- ✅ Automatic token deployment with metadata
- ✅ Vault deployment for projects
- ✅ Query functions (getProject, getAllProjects, getTokenForProject, getVaultForToken)
- ✅ Token-to-project and project-to-vault mappings
- ✅ UUPS upgrades with state preservation
- ✅ Access control (owner-only functions)
- ✅ Edge cases (large project counts, duplicate names, etc.)

**RedemptionVault**:
- ✅ Constructor validation
- ✅ Redemption activation with rate calculation
- ✅ Token-for-USDT swaps
- ✅ Pro-rata distribution
- ✅ Pause/unpause functionality
- ✅ Multiple users redemption
- ✅ Precision handling with different amounts
- ✅ Access control
- ✅ Edge cases (zero supply, insufficient balance, rounding, etc.)

## Upgrading FctFactory

The FctFactory uses the UUPS (Universal Upgradeable Proxy Standard) pattern for upgrades.

### Benefits of Upgradeability

- ✅ Add new features without redeployment
- ✅ Fix bugs while preserving all project data
- ✅ Proxy address remains constant
- ✅ All existing projects, tokens, and vaults remain accessible
- ✅ Gas-efficient (UUPS pattern)

### Storage Safety Rules

**When upgrading, you MUST**:
- ✅ Add new functions
- ✅ Add new state variables at the END (reduce `__gap` accordingly)
- ✅ Modify function logic

**You MUST NOT**:
- ❌ Reorder existing state variables
- ❌ Change types of existing state variables
- ❌ Remove existing state variables

**Warning**: Violating storage layout rules can brick the proxy and lose all data!

### How to Upgrade

```bash
source .env

# Set the proxy address (the address from initial deployment)
PROXY_ADDRESS=0xYourProxyAddress \
  forge script script/UpgradeFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --private-key $PRIVATE_KEY
```

**Using mnemonic:**
```bash
source .env

PROXY_ADDRESS=0xYourProxyAddress \
  forge script script/UpgradeFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0
```

### What Happens During Upgrade

1. New implementation contract is deployed
2. Proxy is updated to point to new implementation
3. All state is preserved (projects, mappings, counters)
4. Users continue using the same proxy address
5. New features become available immediately

### Post-Upgrade Verification

After upgrading, verify that:
```bash
# Check project count (should be unchanged)
cast call <PROXY_ADDRESS> "getProjectCount()" --rpc-url sepolia | cast --to-dec

# Check owner (should be unchanged)
cast call <PROXY_ADDRESS> "owner()" --rpc-url sepolia | xargs cast abi-decode "owner()(address)"

# Test querying existing projects
cast call <PROXY_ADDRESS> "getProject(uint256)(tuple)" 0 --rpc-url sepolia

# Test new functionality
# ...
```

## Contract Source Files

- **FctFactory**: [`src/FctFactory.sol`](../src/FctFactory.sol)
- **FutureCarbonToken**: [`src/FutureCarbonToken.sol`](../src/FutureCarbonToken.sol)
- **RedemptionVault**: [`src/RedemptionVault.sol`](../src/RedemptionVault.sol)
- **Deployment Script**: [`script/DeployFctFactory.s.sol`](../script/DeployFctFactory.s.sol)
- **Upgrade Script**: [`script/UpgradeFctFactory.s.sol`](../script/UpgradeFctFactory.s.sol)
- **Test Suite**: [`test/FctFactory.t.sol`](../test/FctFactory.t.sol), [`test/RedemptionVault.t.sol`](../test/RedemptionVault.t.sol)

## Additional Resources

- [OpenZeppelin Contracts Documentation](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)
- [UUPS Proxy Pattern](https://docs.openzeppelin.com/contracts/api/proxy#UUPSUpgradeable)
- [ERC-20 Token Standard](https://eips.ethereum.org/EIPS/eip-20)
