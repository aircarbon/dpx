# DPX Smart Contract Architecture

## Overview

The DPX (Decentralized Project Exchange) system enables tokenization of future carbon credits. Project developers can mint tokens representing future carbon credits, which investors can purchase. Once the project completes and real carbon credits are issued and sold, token holders can redeem their tokens for USDT proportional to the sale proceeds.

## Architecture Components

### 1. RegistryFactory (Upgradeable via Proxy)

**Purpose**: Central factory contract for deploying and managing all project tokens and redemption vaults.

**Upgradeability**: UUPS proxy pattern - Implementation can be upgraded to add new features

**Key Responsibilities**:
- Accept project proposals from developers
- Deploy `FutureCarbonToken` contracts when projects are approved
- Deploy corresponding `RedemptionVault` contracts (separately, when needed)
- Maintain registry mapping: `token address -> vault address`
- Track project lifecycle status (Pending, Approved, Denied, Completed)
- Provide discovery functions for querying all projects

**Extends OpenZeppelin Contracts**:
- `Initializable` - Initialization pattern for upgradeable contracts
- `UUPSUpgradeable` - Upgradeable proxy pattern
- `OwnableUpgradeable` - Access control

**Custom Business Logic**:
- Project proposal management (propose, approve, deny)
- Token and vault deployment
- Project registry and discovery
- Lifecycle status tracking

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

**Extends OpenZeppelin Contracts**:
- `ERC20` - Standard ERC-20 implementation
- `ERC20Permit` - Gasless approvals via signatures (EIP-2612)
- `ERC20Burnable` - Burn functionality
- `ERC20Pausable` - Pause/unpause transfers
- `Ownable` - Access control

**Custom Business Logic**:
- Minimal - primarily wraps OpenZeppelin functionality with access control
- Custom `mint()` function (owner-only wrapper around `_mint`)
- Custom `pause()`/`unpause()` functions (owner-only wrappers)
- Required `_update()` override for multiple inheritance

---

### 3. RedemptionVault (Non-Upgradeable)

**Purpose**: Holds USDT proceeds from carbon credit sales and facilitates token redemption.

**Upgradeability**: Not upgradeable - Each vault is specific to one project with immutable redemption logic

**Key Responsibilities**:
- Store USDT from carbon credit sales
- Calculate pro-rata redemption rate: `redemptionRatePerToken = totalUSDT / futureTokenTotalSupply`
- Execute token-for-USDT swaps
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
