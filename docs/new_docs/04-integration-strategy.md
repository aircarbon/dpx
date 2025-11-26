# Integration Strategy

## The Dual-Mode Approach

DPX and CPX are designed to operate as complementary platforms within the unified ACXRWA ecosystem. Rather than competing solutions, they represent two access modes to the same underlying carbon RWA market—each optimized for different user profiles and regulatory contexts.

### Why Two Platforms?

The carbon credit market spans a diverse range of participants with fundamentally different requirements:

**Institutional & Regulated Markets (CPX):**
- Corporate sustainability teams with compliance obligations
- Regulated financial institutions requiring custody solutions
- Traditional finance participants unfamiliar with Web3
- Jurisdictions requiring centralized custody and fiat settlement

**DeFi & Crypto-Native Markets (DPX):**
- DAOs and protocol treasuries seeking carbon exposure
- Crypto-native investors preferring self-custody
- DeFi protocols requiring composable ERC-20 assets
- Global participants in regions with limited banking access

A single platform cannot optimally serve both segments. CPX's custodial model provides the compliance infrastructure and familiar UX that institutions require, while DPX's non-custodial architecture delivers the self-sovereignty and composability that DeFi participants expect.

By offering both modes, ACXRWA can capture the entire addressable market rather than forcing participants to compromise on their core requirements.

### Strategic Benefits

**Market Coverage:**
The dual-mode approach ensures ACXRWA serves the complete spectrum of carbon market participants—from institutional carbon credit buyers executing large bilateral trades to DeFi protocols seeking programmatic carbon exposure.

**Risk Distribution:**
Operating across two models reduces concentration risk. Regulatory changes affecting custodial platforms don't impact non-custodial operations, and vice versa. This resilience protects both the platform and its users.

**Competitive Positioning:**
Few platforms offer both institutional-grade custody AND non-custodial DeFi access. This unique positioning differentiates ACXRWA from both traditional carbon exchanges (no DeFi) and crypto-native platforms (no institutional infrastructure).

---

## Shared Infrastructure

DPX leverages ACX's existing infrastructure and operational expertise, enabling efficient development without building from scratch.

### Platform Components

**User Interface & Experience:**
DPX builds upon ACX's established UI/UX patterns and design systems. The marketplace interface, project browsing, and trading workflows benefit from years of refinement on CPX. Users familiar with CPX will find DPX intuitive, while new users benefit from a polished, production-tested experience.

**Backend Services:**
Core services developed for ACX—project data management, analytics, notification systems, and API infrastructure—are architected for reuse across both platforms. This shared foundation accelerates DPX development and ensures consistency.

**Operational Expertise:**
ACX's experience operating carbon exchanges across multiple jurisdictions informs DPX's design. Compliance frameworks, security practices, and operational procedures developed for CPX provide a foundation for DPX operations.

### Dual Authentication Model

The platform supports two authentication methods, allowing users to choose their preferred access mode:

**Traditional Login (CPX Mode):**
- Username/password with multi-factor authentication
- Custodial asset management via STMv2 ledger
- Fiat currency deposits and withdrawals
- Full platform custody of user assets

**Wallet-Based Login (DPX Mode):**
- Web3 wallet connection (MetaMask, WalletConnect, etc.)
- Self-custody of assets in user's wallet
- Stablecoin-based transactions
- Non-custodial trading via smart contracts

Users can maintain both access methods, choosing the appropriate mode based on their needs for each interaction. A corporate treasury might use CPX for large, compliance-documented purchases while using DPX for smaller, more agile positions.

---

## Unified Liquidity Vision

A key long-term objective is enabling liquidity to flow between CPX and DPX, creating a unified market that benefits all participants regardless of their access mode.

### The Opportunity

Currently, custodial and non-custodial carbon markets operate in isolation. Institutional liquidity on platforms like CPX cannot easily reach DeFi participants, while DeFi liquidity remains inaccessible to traditional market participants. This fragmentation reduces overall market efficiency and limits price discovery.

By connecting CPX and DPX liquidity pools, ACXRWA can:

- **Deepen Markets:** Combined order flow creates more liquid markets with tighter spreads
- **Improve Price Discovery:** Unified pricing across both platforms ensures consistent, fair market prices
- **Expand Access:** Institutional supply can meet DeFi demand, and vice versa
- **Reduce Friction:** Users can access the best available liquidity regardless of their platform preference

### Bridge Architecture

The bridge between CPX (on ACXNET) and DPX (on Avalanche) will leverage native Avalanche primitives to enable secure, transparent asset transfers:

**Avalanche C-Chain (Primary Layer):**
Will host DPX's ERC-20 FCT tokens, smart contracts (UsdcDistributor, governance, marketplace settlement), and DeFi composability layer. All non-custodial trading and asset management will occur here.

**Avalanche X-Chain (Routing & Registry):**
Will serve as an immutable provenance ledger for FCT issuance and bridging events. When CPX-registered FCTs are issued in STMv2, issuance hashes will be anchored to X-Chain before bridging to C-Chain, creating a lightweight, timestamped audit trail that preserves traceability across both platforms.

**Bridge Flows:**
- **CPX → DPX:** STMv2 FCT → X-Chain provenance record → C-Chain ERC-20 issuance via FCTBridge
- **DPX → CPX:** C-Chain burn → X-Chain confirmation → STMv2 credit restoration

**Future Enhancements:**
- **Avalanche Subnets:** Regulatory segregation via permissioned CPX subnet with native KYC integration and jurisdictional firewalling
- **Avalanche Warp Messaging (AWM):** Cross-platform state synchronization for delivery confirmations and carbon registry updates without external oracles
- **Avalanche Indexer:** Real-time transparency for issuance, burns, redemptions, and market activity integrated into Avalanche ecosystem tools

### Implementation Approach

Unified liquidity will be implemented progressively:

**Phase 1 - Parallel Operation:**
CPX and DPX operate independently with separate liquidity pools. Users choose their preferred platform based on their requirements.

**Phase 2 - Asset Bridging:**
Bridge infrastructure enables users to move assets between platforms. Liquidity remains separate, but users can access both markets by bridging their holdings.

**Phase 3 - Unified Order Book:**
Advanced integration enables orders from both platforms to interact, creating a single unified market. Institutional CPX orders can match with DPX counterparties, and vice versa.

The phased approach allows each stage to be thoroughly tested and validated before progressing, ensuring security and reliability at every step.

---

## Value Proposition Summary

| Aspect | CPX Only | DPX Only | Dual-Mode (CPX + DPX) |
|--------|----------|----------|----------------------|
| **Market Reach** | Institutional only | DeFi only | Complete market coverage |
| **Liquidity** | Institutional pools | DeFi pools | Unified liquidity (future) |
| **User Choice** | Custody required | Self-custody required | User chooses per transaction |
| **Regulatory Flexibility** | High compliance | Permissionless | Both options available |
| **Development Efficiency** | Standalone | Standalone | Shared infrastructure |

The integration strategy ensures that ACXRWA can serve any carbon market participant, leverage existing infrastructure investments, and work toward a future where liquidity flows freely between institutional and DeFi markets.

---

*Previous: [03 - DPX Architecture](./03-dpx-architecture.md)*
*Next: [05 - Roadmap](./05-roadmap.md)*
