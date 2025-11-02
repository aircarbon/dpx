# DPX Project - Smart Contracts Repository

This repository contains smart contracts for two main systems:

1. **ACR Governance Token & DAO** - An upgradeable ERC-20 governance token with on-chain voting capabilities
2. **DPX Platform** - A decentralized platform for tokenizing future carbon credits

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

## Project Overview

### ACR Governance System

The ACR system provides a complete on-chain governance solution with:

- **ACR Token (ACT.sol)**: Upgradeable ERC-20 token with voting capabilities, built using OpenZeppelin's ERC20Votes standard
- **ACTGovernor**: OpenZeppelin Governor contract for DAO governance integration with Tally
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

- **RegistryFactory**: Central factory for deploying and managing project tokens and vaults (upgradeable)
- **FutureCarbonToken**: ERC-20 tokens representing future carbon credits for specific projects
- **RedemptionVault**: Manages USDT redemption after carbon credit sales

**How it Works**:
1. Project developers propose carbon credit projects
2. Approved projects receive a FutureCarbonToken deployment
3. Investors purchase tokens representing future carbon credits
4. After credits are issued and sold, token holders redeem for USDT pro-rata
5. RedemptionVault manages the redemption process

**Documentation**: [DPX Platform Documentation](docs/DPX_SC_ARCHITECTURE.md)

## Technology Stack

- **Foundry**: Smart contract development framework
- **OpenZeppelin Contracts**: Battle-tested contract libraries
- **Solidity**: Smart contract programming language
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
forge test --match-contract ACTTest -vv

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

### Contract Reference

#### ACR Governance Contracts
- `src/ACT.sol` - Upgradeable ERC-20 governance token
- `src/ACTGovernor.sol` - OpenZeppelin Governor for DAO

#### DPX Platform Contracts
- `src/RegistryFactory.sol` - Factory for project tokens and vaults
- `src/FutureCarbonToken.sol` - ERC-20 tokens for future carbon credits
- `src/RedemptionVault.sol` - USDT redemption management

### Deployment Scripts

#### ACR Governance Scripts
- `script/Deploy.s.sol` - Deploy ACR token
- `script/Upgrade.s.sol` - Upgrade ACR token implementation
- `script/ACTGovernor.s.sol` - Deploy Governor contract

#### DPX Platform Scripts
- `script/DeployDPX.s.sol` - Deploy DPX platform (RegistryFactory)
- `script/UpgradeDPX.s.sol` - Upgrade DPX platform (RegistryFactory)