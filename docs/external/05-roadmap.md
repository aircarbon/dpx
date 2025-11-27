# Roadmap

## Overview

DPX follows a phased development approach targeting full cross-mode liquidity and staking functionality by end of Q2 2026 (June 30, 2026). The roadmap is structured to deliver incremental value while maintaining security and stability at each stage.

**Current Status:** Phase 1 (In Progress)

---

## Phase 1: Foundation & Launch

Phase 1 spans November 2025 through April 2026 and is divided into four sub-phases, progressively building from infrastructure setup to production-scale operations.

### Phase 1A – Foundation (November 2025)

**Duration:** 4 weeks

Phase 1A establishes the core infrastructure for both ACX and DPX platforms.

**Infrastructure & Network Design (ACX):**
- Design ACXNET subnet configuration
- Implement SIWE (Sign-In with Ethereum) authentication
- Begin security audit engagement with established firms

**Smart Contract Deployment – Avalanche Mainnet (DPX):**
- Deploy ACR token (1 billion supply, ERC-20)
- Set up Safe multisig treasury controls for ACR
- Deploy Hedgey vesting contracts for team and investor allocations

**Smart Contract Deployment – Fuji Testnet (DPX):**
- Deploy FctFactory for project proposals, approvals, and FCT minting
- Deploy SwapBox for atomic FCT ↔ stablecoin swaps (zero fees initially)
- Deploy RedemptionVault template

### Phase 1B – Development Sprint (December 2025)

**Duration:** 4 weeks

Phase 1B focuses on platform integration and the beginning of DPX operations.

**Platform Development (ACX):**
- Complete WalletConnect integration for Avalanche
- Dual-network backend refactoring to support both ACXNET and Avalanche C-Chain
- Load testing infrastructure (targeting 1,000+ concurrent orders)

**DPX Operations Launch:**
- Build FctFactory and SwapBox user interfaces
- Begin onboarding first FCT projects
- Complete external security audit for FctFactory, FutureCarbonToken, and RedemptionVault contracts

### Phase 1C – Network Launches (January–February 2026)

**Duration:** 8 weeks

Phase 1C marks the mainnet deployment of both ACXNET and DPX production infrastructure.

**Network Deployment (ACX):**
- **ACXNET Launch:** Deploy STMv2 contracts, migrate ACX/CPX from Polygon (hard cutover)
- Onboard handpicked crypto-native projects and buyers

**Smart Contract Deployment – Avalanche Mainnet (DPX):**
- Deploy FctFactory and SwapBox to Avalanche mainnet
- Approve and onboard initial FCT projects
- Enable zero-fee atomic swaps for early adopters

### Phase 1D – Production Scale (March–April 2026)

**Duration:** 8 weeks

Phase 1D expands the ecosystem and introduces staking and fee mechanisms.

**Ecosystem Expansion (ACX):**
- Expand DPX to additional crypto-native participants
- ACX/CPX fully operational on ACXNET
- Investigate DEX liquidity pool appetite and potential integrations

**Staking & Fee Collection Launch (DPX):**
- Deploy ACR staking contract (Curve-style design with multi-token fee support)
- Enable SwapBox protocol fees (directed to staking contract)
- Implement fee distribution to ACR stakers (supporting USDT, USDC, DAI)
- Optional fee discount for ACR stakers

---

## Phase 2: Cross-Mode Bridge & DAO Governance

**Duration:** May–June 2026 (8 weeks)

Phase 2 delivers the advanced infrastructure for unified liquidity and transitions platform governance to decentralized control.

### Advanced Infrastructure (ACX)

**Cross-Chain Bridge:**
- Deploy ACXNET ↔ Avalanche C-Chain bridge for FCT token wrapping
- Enable seamless asset transfers between CPX (custodial) and DPX (non-custodial) platforms

**Unified Order Book:**
- Implement cross-platform order matching (CPX bids can match DPX asks)
- Create a single unified market across both access modes

**Market Maker Incentives:**
- Launch $ACR reward programs to incentivize market making and liquidity provision

### DAO Transition (DPX)

**Governance Transfer:**
- Transfer ownership of ACR token, treasury, and DPX contracts from Safe multisig to Tally DAO
- Transition occurs after sufficient ACR token vesting to ensure broad governance participation

**Enhanced ACR Integration:**
- Projects must stake ACR tokens to submit proposals to the FctFactory
- A portion of SwapBox fees allocated to ACR buyback and burn mechanism

**DAO Voting Rights:**
ACR token holders gain governance authority over key protocol parameters:
- Project approvals (which projects can be tokenized)
- Fee parameters (SwapBox fee rates)
- Required ACR stake for project proposals
- Fee allocation between stakers and buyback/burn

---

## Roadmap Summary

| Phase | Timeline | Key Deliverables |
|-------|----------|------------------|
| **1A – Foundation** | Nov 2025 | ACR token deployment, testnet contracts, security audit start |
| **1B – Development Sprint** | Dec 2025 | UI development, first project onboarding, audit completion |
| **1C – Network Launches** | Jan–Feb 2026 | ACXNET launch, DPX mainnet deployment, initial projects live |
| **1D – Production Scale** | Mar–Apr 2026 | ACR staking, fee collection, ecosystem expansion |
| **2 – Bridge & DAO** | May–Jun 2026 | Cross-chain bridge, unified order book, DAO governance |

---

## Development Principles

**Security First:**
Each phase includes security validation before proceeding. External audits, multisig controls, and staged rollouts ensure that user assets remain protected throughout the development process.

**Incremental Value:**
The phased approach delivers usable functionality at each stage rather than waiting for complete feature parity. Users can begin trading on DPX during Phase 1C while more advanced features (staking, bridge, DAO) are developed.

**Flexibility:**
While the roadmap provides target timelines, development priorities may adjust based on market conditions, security findings, or community feedback. The phase structure allows for scope adjustments without disrupting the overall trajectory.

---

*Previous: [04 - Integration Strategy](./04-integration-strategy.md)*
*Next: [06 - $ACR Token](./06-acr-token.md)*
