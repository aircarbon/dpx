# DPX Platform - Carbon Credit Tokenization

Complete documentation for the DPX (Decentralized Project Exchange) platform smart contracts.

## Table of Contents

- [Overview](#overview)
- [Architecture Components](#architecture-components)
- [Deployment Guide](#deployment-guide)
- [Testing](#testing)
- [Upgrading FctFactory](#upgrading-fctfactory)
- [Interacting with Contracts](#interacting-with-contracts)
- [Complete Workflow Example](#complete-workflow-example)

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
PRIVATE_KEY=your_private_key_here
# OR
MNEMONIC="your twelve word seed phrase"

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key

# Contract verification (optional)
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

#### Local Deployment (Anvil)

```bash
# Terminal 1: Start local node
anvil

# Terminal 2: Deploy
forge script script/DeployFctFactory.s.sol --rpc-url anvil --broadcast
```

#### Testnet Deployment (Sepolia)

**Deploy with deployer as owner:**
```bash
source .env

forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --private-key $PRIVATE_KEY
```

**Deploy with deployer as owner (using mnemonics):**
```bash
source .env && \

DERIVED_KEY=$(cast wallet private-key "$MNEMONIC" --mnemonic-index 0) && \
forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --private-key $DERIVED_KEY
```

**Deploy with custom owner (recommended for production):**
```bash
source .env

OWNER_ADDRESS=0xYourMultisigAddress \
  forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --private-key $PRIVATE_KEY
```

**With contract verification:**
```bash
source .env

OWNER_ADDRESS=0xYourMultisigAddress \
  forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --private-key $PRIVATE_KEY
```

**Using mnemonic:**
```bash
source .env

OWNER_ADDRESS=0xYourMultisigAddress \
  forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0
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
     --private-key $PRIVATE_KEY
   ```
3. **Test basic functionality**:
   - Propose a test project
   - Approve and verify token deployment
   - Deploy vault and test redemption flow

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

## Interacting with Contracts

Use Foundry's `cast` tool to interact with deployed contracts.

### Setup

```bash
source .env
export FACTORY_ADDRESS=0xYourProxyAddress
```

### Registry Query Functions

#### Get Project Count

```bash
cast call $FACTORY_ADDRESS "getProjectCount()" --rpc-url sepolia | cast --to-dec
```

#### Get Next Project ID

```bash
cast call $FACTORY_ADDRESS "getNextProjectId()" --rpc-url sepolia | cast --to-dec
```

#### Get Project Details

```bash
# Get project by ID
cast call $FACTORY_ADDRESS \
  "getProject(uint256)" \
  0 \
  --rpc-url sepolia

# Returns: (projectId, name, symbol, initialSupply, tokenAddress, vaultAddress, createdAt, vintageYear, projectRegistryCode)
```

#### Get All Projects

```bash
cast call $FACTORY_ADDRESS "getAllProjects()" --rpc-url sepolia
```


#### Get Token for Project

```bash
cast call $FACTORY_ADDRESS \
  "getTokenForProject(uint256)" \
  0 \
  --rpc-url sepolia | xargs cast abi-decode "getTokenForProject(uint256)(address)"
```

#### Get Vault for Token

```bash
cast call $FACTORY_ADDRESS \
  "getVaultForToken(address)" \
  0xTokenAddress \
  --rpc-url sepolia | xargs cast abi-decode "getVaultForToken(address)(address)"
```

### Project Management Functions

#### Create a Project (Owner Only)

```bash
# Create project with metadata (requires constructing metadata array)
# For simplicity, this example uses empty metadata
cast send $FACTORY_ADDRESS \
  "createProject(string,string,uint256,uint256,string,(string,string)[])" \
  "Future Carbon Credit - Alpha" \
  "FCC-ALPHA" \
  $(cast --to-wei 1000000) \
  2025 \
  "VCS-1234-2025" \
  "[]" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Note: This automatically deploys the FutureCarbonToken with the provided metadata
# Returns: (projectId, tokenAddress)
```

#### Deploy Vault (Owner Only)

```bash
# Deploy RedemptionVault for a project
# Requires: USDT token address
cast send $FACTORY_ADDRESS \
  "deployVault(uint256,address)" \
  0 \
  0xUSDTAddress \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

### Redemption Vault Interactions

#### Activate Redemption (Owner Only)

```bash
# First, deposit USDT to the vault
cast send <USDT_ADDRESS> \
  "transfer(address,uint256)" \
  <VAULT_ADDRESS> \
  1000000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Then activate redemption (calculates rate)
cast send <VAULT_ADDRESS> \
  "activateRedemption()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Check Redemption Status

```bash
# Check if redemption is active
cast call <VAULT_ADDRESS> \
  "isRedemptionActive()" \
  --rpc-url sepolia | xargs cast abi-decode "isRedemptionActive()(bool)"

# Get redemption rate per token
cast call <VAULT_ADDRESS> \
  "getRedemptionRate()" \
  --rpc-url sepolia | cast --to-dec

# Get available USDT in vault
cast call <VAULT_ADDRESS> \
  "getAvailableStablecoin()" \
  --rpc-url sepolia | cast --to-dec

# Get total redeemed
cast call <VAULT_ADDRESS> \
  "totalRedeemed()" \
  --rpc-url sepolia | cast --to-dec
```

#### Redeem Tokens for USDT (Token Holders)

```bash
# First, approve vault to burn your tokens
cast send <TOKEN_ADDRESS> \
  "approve(address,uint256)" \
  <VAULT_ADDRESS> \
  $(cast --to-wei 1000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Then swap tokens for USDT
cast send <VAULT_ADDRESS> \
  "swap(uint256)" \
  $(cast --to-wei 1000) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

#### Pause/Unpause Vault (Owner Only)

```bash
# Pause redemptions
cast send <VAULT_ADDRESS> "pause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Unpause redemptions
cast send <VAULT_ADDRESS> "unpause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

### FutureCarbonToken Interactions

FutureCarbonToken is a standard ERC-20 with additional features:

```bash
# Get token info
cast call <TOKEN_ADDRESS> "name()" --rpc-url sepolia | xargs cast --to-ascii
cast call <TOKEN_ADDRESS> "symbol()" --rpc-url sepolia | xargs cast --to-ascii
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url sepolia | cast --from-wei

# Check balance
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)" \
  0xUserAddress \
  --rpc-url sepolia | cast --from-wei

# Transfer tokens
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  0xRecipient \
  $(cast --to-wei 100) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Burn tokens (owner only)
cast send <TOKEN_ADDRESS> \
  "burn(uint256)" \
  $(cast --to-wei 500) \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Pause/unpause transfers (owner only)
cast send <TOKEN_ADDRESS> "pause()" --rpc-url sepolia --private-key $PRIVATE_KEY
cast send <TOKEN_ADDRESS> "unpause()" --rpc-url sepolia --private-key $PRIVATE_KEY
```

## Complete Workflow Example

Here's a complete end-to-end workflow for the DPX platform:

### 1. Deploy Platform

```bash
source .env
OWNER_ADDRESS=0xMultisigAddress \
  forge script script/DeployFctFactory.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --private-key $PRIVATE_KEY

# Save the PROXY_ADDRESS from output
export FACTORY_ADDRESS=0xProxyAddress
```

### 2. Owner Creates Project

```bash
# Owner creates a carbon credit project (automatically deploys token)
cast send $FACTORY_ADDRESS \
  "createProject(string,string,uint256,uint256,string,(string,string)[])" \
  "Rainforest Preservation 2025" \
  "RFP2025" \
  $(cast --to-wei 5000000) \
  2025 \
  "VCS-RFP-2025" \
  "[]" \
  --rpc-url sepolia \
  --private-key $OWNER_KEY

# Get deployed token address
TOKEN_ADDRESS=$(cast call $FACTORY_ADDRESS \
  "getTokenForProject(uint256)" \
  0 \
  --rpc-url sepolia | xargs cast abi-decode "getTokenForProject(uint256)(address)")

echo "Token deployed at: $TOKEN_ADDRESS"

# Check project details
cast call $FACTORY_ADDRESS "getProject(uint256)" 0 --rpc-url sepolia
```

### 3. Token Trading Phase

```bash
# Owner transfers tokens to investors
cast send $TOKEN_ADDRESS \
  "transfer(address,uint256)" \
  0xInvestor1 \
  $(cast --to-wei 100000) \
  --rpc-url sepolia \
  --private-key $OWNER_KEY

# Investors can trade tokens on secondary markets
# ...
```

### 4. Project Completes & Vault Deployment

```bash
# Carbon credits sold, ready for redemption
# Owner deploys redemption vault
cast send $FACTORY_ADDRESS \
  "deployVault(uint256,address)" \
  0 \
  0xUSDTAddress \
  --rpc-url sepolia \
  --private-key $OWNER_KEY

# Get vault address
VAULT_ADDRESS=$(cast call $FACTORY_ADDRESS \
  "getVaultForToken(address)" \
  $TOKEN_ADDRESS \
  --rpc-url sepolia | xargs cast abi-decode "getVaultForToken(address)(address)")

echo "Vault deployed at: $VAULT_ADDRESS"
```

### 5. Deposit USDT and Activate Redemption

```bash
# Owner deposits USDT from carbon credit sales
cast send 0xUSDTAddress \
  "transfer(address,uint256)" \
  $VAULT_ADDRESS \
  500000000000 \
  --rpc-url sepolia \
  --private-key $OWNER_KEY

# Activate redemption (calculates rate)
cast send $VAULT_ADDRESS \
  "activateRedemption()" \
  --rpc-url sepolia \
  --private-key $OWNER_KEY

# Check redemption rate
cast call $VAULT_ADDRESS "getRedemptionRate()" --rpc-url sepolia | cast --to-dec
```

### 6. Token Holders Redeem

```bash
# Investor approves vault to burn tokens
cast send $TOKEN_ADDRESS \
  "approve(address,uint256)" \
  $VAULT_ADDRESS \
  $(cast --to-wei 100000) \
  --rpc-url sepolia \
  --private-key $INVESTOR_KEY

# Investor redeems tokens for USDT
cast send $VAULT_ADDRESS \
  "swap(uint256)" \
  $(cast --to-wei 100000) \
  --rpc-url sepolia \
  --private-key $INVESTOR_KEY

# Check USDT balance
cast call 0xUSDTAddress \
  "balanceOf(address)" \
  0xInvestorAddress \
  --rpc-url sepolia | cast --to-dec
```

### 7. Monitor Platform

```bash
# Check total projects
cast call $FACTORY_ADDRESS "getProjectCount()" --rpc-url sepolia | cast --to-dec

# Get all projects
cast call $FACTORY_ADDRESS "getAllProjects()" --rpc-url sepolia

# Check vault stats
cast call $VAULT_ADDRESS "totalRedeemed()" --rpc-url sepolia | cast --to-dec
cast call $VAULT_ADDRESS "getAvailableStablecoin()" --rpc-url sepolia | cast --to-dec
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
