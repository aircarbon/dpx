# Introduction

Welcome to the **DPX Project** documentation!

This repository contains smart contracts for two main systems:

## ACR Governance Token & DAO

An upgradeable ERC-20 governance token with on-chain voting capabilities, deployed on Avalanche C-chain.

**Key Features:**
- Full ERC-20 compliance with voting support (ERC20Votes)
- Burnable, mintable, and pausable tokens
- Gasless approvals via EIP-2612 permit
- UUPS upgradeable proxy pattern
- Integrated with Tally for DAO governance

**Deployed on Avalanche C-chain:**
- Token Address: `0xc0AcD13BD4E568aD96D758DEd3C7150f37e5B016`
- Token Symbol: ACR
- Total Supply: 1,000,000,000 ACR

## DPX Platform

A decentralized platform for tokenizing future carbon credits, enabling project developers to raise capital for carbon credit projects.

**How it Works:**
1. Project developers propose carbon credit projects
2. Approved projects receive a FutureCarbonToken deployment
3. Investors purchase tokens representing future carbon credits
4. After credits are issued and sold, token holders redeem for USDT
5. RedemptionVault manages the redemption process

## Technology Stack

- **Foundry** - Smart contract development framework
- **OpenZeppelin Contracts** - Battle-tested contract libraries
- **Solidity** - Smart contract programming language
- **Safe Global** - Multi-signature wallet infrastructure
- **Tally** - DAO governance interface

## Quick Start

```bash
# Install dependencies
forge install

# Run tests
forge test

# Build contracts
forge build
```

## Documentation

- [Architecture Refactoring Roadmap](./architecture-roadmap) - Complete technical documentation for CPX to DPX transformation

<!-- TODO: Add these documentation files
- [ACR Governance Documentation](./acr-governance/overview.md)
- [DPX Platform Documentation](./dpx-platform/overview.md)
- [Testing Guide](./guides/testing.md)
-->
