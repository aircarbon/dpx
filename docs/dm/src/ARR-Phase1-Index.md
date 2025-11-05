# Architecture Refactoring Roadmap – Phase 1 Documentation Index

**CPX to DPX Transformation – Complete Technical Specification**

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

## Document Suite Overview

This documentation suite provides comprehensive technical specification for transforming AirCarbon's **Carbon Project Exchange (CPX)** into a dual-mode platform supporting both centralized and decentralized operations across **two optimized blockchain networks**.

**Network Deployment:**
- **DPX:** Avalanche C-Chain (Chain ID: 43114) for decentralized, permissionless DeFi operations
- **CPX:** ACXNET (AvaLabs Custom Layer 1) for institutional-grade, subsidized-gas centralized exchange

**Timeline:** 6-month rollout targeting Phase 2 cross-mode liquidity by end Q2 2026 (June 30, 2026).

**Total Pages:** ~100 pages of technical detail  
**Audience:** Engineering teams, technical leadership, security auditors, whitepaper contributors, Ava Labs partnership teams

**Documents in Suite:**
1. **Whitepaper-ARR-Phase1.md (20 pages) - For whitepaper inclusion** **COMBINED**
2. ARR-Phase1-DPX-Refactoring.md (30 pages) - Complete technical spec
3. SwapBox-Contract.md (10 pages) - Production Solidity implementation
4. CPX-vs-DPX-Technical-Comparison.md (20 pages) - Technical comparison
5. QUICK-REFERENCE.md (1 page) - Developer cheat sheet
6. ARR-Phase1-Index.md (This document)
7. UPDATE-SUMMARY.md - Changelog v1.0 → v1.1
8. CHANGES-v1.1.md - Detailed change log
9. FINAL-REVIEW-CHECKLIST.md - Pre-publication checklist

---

## Quick Navigation

### For Executives & Whitepaper Integration

**Start Here:**
1. **[Whitepaper-ARR-Phase1.md](./Whitepaper-ARR-Phase1.md)** (20 pages) **PRIMARY DOCUMENT**
   - Combined Executive Summary + Whitepaper content
   - Ready for direct insertion into ACXRWA whitepaper
   - SwapBox smart contract specification
   - Economic model integration
   - Compliance & KYC framework
   - Market positioning
   - Complete deployment strategy

### For Engineering Teams

**Start Here:**
1. **[ARR-Phase1-DPX-Refactoring.md](./ARR-Phase1-DPX-Refactoring.md)** (25 pages)
   - Complete technical architecture
   - Detailed implementation roadmap
   - Code-level refactoring plan
   - Database schema changes
   - Smart contract designs with full interfaces

2. **[CPX-vs-DPX-Technical-Comparison.md](./CPX-vs-DPX-Technical-Comparison.md)** (20 pages)
   - Side-by-side system comparison
   - Component-by-component analysis
   - Feature toggle implementation patterns
   - Testing strategies

### For Product & UX Teams

**Relevant Sections:**
- **Whitepaper-ARR-Phase1.md** – Core Architectural Changes, Deployment Strategy
- **Technical Comparison** – "User Experience" table
- **DPX Refactoring** – Section 3.2: Public Interfaces & Entry Points
- **Whitepaper-ARR-Phase1.md** – Compliance & Access Control (KYC/AML framework)

### For Security Auditors

**Focus Areas:**
- **SwapBox-Contract.md** – Complete Solidity implementation
- **Whitepaper-ARR-Phase1.md** – Technical Appendix: SwapBox Full Interface
- **DPX Refactoring** – Section 6: Risk Mitigation
- **Whitepaper-ARR-Phase1.md** – Compliance & Access Control (KYC/geofencing)
- **Technical Comparison** – "Security & Compliance" section

---

## Document Descriptions

### 1. Whitepaper-ARR-Phase1.md **PRIMARY DOCUMENT**

**Purpose:** Combined executive summary + whitepaper-ready content for ACXRWA whitepaper  
**Length:** ~20 pages  
**Key Sections:**
- Overview & Strategic Objective
- Architectural Transformation (CPX vs. DPX)
- SwapBox: Trustless Bilateral Settlement
- True ERC-20 FCT Tokens & DeFi Composability
- Feature Toggle Architecture
- System Components & Changes
- Marketplace v2: Project-Based Trading
- Deployment Strategy (Phases 1A-2)
- **Compliance & Access Control** (KYC/AML framework, geofencing)
- Economic Model Integration ($ACR utility)
- Risk Mitigation
- Success Metrics
- Technical Appendix: SwapBox Interface

**Who Should Read:** 
- C-level executives
- Whitepaper authors/editors
- Investors/partners
- Legal/compliance teams
- Product managers

**Reading Time:** 45 minutes

**Special Note:** This document is formatted for **direct inclusion** in ACXRWA whitepaper as Section 7.5.

---

### 2. ARR-Phase1-DPX-Refactoring.md

**Purpose:** Complete technical specification and implementation guide  
**Length:** ~25 pages  
**Key Sections:**

1. **Current CPX Architecture** (Sections 1.1-1.6)
   - Authentication & user management
   - Custody model – centralized ledger
   - Asset lifecycle – FCT minting
   - Payment & settlement – fiat USD
   - Marketplace & order matching
   - Multi-entity architecture

2. **Target DPX Architecture** (Sections 2.1-2.4)
   - Metamask integration (SIWE)
   - ERC-20 FCT tokens
   - USDC payment rails
   - **SwapBox smart contract** (full implementation)

3. **Codebase Refactoring Plan** (Section 3)
   - Component-by-component changes
   - Public interfaces & entry points
   - Smart contract deployment strategy
   - Database schema changes
   - Feature toggle implementation

4. **Technical Benefits** (Section 4)
   - Codebase efficiency
   - Operational flexibility
   - Security & compliance
   - Performance & scalability

5. **Implementation Roadmap** (Section 5)
   - 4-phase timeline (12+ weeks)
   - Deliverables per phase
   - Testing & deployment strategies

6. **Risk Mitigation** (Section 6)
   - Smart contract risks
   - UX complexity risks
   - Liquidity fragmentation
   - Regulatory uncertainty

**Who Should Read:**
- Engineering leads
- Smart contract developers
- Backend/frontend developers
- DevOps engineers
- Security teams

**Reading Time:** 60-90 minutes

---

### 3. CPX-vs-DPX-Technical-Comparison.md

**Purpose:** Detailed side-by-side technical comparison  
**Length:** ~20 pages  
**Format:** Primarily comparison tables with explanations  
**Key Sections:**

1. **System Architecture Comparison**
   - Authentication & user identity
   - Asset custody & tokenization
   - Payment & currency management
   - Order placement & validation
   - Trade matching (identical)
   - Trade settlement (different)

2. **Smart Contracts** – Contract usage matrix

3. **Database Schema** – Table-by-table changes

4. **API Endpoints** – New vs. modified endpoints

5. **Frontend Components** – UI component changes

6. **Background Services** – Service-by-service comparison

7. **Security & Compliance** – Custody model implications

8. **Gas Costs & Transaction Fees** – Economic comparison

9. **Operational Workflows** – Process flow comparisons

10. **User Experience** – UX differences table

11. **Performance & Scalability** – Metrics comparison

12. **Feature Toggle Strategy** – Implementation patterns

13. **Migration Path** – Gradual rollout strategy

14. **Code Organization** – Shared vs. mode-specific modules

15. **Testing Strategy** – Unit, integration, e2e tests

**Who Should Read:**
- All engineering team members
- QA/testing teams
- Technical writers
- System architects

**Reading Time:** 45-60 minutes

---

### 4. Whitepaper-ARR-Section.md

**Purpose:** Whitepaper-ready content for public communication  
**Length:** ~15 pages  
**Tone:** Professional, investor-friendly, technically accurate  
**Key Sections:**

1. **Overview** – Transformation summary

2. **Architectural Transformation** – CPX vs. DPX table

3. **SwapBox: Trustless Bilateral Settlement**
   - Mechanism explanation
   - Settlement flow
   - Security features

4. **True ERC-20 FCT Tokens**
   - FctTokenFactory contract
   - DeFi composability benefits

5. **Feature Toggle Architecture**
   - Single codebase strategy
   - Technical benefits

6. **System Components & Changes** – All layers summarized

7. **Matching Engine** – Highlighting consistency

8. **Deployment Strategy** – 4-phase roadmap

9. **Economic Model Integration** – ACXRWA token utility

10. **Risk Mitigation** – Professional risk assessment

11. **Success Metrics** – KPIs for Phase 1

12. **Conclusion** – Market positioning

13. **Technical Appendix** – SwapBox full interface + gas analysis

**Who Should Read:**
- Marketing teams
- Investor relations
- Legal/compliance
- Technical partners
- Whitepaper authors

**Reading Time:** 30-40 minutes

**Special Note:** This document is formatted for **direct inclusion** in ACXRWA whitepaper as Section 7.5.

---

## Key Concepts & Terminology

### CPX (Carbon Project Exchange)
**Centralized platform (subsystem of ACX exchange) migrating to ACXNET:**
- **Context:** CPX is part of the wider ACX centralized exchange (includes spot/CLOB markets, custody, fiat rails)
- **Network:** ACXNET (AvaLabs Custom Layer 1)
- Username/password authentication
- FCTs held in ACX-controlled STMv2 ledger (Security Token Manager v2 smart contract on ACXNET)
- Fiat USD payments via bank transfers
- Admin-signed blockchain transactions (zero gas fees to users)
- Private mempool for MEV protection
- Ideal for regulated markets and institutional users

### DPX (Decentralized Project Exchange)
**Decentralized variant on Avalanche C-Chain:**
- **Network:** Avalanche C-Chain (Chain ID: 43114)
- Wallet-based authentication (Metamask, Core Wallet, WalletConnect)
- FCTs as true ERC-20 tokens in user wallets
- USDC/USDT payments on-chain
- User-signed blockchain transactions (~$0.42 gas per swap)
- Sub-second finality (<2 seconds)
- Integrates with Trader Joe, Aave, Benqi DeFi protocols
- Ideal for DeFi-native users and permissionless global access

### SwapBox
**Smart contract for trustless bilateral trade settlement:**
- Replaces centralized `transferOrTrade()` ledger function
- ACX backend configures swap after marketplace match
- Buyer deposits USDC, seller deposits FCT
- Contract auto-executes when both assets deposited
- Automatic refunds if swap expires incomplete

### Feature Toggle
**Configuration-driven code branching:**
- Single codebase contains both CPX and DPX logic
- Runtime behavior controlled by `FEATURE_DPX_MODE` env var
- Enables gradual rollout, instant rollback, operational flexibility
- Eliminates code duplication between modes

### SIWE (Sign-In with Ethereum)
**Wallet-based authentication standard:**
- User signs nonce message with private key
- Backend verifies signature cryptographically
- No passwords or centralized identity storage
- Standard adopted by MetaMask, WalletConnect, Coinbase Wallet

---

## Implementation Resources

### Smart Contracts

**SwapBox.sol (Avalanche C-Chain):**
- **Full production-ready Solidity code:** `SwapBox-Contract.md` **NEW**
- Complete implementation with multiple concurrent swaps support
- TypeScript usage examples included
- Interface reference in: `Whitepaper-ARR-Section.md`, Technical Appendix
- Architecture overview in: `ARR-Phase1-DPX-Refactoring.md`, Section 2.4
- Gas analysis (Avalanche): `Whitepaper-ARR-Section.md`, Appendix
- Deployment target: Avalanche C-Chain mainnet (43114)
- Testnet: Avalanche Fuji (43113)

**FctTokenFactory.sol (Avalanche C-Chain):**
- Simplified interface in: `Whitepaper-ARR-Section.md`, Section 4
- Full specification in: `ARR-Phase1-DPX-Refactoring.md`, Section 2.2
- Network: Avalanche C-Chain for maximum DeFi composability

**STMv2.sol (ACXNET Custom L1):**
- Contract name: STMv2 (Security Token Manager v2)
- Current deployment: Polygon PoS (ACX/CPX platform)
- Migration target: ACXNET (AvaLabs custom subnet)
- Migration type: Hard cutover (Polygon decommissioned simultaneously)
- Benefits: Zero gas fees for users, private mempool, dedicated validators

### Code Examples

**Feature Toggle Patterns:**
- Configuration: `ARR-Phase1-DPX-Refactoring.md`, Section 3.5
- Usage examples: `CPX-vs-DPX-Technical-Comparison.md`, Section 12

**Authentication:**
- SIWE implementation: `ARR-Phase1-DPX-Refactoring.md`, Section 2.1
- Comparison: `CPX-vs-DPX-Technical-Comparison.md`, Section 1

**Settlement:**
- SwapBox integration: `ARR-Phase1-DPX-Refactoring.md`, Section 2.4
- Workflow comparison: `CPX-vs-DPX-Technical-Comparison.md`, Section 9

### Database Schemas

**New Tables:**
- `user_wallet`, `swapbox_swap`: `ARR-Phase1-DPX-Refactoring.md`, Section 3.4
- Detailed schemas: `CPX-vs-DPX-Technical-Comparison.md`, Section 3

**Modified Tables:**
- `x_asset`, `user_account`: Both documents, Section 3

### API Specifications

**New Endpoints:**
- `/api/auth/wallet-login`
- `/api/swapbox/:swapId`
- `/api/apx/deploy-fct-token`

**Details:** `ARR-Phase1-DPX-Refactoring.md`, Section 3.2.2

---

## Testing Guidelines

### Test Coverage Requirements

| Component | Target Coverage | Test Types |
|-----------|----------------|------------|
| SwapBox Contract | >95% | Unit, integration, fuzz |
| FctTokenFactory | >90% | Unit, integration |
| Feature Toggles | 100% | Unit (both modes) |
| Settlement Flows | >90% | Integration, e2e |
| Authentication | >85% | Unit, integration |

**Detailed Strategy:** `CPX-vs-DPX-Technical-Comparison.md`, Section 15

### End-to-End Test Scenarios

**CPX Mode:**
1. Register → login with credentials
2. Admin deposits fiat USD
3. Admin mints FCT to ledger account
4. Place order (ledger balance check)
5. Match executes → auto-settle via `transferOrTrade()`

**DPX Mode:**
1. Connect Metamask wallet
2. User holds USDC (acquired externally)
3. Admin mints FCT as ERC-20 to wallet
4. Approve USDC → place order
5. Match executes → deposit to SwapBox → settle

**Detailed Flows:** `CPX-vs-DPX-Technical-Comparison.md`, Section 15

---

## Security Audit Checklist

### Smart Contracts

**SwapBox.sol:**
- [ ] Reentrancy protection verified
- [ ] Integer overflow/underflow checks
- [ ] Access control on `configureSwap()`
- [ ] Emergency pause mechanism tested
- [ ] Expiry timestamp validation
- [ ] Gas optimization review

**FctTokenFactory.sol:**
- [ ] ERC-20 standard compliance
- [ ] Metadata immutability
- [ ] Mint authorization checks
- [ ] Supply cap enforcement

**Third-Party Dependencies:**
- [ ] OpenZeppelin contracts up-to-date
- [ ] Known vulnerabilities scanned (Slither, Mythril)

### Backend Services

**Feature Toggles:**
- [ ] No logic bypasses when toggled off
- [ ] Mode switching cannot corrupt state
- [ ] Audit logs capture toggle changes

**Wallet Authentication:**
- [ ] Nonce replay attack prevention
- [ ] Signature verification robustness
- [ ] Session expiry enforcement

**Settlement Integration:**
- [ ] SwapBox expiry monitoring
- [ ] Failed deposit refund testing
- [ ] Double-spend prevention

**Full Risk Assessment:** `ARR-Phase1-DPX-Refactoring.md`, Section 6

---

## Deployment Checklist

### Pre-Deployment

**Smart Contracts:**
- [ ] Testnet deployment completed (Polygon Mumbai / Sepolia)
- [ ] External security audit completed
- [ ] Bug bounty program launched
- [ ] Gas optimization finalized

**Backend:**
- [ ] Feature toggle framework merged
- [ ] SIWE authentication tested
- [ ] SwapBox monitoring service deployed
- [ ] Database migrations tested

**Frontend:**
- [ ] WalletConnect integration complete
- [ ] SwapBox deposit UI tested
- [ ] Fallback to CPX mode functional

### Deployment Phases

**Phase 1A – Foundation (Nov 2025: 4 weeks):**
- Deploy contracts to **Avalanche Fuji testnet** (43113)
- Design ACXNET subnet configuration
- Enable DPX mode for internal test entity
- Security audit begins

**Phase 1B – Development Sprint (Dec 2025: 4 weeks):**
- Complete dual-network backend (Avalanche + ACXNET)
- Frontend integration with Core Wallet, WalletConnect
- Security audit remediation
- Load testing across both networks

**Phase 1C – Network Launches (Jan-Feb 2026: 8 weeks):**
- **Week 1-4:** Deploy ACXNET, migrate ACX/CPX from Polygon (hard cutover + Polygon decommission)
- **Week 5-8:** Deploy DPX to Avalanche C-Chain mainnet
- Pilot launch: 3-5 entities per network

**Phase 1D – Production Scale (Mar-Apr 2026: 8 weeks):**
- Global DPX rollout on Avalanche
- All ACX/CPX fully operational on ACXNET (Polygon decommissioned in Phase 1C)
- Investigate market appetite for DEX liquidity pools (e.g., Trader Joe FCT/USDC pairs)
- Launch $ACR token staking
- Target: 1,000+ DPX wallets, $15M+ volume

**Phase 2 – Cross-Mode Bridge (May-Jun 2026: 8 weeks):**
- ACXNET ↔ Avalanche C-Chain bridge deployment
- Unified order book matching CPX and DPX trades
- **Go-Live:** June 30, 2026

**Detailed Timeline:** `ARR-Phase1-DPX-Refactoring.md`, Section 5

---

## Success Criteria

### Technical Metrics

**Performance:**
- [ ] Swap success rate >95%
- [ ] Settlement latency <10 minutes (p95)
- [ ] Gas cost <$5 per swap (Polygon)
- [ ] System uptime 99.9%

**Security:**
- [ ] Zero critical vulnerabilities
- [ ] Zero loss-of-funds incidents
- [ ] <2 hours rollback time if needed

**Code Quality:**
- [ ] <10% code duplication (CPX/DPX)
- [ ] All tests passing
- [ ] Linter errors = 0

### Business Metrics

**Adoption:**
- [ ] 500+ active DPX wallets (6 months)
- [ ] $10M+ USDC volume (Q1)
- [ ] 50% of new users choose DPX

**Liquidity:**
- [ ] <5% slippage on top 10 pairs
- [ ] 24/7 market availability
- [ ] $5M+ total value locked (TVL)

**User Satisfaction:**
- [ ] >4.5/5 rating for DPX UX
- [ ] <5% support tickets wallet-related
- [ ] >80% swap completion rate (user action)

**Full Metrics:** `ARR-Phase1-DPX-Refactoring.md`, Section 7

---

## Phase 2 Preview: Cross-Mode Liquidity

### Bridge Architecture (Q4 2026)

**Goal:** Enable CPX users to trade with DPX users seamlessly

**Mechanism:**
1. **Wrap:** Lock FCT on CPX ledger → mint wrapped FCT (wFCT) ERC-20 on DPX
2. **Unwrap:** Burn wFCT on DPX → unlock FCT on CPX ledger
3. **Unified Order Book:** Match CPX bids with DPX asks transparently
4. **Market Makers:** Incentivize liquidity provision across bridge

**Benefits:**
- Single liquidity pool for all users
- No custody preference fragmentation
- Maximum market depth and efficiency

**Future Documentation:** `ARR-Phase2-Cross-Mode-Bridge.md` (TBD)

---

## Additional Resources

### External Dependencies

**Smart Contract Libraries:**
- OpenZeppelin Contracts v5.0+
- Hardhat / Foundry testing frameworks
- **Avalanche Subnet EVM** (for ACXNET deployment)
- Slither / Mythril security scanners

**Frontend Libraries:**
- WalletConnect v2
- Wagmi / Viem (Ethereum + Avalanche interaction)
- **Core Wallet SDK** (Avalanche native wallet)
- RainbowKit (wallet UI with Avalanche support)

**Backend Libraries:**
- ethers.js v6 with **Avalanche RPC providers**
- TypeChain (contract type generation)
- Moleculer.js (microservices)
- **Avalanche.js** (for subnet/C-Chain operations)

**Avalanche-Specific:**
- **Avalanche Network Runner** (local subnet testing)
- **Subnet EVM** (ACXNET custom L1)
- **Avalanche Warp Messaging** (Phase 2 cross-subnet bridge)
- **Trader Joe SDK** (DeFi integrations)

### Related AirCarbon Documentation

- `highlights.md` – Codebase technical analysis
- `Overview.md` – Component architecture
- `deployment/k8s/ARCHITECTURE.md` – Kubernetes deployment
- `.cursor/rules/` – Development guidelines

### Standards & Protocols

- **EIP-4361:** Sign-In with Ethereum (SIWE)
- **ERC-20:** Token standard
- **ERC-1155:** Multi-token standard (alternative)
- **OpenZeppelin:** Security best practices

---

## Document Maintenance

### Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | Nov 2025 | Initial ARR Phase 1 suite | ACX Engineering |

### Update Cadence

- **Weekly:** During Phase 1 implementation (code examples, discoveries)
- **Monthly:** Post-deployment (success metrics, lessons learned)
- **Quarterly:** Strategic updates (Phase 2 planning)

### Feedback & Questions

**Internal:** Slack #arr-phase1 channel  
**External:** engineering@aircarbon.co

---

## Summary

This documentation suite provides **complete technical specification** for ACX's transformation from centralized CPX to dual-mode CPX/DPX platform.

**Key Deliverables:**
1. Executive summary for stakeholders
2. Full technical architecture (25 pages)
3. Detailed CPX vs. DPX comparison
4. Whitepaper-ready content
5. Implementation roadmap (6 months)
6. Smart contract specifications
7. Testing & security guidelines

**Total Investment:** ~45 pages of deep technical detail ensuring successful delivery of Phase 1.

**Next Steps:**
1. Review executive summary with leadership
2. Conduct smart contract audit RFP
3. Begin Phase 1A sprint planning
4. Approve resource allocation

---

**Document Suite Status:** **Complete & Ready for Review**  
**Date:** November 2025  
**Version:** 1.0  
**Classification:** Internal / Investor-Shareable

