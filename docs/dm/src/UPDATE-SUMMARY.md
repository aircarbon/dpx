# ARR Phase 1 Documentation Update Summary

**Version:** 1.0 → 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

## Overview of Changes

All ARR Phase 1 documentation has been updated to reflect:

1. **Network Deployment Strategy:**
   - **DPX (Decentralized):** Avalanche C-Chain (43114)
   - **CPX (Centralized):** ACXNET (AvaLabs Custom Layer 1)

2. **Compressed Timeline:**
   - Phase 2 cross-mode liquidity by **end Q2 2026** (June 30, 2026)

3. **Trading Platform Clarification:**
   - CPX/DPX use **Marketplace v2 (MBv2)** - bilateral negotiation platform
   - **Not** the C# matching engine (CLOB/spot market)
   - Matching engine used only for contract-based trading (CET, GNT), not FCT
   - **CPX Context:** CPX is a subsystem of the wider ACX centralized exchange

4. **Token Branding:**
   - Changed from "ACXRWA token" to **"$ACR token"** throughout
   - Added marketplace access utility: Burn $ACR to list projects (anti-spam)

---

## Key Strategic Changes

### 1. Network Deployment Strategy

**Previous Plan:**
- DPX: Ethereum Mainnet, Polygon, Arbitrum (multi-chain)
- CPX: Remain on Polygon PoS
- Timeline: Gradual 12+ month rollout

**Updated Plan:**
- **DPX:** Avalanche C-Chain (Chain ID: 43114) exclusively
  - Mainnet: 43114
  - Testnet: Avalanche Fuji (43113)
- **CPX:** ACXNET (AvaLabs Custom Layer 1) exclusively
  - Migration from Polygon PoS during Phase 1C
- **Timeline:** Aggressive 6-month rollout (Nov 2025 → June 2026)

### 2. Rationale for Network Choices

#### Avalanche C-Chain (DPX)

**Technical Benefits:**
- **Sub-second finality:** <2 seconds vs. Polygon's ~30 seconds
- **High throughput:** 4,500 TPS on C-Chain
- **Low gas costs:** ~$0.42 per swap (competitive with Polygon's ~$0.10)
- **Subnet extensibility:** Future ACXNET integration for cross-mode bridge
- **Robust DeFi ecosystem:** Trader Joe, Aave, Benqi native integrations

**Strategic Benefits:**
- Ava Labs partnership alignment
- Institutional credibility (Ava Labs partnerships with traditional finance)
- Native USDC support (Circle partnership)
- Path to custom subnet for future expansion

### 3. Marketplace v2 (MBv2) Clarification

**What is Marketplace v2:**
- **Bilateral negotiation platform** for project-based FCT trading
- Sellers list specific projects (vintage, registry, methodology)
- Buyers submit trade requests with proposed price/quantity
- Messaging system for counter-offers and negotiation
- Settlement triggered upon mutual acceptance

**What Marketplace v2 is NOT:**
- Not the C# matching engine (CLOB/spot market)
- Not automatic price-time priority matching
- Not for fungible contract trading (CET, GNT)

**CPX/DPX Scope (Phases 1-2):**
- **Uses:** Marketplace v2 (MBv2) bilateral negotiation exclusively
- **Does NOT use:** C# matching engine (CLOB/spot market)
- Future: Phase 3+ may integrate CLOB trading for FCTs if desired

#### ACXNET Custom Layer 1 (CPX)

**Technical Benefits:**
- **Zero gas fees for users:** ACX subsidizes validator rewards
- **Dedicated throughput:** No congestion from public traffic
- **Private mempool:** MEV protection for institutional trades
- **Configurable parameters:** Custom gas schedule, block times
- **Sub-second finality:** <1 second with optimized consensus

**Strategic Benefits:**
- Institutional-grade SLAs (controlled validator set)
- Regulatory compliance (private, permissioned network)
- Cost control (predictable validator costs vs. public network variability)
- Future subnet features (cross-subnet messaging with DPX)

---

## Compressed Timeline

### Original Timeline (v1.0)

- **Phase 1A-D:** Weeks 1-13+ (3+ months)
- **Phase 2 Cross-Mode Bridge:** Q4 2026 or later

### Updated Timeline (v1.1)

**Working Backwards from Q2 2026 Deadline:**

| Phase | Duration | Target Dates | Key Deliverables |
|-------|----------|--------------|------------------|
| **Phase 1A – Foundation** | 4 weeks | Nov 2025 | Avalanche Fuji deployment, ACXNET design |
| **Phase 1B – Development** | 4 weeks | Dec 2025 | Dual-network backend, security audit |
| **Phase 1C – Launches** | 8 weeks | Jan-Feb 2026 | ACXNET migration (W1-4), Avalanche mainnet (W5-8) |
| **Phase 1D – Production** | 8 weeks | Mar-Apr 2026 | Global rollout, Polygon decommissioned |
| **Phase 2 – Bridge** | 8 weeks | May-Jun 2026 | Cross-mode liquidity **GO-LIVE: June 30, 2026** |

**Total Duration:** 32 weeks (8 months from Nov 2025 start)

---

## Documents Updated

### 1. ARR-Phase1-DPX-Refactoring.md

**Major Changes:**
- **Version:** 1.0 → 1.1
- **Executive Summary:** Added network deployment strategy and compressed timeline
- **Section 1.2:** Added ACXNET migration subsection
- **Section 2.2:** Updated ERC-20 minting to specify Avalanche C-Chain with contract addresses
- **Section 2.3:** Updated USDC integration for Avalanche (mainnet contract: 0xB97E...)
- **Section 3.3:** Smart contract deployment strategy split by network (Avalanche vs. ACXNET)
- **Section 5:** Complete timeline rewrite with 4-phase compressed schedule
- **Appendix A:** Gas cost analysis updated for Avalanche C-Chain with comparison table
- **Appendix B:** Feature toggle configuration with network-specific RPC URLs and contract addresses

**Network References Added:**
- Avalanche C-Chain RPC: `https://api.avax.network/ext/bc/C/rpc`
- Avalanche Fuji testnet: Chain ID 43113
- USDC on Avalanche: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`
- USDT on Avalanche: `0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7`

### 2. ARR-Phase1-Executive-Summary.md

**Major Changes:**
- **Strategic Objective:** Added "two optimized blockchain networks" description
- **Deployment Networks:** New subsection with Avalanche + ACXNET details
- **Timeline:** Compressed to 6-month aggressive rollout
- **Implementation Timeline:** Rewritten with Phase 2 as top-level milestone
- **Success Metrics:** Updated gas costs and volume targets

### 3. Whitepaper-ARR-Section.md

**Major Changes:**
- **Overview:** Added network strategy subsection
- **Core Technical Differentiators:** Split CPX (ACXNET) and DPX (Avalanche) with network-specific features
- **DeFi Composability:** Updated to Avalanche ecosystem (Trader Joe, Benqi, Yield Yak)
- **Deployment Strategy:** Complete rewrite with compressed 6-month timeline
- **Gas Cost Breakdown:** Updated for Avalanche C-Chain with detailed comparison table

**Avalanche Benefits Highlighted:**
- Sub-second finality (<2 seconds)
- Low gas costs (~$0.42 typical)
- High throughput (4,500 TPS)
- Subnet architecture for ACXNET integration
- Robust DeFi ecosystem
- Institutional adoption via Ava Labs partnerships

### 4. CPX-vs-DPX-Technical-Comparison.md

**Major Changes:**
- **Version:** 1.0 → 1.1
- **Header:** Added network deployment section
- **All Comparison Tables:** Added "Blockchain Network" rows
  - CPX: ACXNET (Custom L1)
  - DPX: Avalanche C-Chain (43114)
- **Asset Custody:** Updated DeFi composability to Avalanche protocols
- **Payment Management:** Updated USDC contracts for Avalanche
- **Smart Contracts:** Added "Network" column to table
- **Gas Costs:** Complete rewrite with ACXNET vs. Avalanche comparison

**New Comparison Table:**
- ACXNET (CPX): <1 second finality, 10K+ TPS, $0 gas to user
- Avalanche C-Chain (DPX): <2 second finality, 4,500 TPS, ~$0.42 gas
- Polygon (Legacy): ~30 second finality, ~7,000 TPS, ~$0.10 gas

### 5. ARR-Phase1-Index.md

**Major Changes:**
- **Version:** 1.0 → 1.1
- **Document Suite Overview:** Added network deployment and timeline
- **Key Concepts:** Expanded CPX and DPX definitions with network details
- **Implementation Resources:** Added network information to smart contract sections
- **Deployment Phases:** Complete rewrite with 6-month compressed timeline
- **External Dependencies:** Added Avalanche-specific tools and SDKs

**New Dependencies Listed:**
- Avalanche Subnet EVM
- Core Wallet SDK
- Avalanche.js
- Avalanche Network Runner
- Avalanche Warp Messaging
- Trader Joe SDK

---

## Technical Specification Updates

### Smart Contract Deployments

| Contract | Network | Chain ID | Purpose |
|----------|---------|----------|---------|
| **FctTokenFactory.sol** | Avalanche C-Chain | 43114 (mainnet), 43113 (Fuji) | Deploy ERC-20 FCT tokens |
| **SwapBox.sol** | Avalanche C-Chain | 43114 (mainnet), 43113 (Fuji) | Bilateral trade settlement |
| **ACXv2.sol** | ACXNET | TBD (custom subnet) | Centralized ledger for CPX |

### Gas Cost Targets

| Mode | Network | User Cost | ACX Cost | Finality |
|------|---------|-----------|----------|----------|
| **CPX** | ACXNET | **$0.00** | <$0.01/tx | <1 second |
| **DPX** | Avalanche C-Chain | **~$0.42** | $0.00 | <2 seconds |

### Volume Targets (Updated)

| Metric | Original (v1.0) | Updated (v1.1) |
|--------|-----------------|----------------|
| Active DPX Wallets (6 months) | 500+ | 1,000+ |
| USDC Volume (Q1) | $10M+ | $15M+ |
| Phase 2 Launch | Q4 2026 | **End Q2 2026** |

---

## Migration Strategy (CPX: Polygon → ACXNET)

### Phase 1C (Jan-Feb 2026: Weeks 1-4)

**Steps:**
1. Deploy ACXNET subnet with minimum 5 institutional validators
2. Deploy ACXv2 ledger contract to ACXNET
3. Snapshot Polygon CPX state (all balances, assets, trades)
4. Migrate user accounts to ACXNET (parallel operation for 2 weeks)
5. Cutover CPX traffic to ACXNET
6. Monitor 24/7 for 1 week
7. Decommission Polygon infrastructure (May 1, 2026)

**Zero-Downtime Strategy:**
- Parallel operation on both networks during migration
- Gradual traffic shift from Polygon to ACXNET
- Rollback capability maintained for 2 weeks

---

## Phase 2 Cross-Mode Bridge Architecture

### Technical Approach (May-Jun 2026)

**Bridge Contract:**
- Deployed on both Avalanche C-Chain and ACXNET
- Locks FCT ERC-20 on Avalanche → unlocks equivalent on ACXNET ledger
- Burns ledger FCT on ACXNET → mints ERC-20 on Avalanche

**Cross-Chain Messaging:**
- **Option 1:** Avalanche Warp Messaging (preferred - native subnet communication)
- **Option 2:** Axelar (general-purpose cross-chain protocol)

**Unified Order Book:**
- Matching engine matches CPX bids with DPX asks transparently
- Backend routes settlements to appropriate network (ACXNET or Avalanche)
- Market makers incentivized with ACXRWA token rewards

---

## Risk Assessment Updates

### New Risks Introduced

**1. Dual-Network Complexity:**
- **Risk:** Operating on two L1s increases operational complexity
- **Mitigation:** 
  - Unified codebase with network-aware routing
  - Comprehensive monitoring dashboards for both networks
  - Dedicated support team training for dual-network troubleshooting

**2. ACXNET Subnet Launch:**
- **Risk:** Custom L1 deployment may encounter unforeseen technical challenges
- **Mitigation:**
  - Ava Labs partnership for technical support
  - Extensive testnet period (Phase 1A-1B)
  - Parallel Polygon operation during migration

**3. Compressed Timeline:**
- **Risk:** 6-month delivery window leaves limited buffer for delays
- **Mitigation:**
  - Start Phase 1A immediately (November 2025)
  - Parallel development streams where possible
  - Pre-approved contingency: Phase 2 can slip to mid-July 2026 if critical issues arise

### Risks Mitigated

**1. Multi-Chain Fragmentation (v1.0 concern):**
- **Previous:** DPX on multiple chains (Ethereum, Polygon, Arbitrum) would fragment liquidity
- **Resolved:** Single Avalanche C-Chain deployment consolidates liquidity

**2. High Gas Costs (v1.0 concern on Ethereum):**
- **Previous:** Ethereum mainnet gas costs could exceed $50 per swap
- **Resolved:** Avalanche C-Chain offers ~$0.42 per swap

---

## Success Metrics (Updated for v1.1)

### Technical Metrics

| Metric | Original Target (v1.0) | Updated Target (v1.1) |
|--------|------------------------|----------------------|
| Swap success rate | >95% | >95% (unchanged) |
| Settlement latency | <10 minutes | **<2 minutes** (Avalanche finality) |
| Gas cost per swap | <$5 (Polygon) | **<$1** (Avalanche) |
| CPX user gas cost | N/A | **$0** (ACXNET subsidized) |

### Business Metrics

| Metric | Original Target (v1.0) | Updated Target (v1.1) |
|--------|------------------------|----------------------|
| Active DPX wallets (6 months) | 500+ | **1,000+** |
| USDC volume (Q1 2026) | $10M+ | **$15M+** |
| Phase 2 launch date | Q4 2026 | **June 30, 2026** |
| Polygon decommission | N/A | **May 1, 2026** |

### Operational Metrics

| Metric | Target |
|--------|--------|
| ACXNET migration downtime | <1 hour |
| Cross-network monitoring coverage | 100% (both ACXNET + Avalanche) |
| Support team dual-network certification | 100% by Phase 1C |
| Bridge deployment success | Phase 2 go-live June 30, 2026 |

---

## Next Steps

### Immediate Actions (November 2025)

1. **Ava Labs Partnership:**
   - Formalize technical partnership agreement
   - Access Avalanche Subnet EVM documentation and tooling
   - Schedule ACXNET subnet design workshop with Ava Labs engineers

2. **Smart Contract Development:**
   - Begin SwapBox + FctTokenFactory development for Avalanche
   - Set up Avalanche Fuji testnet environment
   - Configure Hardhat for Avalanche fork testing

3. **Security Audit RFP:**
   - Engage Ava Labs-recommended auditors (Halborn, Trail of Bits)
   - Schedule audit for December 2025 (Phase 1B)
   - Set up bug bounty program ($50K rewards)

4. **Backend Refactoring:**
   - Implement network-aware routing logic
   - Add Avalanche RPC integration
   - Design ACXNET state migration strategy

5. **Team Staffing:**
   - Hire/train Avalanche specialist developers
   - Onboard ACXNET subnet operations team
   - Expand support team for dual-network coverage

---

## Stakeholder Communication

### Internal Teams

- **Engineering:** Full ARR v1.1 documentation suite
- **Product:** Executive Summary + Whitepaper Section
- **Operations:** Deployment checklist + monitoring setup
- **Support:** Dual-network troubleshooting guide (TBD)

### External Partners

- **Ava Labs:** Technical partnership roadmap
- **Institutional Validators:** ACXNET participation agreements
- **Liquidity Providers:** Phase 2 market maker incentive program
- **Auditors:** Smart contract audit scope (Avalanche + ACXNET)

---

## Conclusion

The updated ARR Phase 1 documentation reflects a **strategic pivot** to:

1. **Avalanche C-Chain** for DPX (decentralized, DeFi-native operations)
2. **ACXNET Custom L1** for CPX (institutional, subsidized-gas operations)
3. **Aggressive 6-month timeline** delivering Phase 2 cross-mode liquidity by **end Q2 2026**

This approach optimizes for:
- **Technical performance:** Sub-second finality on both networks
- **Cost efficiency:** <$1 gas (DPX), $0 gas (CPX)
- **Strategic alignment:** Ava Labs partnership, subnet extensibility
- **Market positioning:** First carbon exchange spanning custodial (ACXNET) and non-custodial (Avalanche) with unified liquidity

**All documentation is now consistent with this updated strategy and ready for stakeholder review.**

---

## Additional Clarifications (v1.1)

### Trading Platform Architecture

**Two Distinct Trading Venues in ACX Platform:**

1. **Marketplace v2 (MBv2)** - Bilateral Negotiation
   - **Purpose:** Project-based FCT trading
   - **Mechanism:** Sellers list projects, buyers submit trade requests, negotiation via counter-offers
   - **Settlement:** Triggered by seller acceptance (CPX: `transferOrTrade`, DPX: SwapBox)
   - **Used by:** CPX/DPX (Phases 1-2)
   - **Code:** `packages/wa-api/services/mb2/mb2.service.ts`

2. **Spot Market (CLOB)** - Matching Engine
   - **Purpose:** Contract-based trading (CET, GNT fungible tokens)
   - **Mechanism:** Price-time priority automatic matching
   - **Settlement:** Instant atomic swaps via matching engine
   - **Used by:** Not used for CPX/DPX FCT trading
   - **Code:** `apps/OrderMatcher/` (C# .NET 6)

**Key Insight:** CPX and DPX are **bilateral negotiation platforms** (Marketplace v2), not order book exchanges. This design choice provides:
- Better price discovery for unique carbon projects
- Transparent seller-buyer communication
- Flexibility for bespoke terms (delivery schedules, quality criteria)
- Natural fit for project-based assets (each FCT vintage is unique)

### New Document Added

**SwapBox-Contract.md** (~10 pages)
- Complete production-ready Solidity implementation
- Supports **multiple concurrent swaps** with unique IDs
- TypeScript integration examples
- Gas cost analysis for Avalanche C-Chain
- Security audit checklist
- Deployment procedures

**Key Features:**
- Each swap has buyer, seller, buyerAsset (USDC), sellerAsset (FCT), amounts
- Once both deposit, each side withdraws the inverse asset
- Contract enforces atomicity (both deposit before either withdraws)
- 24-hour expiry with automatic refunds
- ~400K gas per swap (~$0.42 on Avalanche C-Chain)

---

**Document Status:** **Complete**  
**Review Status:** Ready for C-level approval

**Documents in Suite:**
1. ARR-Phase1-Executive-Summary.md (5 pages)
2. ARR-Phase1-DPX-Refactoring.md (25 pages)
3. CPX-vs-DPX-Technical-Comparison.md (20 pages)
4. Whitepaper-ARR-Section.md (15 pages)
5. **SwapBox-Contract.md (10 pages)** NEW
6. ARR-Phase1-Index.md (Navigation guide)
7. UPDATE-SUMMARY.md (This document)

