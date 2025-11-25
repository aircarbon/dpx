# ACX & CPX Platform Overview

## ACX Group

ACX (AirCarbon Exchange) is a climate-finance technology company that designs and delivers environmental market infrastructure as a service for governments, exchanges, corporates, and project developers. ACX provides SaaS trading technology and market architecture, enabling partners to operate carbon exchanges and environmental asset marketplaces.

ACX's institutional-grade platform includes order matching, standardized contracts, settlement tooling, and tokenization capabilities. This infrastructure has been deployed across multiple jurisdictions, powering carbon exchanges and environmental markets in Indonesia, Brazil, Argentina, the USA, and other regions.

### Core Capabilities

ACX provides its partners with:

- **Exchange Technology:** Institutional-grade order matching and trade execution
- **Settlement Infrastructure:** Atomic on-chain settlement with full audit trails
- **Custody Services:** Secure asset custody with centralized ledger management
- **Tokenization Rails:** Converting carbon contracts into tradeable digital instruments
- **Fiat Integration:** Bank wire deposits/withdrawals and fiat currency settlement
- **Compliance Tools:** KYC/AML integration, entity permissions, and jurisdictional controls

---

## CPX: Carbon Project Exchange

CPX (Carbon Project Exchange) is the project-based carbon credit marketplace within the ACX platform. It enables bilateral trading of Future Carbon Tons (FCTs)—tokenized RWAs representing forward carbon contracts derived from ERPAs.

### How CPX Works

CPX operates as a **custodial, centralized marketplace** where ACX manages all blockchain interactions on behalf of users:

**User Authentication:**
- Traditional username/password login with multi-factor authentication
- Users do not hold private keys to blockchain addresses
- ACX-controlled admin accounts execute all on-chain transactions

**Asset Custody (STMv2 Ledger):**
- FCTs exist as entries in the STMv2 (Security Token Manager v2) smart contract
- ACX maintains a centralized ledger tracking all user balances
- Assets are held in ACX-controlled addresses, not user wallets
- Transfers occur only within the platform ecosystem

**Payment Settlement:**
- Fiat USD settlement via traditional bank wires
- Users deposit funds through bank transfers; ACX credits their ledger balance
- No stablecoin or cryptocurrency payments required

**Trading via Marketplace v2:**
- Bilateral negotiation platform (not an order book exchange)
- Sellers list FCT projects with price, quantity, and criteria
- Buyers submit trade requests and negotiate terms directly
- Upon agreement, ACX executes atomic settlement via the STMv2 ledger

### Current Deployment & Migration

**Current State:**
CPX currently operates on Polygon PoS, with all STMv2 ledger transactions and FCT minting occurring on the Polygon network.

**Migration to ACXNET:**
ACX is migrating the entire CPX platform from Polygon to ACXNET—a custom Avalanche subnet (Layer 1) purpose-built for institutional carbon trading. ACXNET will provide:

- **Zero Gas Fees:** ACX subsidizes all transaction costs for users
- **Dedicated Throughput:** No congestion from public network traffic
- **Sub-Second Finality:** Faster settlement than public blockchains
- **Private Mempool:** MEV protection for institutional trades
- **Institutional SLAs:** Controlled validator set with guaranteed uptime

The migration involves a state snapshot of all Polygon balances and a hard cutover to ACXNET, after which Polygon infrastructure will be decommissioned.

### CPX Strengths & Limitations

**Strengths:**
- Familiar user experience (no crypto wallet required)
- Zero gas fees for end users
- Fiat currency support (no stablecoin complexity)
- Full custody and transaction reversibility
- Ideal for regulated markets and institutional users

**Limitations:**
- Users cannot self-custody assets
- FCTs are not composable with DeFi protocols
- Limited to platform participants only (no external transfers)
- Centralized custody creates counterparty risk
- Excludes crypto-native and DeFi participants

---

## The Need for DPX

While CPX serves institutional and regulated markets effectively, significant demand exists for non-custodial carbon RWA access:

- **DeFi Protocols:** DAOs and treasury managers want to hold carbon RWAs without centralized custody
- **Crypto-Native Investors:** Users accustomed to self-custody prefer wallet-based platforms
- **Global Accessibility:** Permissionless access removes geographic and institutional barriers
- **DeFi Composability:** True ERC-20 tokens enable lending, liquidity provision, and yield strategies

DPX addresses these needs by providing a decentralized alternative that operates alongside CPX within the unified ACX ecosystem. The following sections detail the DPX architecture and how both platforms integrate to serve the complete spectrum of carbon market participants.

---

*Previous: [01 - Introduction](./01-introduction.md)*
*Next: [03 - DPX Architecture](./03-dpx-architecture.md)*
