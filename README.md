# DPX Project - Smart Contracts Repository

This repository contains smart contracts for three main systems:

1. **ACR Governance Token & DAO** - An upgradeable ERC-20 governance token with on-chain voting capabilities
2. **DPX Platform** - A decentralized platform for tokenizing future carbon credits
3. **SwapBox** - Atomic, non-custodial ERC20 token swaps powered by AirSwap's SwapERC20 protocol

## Production Deployments

### ACR Governance Token (Avalanche C-chain)

- **Token Name**: ACX RWA
- **Token Symbol**: ACR
- **Token Address**: `0xc0AcD13BD4E568aD96D758DEd3C7150f37e5B016`
- **Total Supply**: 1,000,000,000 ACR (1 billion tokens)
- **Treasury Safe Wallet**: `0x46917d5E1fA5D8A55d4FD4Bccf73498571FB1d60`
- **Upgradeability**: UUPS proxy pattern

The token is controlled by a multisig Treasury Safe wallet, which currently holds the entire supply of 1 billion tokens.

### DPX Project
Not deployed for now.

### SwapBox
Not deployed for now.

## Project Overview

### ACR Governance System

The ACR system provides a complete on-chain governance solution with:

- **ACR Token**: Upgradeable ERC-20 token with voting capabilities, built using OpenZeppelin's ERC20Votes standard
- **ACRGovernor**: OpenZeppelin Governor contract for DAO governance integration with Tally
- **Treasury Management**: Multi-signature wallet integration via Safe Global
- **Vesting Support**: Integration with Hedgey Finance for team vesting schedules

**Key Features**:
- Full ERC-20 compliance with voting/governance support (ERC20Votes)
- Burnable, mintable, and pausable tokens
- Gasless approvals via EIP-2612 permit
- Historical balance tracking via checkpoints
- UUPS upgradeable proxy pattern

**Documentation**: [ACR Governance Documentation](docs/ACR_OVERVIEW.md)

### DPX Platform

The DPX (Decentralized Project Exchange) platform enables tokenization of future carbon credits:

- **FctFactory**: Central factory for deploying and managing project tokens and vaults (upgradeable)
- **FutureCarbonToken**: ERC-20 tokens representing future carbon credits for specific projects
- **RedemptionVault**: Manages USDT redemption after carbon credit sales

**How it Works**:
1. Project developers propose carbon credit projects
2. Approved projects receive a FutureCarbonToken deployment
3. Investors purchase tokens representing future carbon credits
4. After credits are issued and sold, token holders redeem for USDT pro-rata
5. RedemptionVault manages the redemption process

**Documentation**: [DPX Platform Documentation](docs/DPX_SC_ARCHITECTURE.md)

### SwapBox (Atomic Token Swaps)

SwapBox enables atomic ERC20 token swaps using off-chain signed orders. Built on **AirSwap's SwapERC20 v5.0.0**, it provides a trustless, peer-to-peer token exchange mechanism.

**Key Features**:
- Atomic swaps with EIP-712 signed orders
- Protocol fee collection for platform revenue
- Gas-optimized swap methods
- Nonce management for replay protection
- Non-upgradeable (immutable once deployed)

**Deployment**: SwapBox is deployed as a separate instance to faciliotate atomic swap of ERC-20 tokens and collect protocol fees from token swaps on the platform.

**Documentation**: [SwapBox Integration Guide](docs/team/SWAPBOX_OVERVIEW.md) - Complete deployment and interaction guide

## Technology Stack

- **Foundry**: Smart contract development framework
- **OpenZeppelin Contracts**: Battle-tested contract libraries
- **Solidity**: Smart contract programming language
- **AirSwap**: Atomic token swap protocol (SwapERC20 v5.0.0)
- **Safe Global**: Multi-signature wallet infrastructure
- **Tally**: DAO governance interface
- **Hedgey Finance**: Vesting schedule management

## Quick Start

### 1. Install Dependencies

```bash
forge install
```

### 2. Configure Environment Variables

Copy the example environment file and add your configuration:

```bash
cp .env.example .env
```

Edit `.env` and add:
- `PRIVATE_KEY` or `MNEMONIC`: Your wallet credentials
- `SEPOLIA_RPC_URL`, `MAINNET_RPC_URL`: RPC endpoints (e.g., Alchemy, Infura)
- `ETHERSCAN_API_KEY`: For contract verification (optional)
- Governor-specific variables (see ACR documentation)

**⚠️ IMPORTANT**: Never commit your `.env` file! It's already in `.gitignore`.

### 3. Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test contract
forge test --match-contract ACRTest -vv

# Run with gas reporting
forge test --gas-report
```

### 4. Build Contracts

```bash
forge build
```

## Documentation

### Detailed Guides

- **[ACR Governance System](docs/ACR_OVERVIEW.md)** - Complete guide for ACR token, Governor contract, deployment, and DAO setup
- **[ACR Deployment Workflow](docs/ACR_DEPLOYMENT.md)** - Step-by-step workflow for production token launch with multisig and DAO
- **[DPX Platform](docs/DPX_SC_ARCHITECTURE.md)** - Architecture, deployment, and testing guide for the carbon credit tokenization platform
- **[SwapBox Integration](docs/team/SWAPBOX_OVERVIEW.md)** - Deployment and interaction guide for atomic token swaps using AirSwap SwapERC20

### Contract Reference

#### ACR Governance Contracts
- `src/ACR.sol` - Upgradeable ERC-20 governance token
- `src/ACRGovernor.sol` - OpenZeppelin Governor for DAO

#### DPX Platform Contracts
- `src/FctFactory.sol` - Factory for project tokens and vaults
- `src/FutureCarbonToken.sol` - ERC-20 tokens for future carbon credits
- `src/RedemptionVault.sol` - USDT redemption management

#### SwapBox Contracts
- `lib/airswap-protocols/source/swap-erc20/contracts/SwapERC20.sol` - AirSwap atomic swap contract (v5.0.0)
- `src/interfaces/ISwapERC20.sol` - Extended interface for CLI interactions and testing

### Deployment Scripts

#### ACR Governance Scripts
- `script/Deploy.s.sol` - Deploy ACR token
- `script/Upgrade.s.sol` - Upgrade ACR token implementation
- `script/ACRGovernor.s.sol` - Deploy Governor contract

#### DPX Platform Scripts
- `script/DeployFctFactory.s.sol` - Deploy FctFactory
- `script/UpgradeFctFactory.s.sol` - Upgrade FctFactory

#### SwapBox Scripts
- `script/DeploySwapERC20.s.sol` - Deploy SwapBox (AirSwap SwapERC20) instance