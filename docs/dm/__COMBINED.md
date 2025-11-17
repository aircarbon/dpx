# ACXRWA Architecture Refactoring Roadmap
## Phase 1: CPX to DPX Transformation

**Complete Technical Documentation**

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

**Document Purpose:**  
This comprehensive technical documentation supports ACXRWA White Paper Section 7 (Technical Design), detailing the architecture, implementation strategy, and roadmap for transforming AirCarbon's centralized Carbon Project Exchange (CPX) into a dual-mode platform supporting both custodial (CPX) and non-custodial (DPX) operations.

**Intended Audience:**  
Engineering teams, technical leadership, security auditors, investors, partners, and whitepaper contributors.

**Source Documents:**  
All source files available in `src/` directory for reference.

---

# Part I: Executive Summary

*This section is formatted for direct inclusion in ACXRWA White Paper Section 7.5*

---

## 1. Strategic Vision

The ACXRWA platform will evolve from the current **Carbon Project Exchange (CPX)** centralized architecture to support a parallel **Decentralized Project Exchange (DPX)** operating mode. This transformation represents a fundamental shift enabling the platform to serve two distinct market segments—**institutional custodial** and **DeFi-native non-custodial**—from a single unified codebase, governed by the **ACR token** (1 billion supply, Avalanche mainnet).

**Core Innovation:**  
Single platform, dual custody models, unified liquidity across centralized and decentralized carbon markets.

### Network Strategy

**DPX (Decentralized Project Exchange):**
- Deploys on **Avalanche C-Chain** (Chain ID: 43114)
- Sub-second finality (<2 seconds)
- Low gas costs (~$0.42 per swap)
- Robust DeFi ecosystem (Trader Joe, Aave, Benqi)
- Ideal for crypto-native projects and buyers

**CPX (Centralized Project Exchange):**
- Migrates to **ACXNET** (AvaLabs Custom Layer 1)
- Zero gas fees for users (ACX-subsidized)
- Instant finality (<1 second)
- Private mempool (MEV protection)
- Ideal for regulated markets and institutions

**CPX Context:** CPX is a subsystem of the wider ACX centralized exchange platform, which encompasses spot/CLOB markets, custody services, and fiat on/off-ramps.

---

## 2. Architectural Transformation

### 2.1 Key Dimensions of Change

| Dimension | CPX (Custodial) | DPX (Non-Custodial) |
|-----------|-----------------|---------------------|
| **Authentication** | Username/password (JWT sessions) | Wallet signature (SIWE standard) |
| **FCT Custody** | STMv2 ledger (ACX-controlled) | ERC-20 tokens (user wallets) |
| **Payment Rails** | Fiat USD (bank accounts) | USDC/USDT (on-chain) |
| **Settlement** | Admin-signed atomic swap | SwapBox atomic signature-based swap |
| **Network** | ACXNET (Custom L1) | Avalanche C-Chain |
| **Gas Fees** | $0 (subsidized) | ~$0.15 per swap |

### 2.2 Trading Platform: Marketplace v2 (MBv2)

Both CPX and DPX operate on **Marketplace v2 (MBv2)**—a bilateral negotiation platform distinct from the C# matching engine (CLOB/spot market).

**MBv2 Architecture:**
- Sellers list specific FCT projects (vintage, registry, methodology)
- Buyers submit trade requests with proposed price/quantity
- Direct negotiation via counter-offers and messaging
- Settlement triggered upon mutual acceptance

**NOT Used:** C# matching engine (CLOB/spot market) is reserved for contract-based trading (CET, GNT fungible tokens), not project-based FCT trading in Phases 1-2.

**Trade Flow:**
```
Seller Lists Project on MBv2
    ↓
Buyer Submits Trade Request
    ↓
Negotiation (Counter-Offers)
    ↓
Seller Accepts Final Terms
    ↓
Settlement (CPX: transferOrTrade | DPX: SwapBox atomic execution)
```

---

## 3. SwapBox: Trustless Atomic Settlement

The **SwapBox** smart contract enables DPX to eliminate ACX custody through atomic, signature-based swaps. Built on **AirSwap's audited SwapERC20** architecture, SwapBox executes FCT ↔ stablecoin trades in a single transaction without ever holding user funds.

### 3.1 Mechanism

SwapBox uses **EIP-712 signed orders** for atomic execution. Buyers create and sign orders off-chain (e.g., "buy 100 FCT for 1000 USDC"). Sellers execute swaps on-chain by submitting the buyer's signature. The contract verifies the signature and atomically transfers tokens in a single transaction—either the entire swap succeeds or it reverts.

**Contract Interface:**
```solidity
interface ISwapBox {
    function swap(
        uint256 nonce,
        uint256 expiry,
        address signerWallet,
        address signerToken,    // USDC
        uint256 signerAmount,
        address senderToken,    // FCT
        uint256 senderAmount,
        uint8 v, bytes32 r, bytes32 s
    ) external;
}
```

### 3.2 Settlement Flow

1. **Order Creation:** Buyer signs order off-chain (EIP-712 signature)
2. **Order Discovery:** DPX displays order in UI (DPX never custodies funds)
3. **Atomic Execution:** Seller submits transaction with buyer's signature
4. **Verification:** SwapBox verifies signature, checks expiry and nonce
5. **Token Transfer:** FCT → buyer, USDC → seller, fee → treasury/staking (atomic)

**Key Features:**
- **Non-custodial:** DPX never holds funds, only provides order discovery
- **Atomic:** Single transaction (all transfers succeed or entire swap reverts)
- **Gas-efficient:** ~50K gas (~$0.15 on Avalanche @ 25 nAVAX, $30 AVAX)
- **AirSwap heritage:** Built on audited, battle-tested SwapERC20
- **Modified fees:** Always collected in stablecoins (USDT/USDC), never illiquid FCT (enforced through the UI, FCT buyer is always a signer, FCT seller always executes the transaction)

---

## 4. True ERC-20 FCT Tokens

Unlike CPX where FCTs exist only as ledger entries, DPX mints **real ERC-20 tokens** to project owners' wallets via the **FctFactory** contract, which manages project proposals, approvals, and token deployment.

### 4.1 DeFi Composability

ERC-20 FCTs on Avalanche unlock ecosystem integrations:

- **Trader Joe/Pangolin:** Liquidity pools for FCT/USDC trading
- **Aave/Benqi:** Collateralized loans using FCTs
- **Yield Yak:** Auto-compounding yield strategies
- **Cross-Chain Bridges:** Port FCTs via LayerZero, Axelar
- **Future:** ACXNET integration for institutional liquidity

### 4.2 Metadata & Compliance

Each FCT ERC-20 embeds immutable metadata defining a **standard for future carbon tokens**:
- **Project ID:** Unique identifier
- **Vintage Year:** Carbon credit issuance year (uint256)
- **Registry ID:** "VCS-1234", "GS-5678" (Verra, Gold Standard, ART)
- **Country:** ISO-3166 country code
- **Methodology:** "VM0042", "ACM0002" (project methodology)
- **CORSIA Eligible:** Boolean flag for aviation offset eligibility
- **Article 6 Authorized:** Boolean for Paris Agreement compliance

**Deployment Workflow:**
1. Developer proposes project via `FctFactory.proposeProject()`
2. Multisig (Phase 1) or DAO (Phase 3) reviews proposal
3. `approveProject()` deploys FutureCarbonToken ERC-20 with metadata

---

## 5. Feature Toggle Architecture

### 5.1 Single Codebase, Dual Behavior

The platform determines CPX vs. DPX behavior via runtime configuration:

```typescript
// Environment variable
FEATURE_DPX_MODE=true  // or false

// Runtime decision logic
if (config.FEATURE_DPX_MODE) {
  authenticateWallet(signature, address);      // DPX
  mintErc20Fct(ownerWallet, amount);           // Avalanche
  settleViaSwapBox(signedOrder);               // Atomic signature-based
} else {
  authenticateCredentials(username, password); // CPX
  mintLedgerFct(ledgerAddress, amount);        // ACXNET
  settleViaLedger(tradeRequest);               // Admin-signed
}
```

### 5.2 Technical Benefits

**Efficiency:**
- ~50% reduction in code maintenance vs. separate platforms
- Shared business logic: MBv2 negotiation, risk management, entity permissions
- Unified test suite covers both modes

**Operational Flexibility:**
- Enable DPX per entity/region via configuration
- Instant rollback (toggle=false) if issues arise
- Gradual rollout based on operational readiness

**Scalability:**
- CPX: Batched admin transactions (gas-efficient)
- DPX: Parallel user settlements (eliminates centralized bottleneck)
- Horizontal scaling via decentralized architecture

---

## 6. Phased Roadmap

**Timeline:** 6-month rollout targeting full cross-mode liquidity and staking by end Q2 2026 (June 30, 2026).

### Phase 1A – Foundation (Nov 2025: 4 weeks)
**Infrastructure & Network Design (ACX)**
- Design ACXNET subnet configuration
- Implement SIWE authentication
- Begin security audit (Halborn, Trail of Bits)

**Smart Contract Deployment (DPX) - Avalanceh Mainnet**
- Deploy ACR token (1B supply, ERC-20)
- Set up Safe multisig treasury controls for ACR
- Deploy Hedgey vesting contracts for team/investors

**Smart Contract Deployment (DPX) - Fuji Testnet**
- Deploy FctFactory for project proposals, approvals, FCT minting
- Deploy SwapBox for atomic FCT ↔ stablecoin swaps (zero fees)
- Deploy RedemptionVault template
- Set up Safe multisig treasury controls for FctFactory and SwapBox
- Establish Safe multisig approval process for FctFactory projects

### Phase 1B – Development Sprint (Dec 2025: 4 weeks)
**Platform Development (ACX)**
- Complete WalletConnect integration (Avalanche)
- Dual-network backend refactoring
- Load testing (1,000+ concurrent orders)

**DPX Operations Launch (DPX)**
- Build FctFactory and SwapBox UI
- Begin onboarding first FCT projects
- External audit completion (FctFactory, FutureCarbonToken, RedemptionVault)


### Phase 1C – Network Launches (Jan-Feb 2026: 8 weeks)
**Network Deployment (ACX)**
- ACXNET Launch: Deploy STMv2, migrate ACX/CPX from Polygon (hard cutover)
- Onboard handpicked crypto-native projects and buyers

**Smart Contract Deployment (DPX) - Avalanche Mainnet**
- Deploy FctFactory + SwapBox to Avalanche mainnet
- Approve and onboard FCT projects
- Enable zero-fee atomic swaps


### Phase 1D – Production Scale (Mar-Apr 2026: 8 weeks)

**Ecosystem Expansion (ACX)**
- Expand DPX to additional crypto-native participants
- ACX/CPX fully operational on ACXNET
- Investigate DEX liquidity pool appetite

**Staking & Fee Collection Launch (DPX)**
- Deploy ACR staking contract (Curve-style, multi-token fee support)
- Enable SwapBox fees (sent to staking contract)
- Implement fee distribution: USDT, USDC, DAI to ACR stakers
- Optional: 50% fee discount for stakers

### Phase 2 – Cross-Mode Bridge & DAO Governance (May-Jun 2026: 8 weeks)
**Advanced Infrastructure (ACX)**
- ACXNET ↔ Avalanche bridge for FCT wrapping
- Unified order book (CPX bids match DPX asks)
- Market maker incentives ($ACR rewards)

**DAO Transition and further ACR integration (DPX)**
- Transfer ownership of ACR token, treasury and DPX: Safe multisig → Tally DAO (after sufficient ACR vesting)
- Projects must stake ACR tokens to submit proposals to the FctFactory
- A portion of SwapBox fees is allocated to ACR buyback and burn
- Enable ACR holder voting on: project approvals, fee parameters, required ACR stake for project proposals, what share of fees goes to ACR buyback and burn


---

## 7. Compliance & Access Control

### 7.1 Tiered KYC Framework

While DPX uses wallet-based login, compliance requirements adapt to regulatory context:

**Level 0 – Wallet-Only (Browsing):** View listings, no trading

**Level 1 – Self-Attestation:** Accredited investor questionnaire, $50K trading cap

**Level 2 – Document Verification:** Identity docs, corporate verification, unlimited trading

**Level 3 – Enhanced Due Diligence:** Video calls, source-of-funds, institutional support

### 7.2 Geofencing Strategy

- IP-based geolocation at wallet connection
- OFAC sanction list blocking
- Regional tiers (e.g., US: accredited investors only)
- Flexible framework driven by legal/operational requirements

---

## 8. Economic Model Integration

### 8.1 ACR Token Fundamentals
- **Total Supply:** 1,000,000,000 ACR (fixed, no inflation)
- **Token Standard:** ERC-20 (OpenZeppelin) + additional functionality
- **Network:** Avalanche C-Chain (43114)
- **Ownership:** Safe multisig (Phase 1) → Tally DAO (Phase 2)
- **Distribution:** Team/investor cliff and vesting via Hedgey platform; treasury for ecosystem growth

### 8.2 Value Accrual Mechanisms
**Staking & Fee Distribution**
- Stake ACR to earn proportional share of SwapBox fees (USDT, USDC, DAI)
- Distribution pro-rata by staked amount × lock duration
- Optional 50% swap fee discount for stakers

**Buyback & Burn**
- Safe multisig (Phase 1) or Tally DAO (Phase 2) determined portion of SwapBox fees allocated to ACR buyback
- Purchased tokens permanently burned, reducing circulating supply
- After bridge deployment: unified revenue from both DPX swap fees and CPX trading fees (ACXNET)

**Fee Flow**
- SwapBox swap → Fee (stablecoin) → Staking contract → ACR stakers + ACR buyback and burn

### 8.3 Governance & Utility
**DAO Voting Rights:**
- Approve/deny FctFactory project proposals
- Set SwapBox fee parameters and allocation (staking vs. buyback)
- Determine required ACR stake for project submissions
- Upgrade protocol implementations (UUPS)

**Project Proposal Stake:**
- Projects must stake ACR to submit to FctFactory (anti-spam)
- Stake amount governed by DAO vote

### Economic Progression:
- Phase 1A-1C (Nov 2025 - Feb 2026): Zero fees drive adoption
- Phase 1D (Mar-Apr 2026): Staking and fee distribution activate
- Phase 2 (May-Jun 2026): Full DAO governance, buyback & burn, cross-mode revenue capture

---

## 9. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **Smart Contract Bugs** | External audit + $100K bug bounty + emergency pause |
| **UX Complexity** | Handpicked DeFi-native participants + in-app guides + CPX fallback |
| **Liquidity Fragmentation** | Phase 2 bridge unifies pools + market maker incentives |
| **Regulatory Uncertainty** | Tiered KYC + geofencing + legal review per market |

---

## 10. Success Metrics

**Technical:**
- Swap completion rate >95%
- Settlement time: instant (single transaction)
- Gas cost <$0.20 (Avalanche)
- ACXNET uptime >99.9%

**Business:**
- 1,000+ active DPX wallets (Q1 2026)
- $15M+ USDC volume via SwapBox
- 50+ handpicked projects onboarded
- Polygon → ACXNET hard cutover (Phase 1C)

**Operational:**
- Zero critical security incidents
- <10% code duplication (CPX/DPX)
- <2 hour rollback capability

---

## 11. Market Positioning

**Unique Value Proposition:**

> *"ACXRWA is the only carbon exchange offering both centralized and decentralized access from a single platform, enabling institutions, DAOs, and retail investors to trade carbon credits with their preferred custody model—all backed by bilateral negotiation (Marketplace v2) for transparent project-based trading."*

**Market Capture:**
- **CPX:** Regulated markets (Indonesia IDXCarbon, Brazil B3, compliance buyers)
- **DPX:** DeFi markets (DAO treasuries, crypto-native projects, permissionless access)
- **Phase 2:** Unified liquidity pool bridging both ecosystems

**Total Addressable Market:** 100% of carbon credit demand, regardless of custody preference.

---

# Part II: Current CPX Architecture

## 12. Authentication & User Management

**Current Implementation (CPX):**
- Username/password authentication (SHA256-hashed credentials, SQL Server)
- JWT-based session management (HTTP-only cookies)
- Multi-factor authentication (email/SMS OTP)
- Cognito integration for select deployments
- IP whitelisting for enhanced security

**Key Components:**
- `packages/wa-api/services/user/user.service.ts` – Login handlers
- `packages/utils-server/src/services/auth.service.ts` – Auth middleware
- `packages/web/src/pages/Login.tsx` – User-facing React login

---

## 13. Custody Model – STMv2 Centralized Ledger

**Current Implementation:**
- Users **do not hold private keys**
- ACX-controlled admin accounts execute all blockchain transactions
- Pre-generated addresses (5000 per deployment) assigned to users
- Balances maintained in **STMv2 smart contract** (`STMv2.sol`)
- All asset movements occur on-ledger via admin-signed transactions

**STMv2 Contract (Security Token Manager v2):**
- `mintSecTokenBatch()` – Mints FCTs to ledger accounts
- `fundOrWithdraw()` – Credits/debits fiat currency
- `transferOrTrade()` – Executes bilateral asset transfers
- `getLedgerEntry()` – Retrieves account balances

**Database Integration:**
- SQL Server: User-to-address mappings (`user_account`)
- MongoDB: Blockchain indexer for fast ledger state queries
- RabbitMQ: Transaction queue for async processing

**Network Migration:**
- Current: Polygon PoS
- Target: **ACXNET** (AvaLabs Custom L1)
- Benefits: Dedicated throughput, zero-gas for users, customizable economics
- Strategy: Snapshot → replay → **hard cutover** (Polygon decommissioned simultaneously)

---

## 14. Asset Lifecycle – FCT Minting (CPX)

**Current Workflow:**

1. **Project Onboarding:** Developer submits ERPA → stored in `carbon_project_apx` table
2. **FCT Asset Creation:** Admin creates asset type → registered in `x_asset` → trading pair created
3. **Minting to Ledger:** Admin triggers mint → `Ledger.mintBatch()` → FCTs appear in project owner's **ledger account** (not transferable to external wallets)

**Key Point:** FCTs exist only on STMv2 ledger, not as true ERC-20s.

---

## 15. Payment & Settlement – Fiat USD (CPX)

**Current Workflow:**

1. **Fiat Deposit:** User bank wire → admin verifies → `fundOrWithdraw()` credits USD on-ledger
2. **MBv2 Trading:** Seller lists project → buyer submits request → negotiation → acceptance
3. **Settlement:** `mb2.executeTrade` → `transferOrTrade()` → atomic USD ↔ FCT swap on-ledger
4. **Fiat Withdrawal:** Admin debits ledger → initiates bank wire

**Key Point:** USD exists as ledger balances, not stablecoins. ACX holds custody.

---

## 16. Marketplace v2 (MBv2) – Bilateral Trading

**Architecture:**
- TypeScript/Node.js service (`mb2.service.ts`)
- Seller workflow: List projects → receive requests → accept/reject/counter
- Buyer workflow: Browse listings → submit requests → negotiate → confirm
- Settlement: `mb2.executeTrade` triggers bilateral settlement

**vs. Spot Market:**
- **MBv2:** Project-based bilateral negotiation (used by CPX/DPX)
- **CLOB Spot:** Contract-based automatic matching (not used for FCT)

---

# Part III: Target DPX Architecture

## 17. Wallet-Based Authentication (DPX)

**Proposed Implementation:**

**Frontend:**
- WalletConnect / RainbowKit UI for wallet connection
- Support Metamask, Core Wallet, WalletConnect, hardware wallets
- Display connected address as identifier

**Backend:**
- SIWE (Sign-In with Ethereum) standard
- User signs nonce message → backend verifies signature → issues JWT
- Map wallet address → user entity (auto-create on first login)
- Remove password hashing (authentication is cryptographic)

**Feature Toggle:**
```typescript
// auth.service.ts
if (FEATURE_DPX_MODE) {
  return await authenticateWallet(req);
} else {
  return await authenticateCredentials(req);
}
```

---

## 18. ERC-20 FCT Tokens (DPX)

**Implementation:**

**FctFactory Contract:**
Manages project lifecycle (propose → approve/deny) and deploys unique ERC-20 per project-vintage with embedded metadata standard.

**Minting Process (DPX):**
1. Developer calls `FctFactory.proposeProject(name, symbol, supply, metadata)`
2. Multisig (Phase 1) or DAO (Phase 2) reviews proposal
3. `approveProject(projectId)` deploys FutureCarbonToken ERC-20
4. Tokens minted to developer's wallet (not ledger)
5. Token address stored in database for reference

**DeFi Composability:**
- Uniswap-style DEXs (Trader Joe, Pangolin)
- Lending protocols (Aave, Benqi)
- Yield aggregators (Yield Yak)
- Cross-chain bridges (LayerZero, Axelar)

---

## 19. USDC Payment Rails (DPX)

**Implementation:**

**Asset Configuration:**
- USDC on Avalanche: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`
- USDT alternative: `0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7`

**Balance Checks:**
```typescript
async function getWalletBalance(address: string, tokenAddress: string) {
  const avalancheProvider = new ethers.providers.JsonRpcProvider(
    'https://api.avax.network/ext/bc/C/rpc'
  );
  const erc20 = new ethers.Contract(tokenAddress, erc20Abi, avalancheProvider);
  return await erc20.balanceOf(address);
}
```

**Order Placement:**
Before submitting trade request acceptance, buyer approves USDC to SwapBox contract.

---

## 20. SwapBox Settlement (DPX)

**Implementation:**
Sellers create signed orders off-chain; buyers execute atomically on-chain:

1. **Seller:** Signs order off-chain (EIP-712) with terms (FCT amount, USDT amount, fee, expiry)
2. **DPX UI:** Displays order (no custody, just discovery)
3. **Buyer:** Submits transaction calling `SwapBox.swap()` with seller's signature
4. **Contract:** Verifies signature, checks nonce/expiry, atomically transfers tokens
5. **Result:** FCT → buyer, USDT → seller, fee → treasury/staking (stablecoin, all or nothing)

---

# Part IV: Implementation Specification

## 21. Codebase Refactoring Plan

### 21.1 Components Modified

| Component | CPX Function | DPX Function | Shared Logic |
|-----------|--------------|--------------|--------------|
| **Authentication** | Credentials | Wallet (SIWE) | Session management |
| **Marketplace** | MBv2 bilateral | MBv2 bilateral | 100% shared |
| **FCT Minting** | STMv2 ledger (ACXNET) | FctFactory deploy (Avalanche) | Project validation |
| **Listings** | Seller lists on MBv2 | Same | MBv2 engine |
| **Trade Requests** | Buyer submits | Same | MBv2 negotiation |
| **Balance Queries** | Ledger read (ACXNET) | ERC-20 read (Avalanche) | Display logic |
| **Settlement** | `transferOrTrade()` | SwapBox atomic | Order signature |

### 21.2 Frontend Changes (React/TypeScript)

**Modified:**
- `Login.tsx` – WalletConnect button (conditional)
- `Balances.tsx` – Wallet balances (Avalanche ERC-20)
- `TradeRequestForm.tsx` – USDC approval before acceptance

**New:**
- `SwapBoxDeposit.tsx` – Deposit/withdraw UI for settlement

### 21.3 Backend Changes (Node.js/Moleculer)

**Modified:**
- `auth.service.ts` – SIWE authentication
- `user.service.ts` – Wallet address mapping
- `mb2.service.ts` – SwapBox settlement flow

**New:**
- `swapbox.service.ts` – Monitor swaps, handle expirations
- `geofence.service.ts` – KYC/AML compliance checks

### 21.4 Smart Contracts (Solidity)

**New (Avalanche C-Chain):**
- `ACR.sol` – Governance token (1B supply, already deployed)
- `FctFactory.sol` – Project registry, proposal/approval, FCT deployment
- `SwapBox.sol` – Atomic swaps (AirSwap SwapERC20-based)
- `RedemptionVault.sol` – USDT distribution for mature projects
- `Staking.sol` – ACR staking with multi-token fee distribution (Phase 2)

**Existing (ACXNET):**
- `STMv2.sol` – Centralized ledger (unchanged, CPX-only)

### 21.5 Database Schema

**New Tables:**
- `user_wallet` – Wallet address mappings
- `swapbox_swap` – Swap status tracking
- `kyc_attestation` – Compliance data

**Modified Tables:**
- `x_asset` – Add `erc20_address`, `token_standard`, `network_id`
- `user_account` – Add `is_external_wallet` flag
- `user` – Add `kyc_level` enum

---

## 22. Network Deployment Strategy

### 22.1 ACXNET Custom L1 (CPX)

**Configuration:**
- Minimum 5 institutional validators
- Configurable gas schedule (subsidized for users)
- Private mempool (MEV protection)
- Dedicated block space (no public congestion)

**Migration from Polygon:**
1. Snapshot Polygon state (all balances, assets, trades, spot market data)
2. Deploy STMv2 to ACXNET
3. Replay state
4. **Hard cutover:** Switch traffic, decommission Polygon same day
5. Monitor 24/7 for 1 week

### 22.2 Avalanche C-Chain (DPX)

**Configuration:**
- Deploy ACR (already deployed), FctFactory, SwapBox to mainnet (43114)
- Testnet: Avalanche Fuji (43113)
- Grant `OWNER` role to Safe multisig treasury
- Integrate indexer for event tracking

---

## 23. Compliance Implementation

### 23.1 KYC Database Schema

```sql
CREATE TABLE kyc_attestation (
    id INT PRIMARY KEY IDENTITY,
    wallet_address NVARCHAR(42) NOT NULL,
    kyc_level NVARCHAR(20) NOT NULL,
    country_code NVARCHAR(2),
    ip_address NVARCHAR(45),
    attestation_data NVARCHAR(MAX),
    verified_at_utc DATETIME,
    verified_by INT,
    expiry_utc DATETIME,
    created_at_utc DATETIME DEFAULT GETUTCDATE()
);
```

### 23.2 Geofencing Service

```typescript
async function validateAccess(walletAddress: string, ipAddress: string) {
  const geoData = await geolocate(ipAddress);
  
  if (SANCTIONED_COUNTRIES.includes(geoData.country)) {
    throw new ForbiddenError('Region not supported');
  }
  
  if (RESTRICTED_COUNTRIES.includes(geoData.country)) {
    const kycLevel = await getKycLevel(walletAddress);
    if (kycLevel < KYC_LEVEL_DOCUMENT_VERIFIED) {
      throw new ForbiddenError('Enhanced KYC required for your region');
    }
  }
  
  return { allowed: true, kycRequired: geoData.kycTier };
}
```

---

## 24. Performance & Scalability Analysis

### 24.1 Network Comparison

| Metric | ACXNET (CPX) | Avalanche (DPX) |
|--------|--------------|-----------------|
| **Finality** | <1 second | <2 seconds |
| **Throughput** | 10K+ TPS (configurable) | 4,500 TPS |
| **Gas (User)** | $0.00 (subsidized) | ~$0.42 |
| **Gas (ACX)** | <$0.01 per tx | $0 (users pay) |
| **Validator Set** | ACX + institutional partners | Public Avalanche validators |
| **MEV Protection** | Private mempool | Standard |

### 24.2 Settlement Throughput

**CPX:** ~100 settlements/sec (limited by admin signing)  
**DPX:** Unlimited (parallel user-initiated SwapBox transactions)

**Conclusion:** DPX scales horizontally via decentralized settlement; CPX optimizes for zero user friction.

---

## 25. Gas Cost Economics

### 25.1 Avalanche C-Chain (DPX)

| Operation | Gas Used | Cost @ 25 nAVAX |
|-----------|----------|-----------------|
| Atomic Swap (SwapBox.swap) | ~50,000 | **$0.15** |
*Assumes AVAX = $30*

### 25.2 Network Comparison

| Network | Cost | Finality | Throughput |
|---------|------|----------|------------|
| **Avalanche** | **$0.15** | **<2 sec** | **4,500 TPS** |
| Polygon | $0.10 | ~30 sec | ~7,000 TPS |
| Arbitrum | $2.00 | ~15 min | ~40,000 TPS |
| Ethereum | $50+ | ~12 min | ~15 TPS |

**Why Avalanche:**
- Sub-second finality (superior to Polygon/Arbitrum)
- Competitive gas costs
- Subnet architecture (future ACXNET integration)
- Strong DeFi ecosystem
- Institutional adoption (Ava Labs partnerships)

---

# Part V: Deployment Timeline

## 26. Phase-by-Phase Roadmap

**Target:** Phase 2 cross-mode liquidity by end Q2 2026 (June 30, 2026).

### Phase 1A – Foundation (Nov 2025: 4 weeks)

**Smart Contracts:**
- Deploy FctTokenFactory, SwapBox to Avalanche Fuji testnet (43113)
- Comprehensive test suite (Hardhat with Avalanche fork)
- Begin security audit (Ava Labs-recommended: Halborn, Trail of Bits)

**ACXNET Planning:**
- Design subnet configuration (validator set, gas economics)
- Plan Polygon → ACXNET state migration
- Set up ACXNET testnet environment

**Backend:**
- Implement SIWE authentication
- Add Avalanche RPC integration
- Create `swapbox.service.ts`
- Add feature toggle framework with network-aware routing

**Database:**
- Create `user_wallet`, `swapbox_swap`, `kyc_attestation` tables
- Migrate `x_asset` to support `erc20_address`, `network_id`

**Deliverable:** Fully functional DPX testnet + ACXNET migration plan

---

### Phase 1B – Development Sprint (Dec 2025: 4 weeks)

**Frontend:**
- WalletConnect integration (Avalanche C-Chain)
- SwapBox deposit UI with AVAX gas estimation
- Wallet balance displays (USDC on Avalanche)
- USDC approval flow for MBv2 trade requests

**Backend:**
- Refactor `apx.mintFctTokens` for dual-network (Avalanche + ACXNET)
- Refactor `mb2.executeTrade` to support SwapBox
- SwapBox event monitoring in indexer (Avalanche sync)
- ACXNET RPC integration

**Testing:**
- End-to-end: Wallet login → mint FCT → list project → negotiate → deposit → settle
- Integration: CPX (ACXNET testnet) + DPX (Avalanche Fuji) side-by-side
- Load testing: 1000+ concurrent orders across both networks

**Security:**
- Complete external audit
- Remediate critical/high findings
- Launch bug bounty ($50K rewards)

**Deliverable:** Production-ready codebase for both networks

---

### Phase 1C – Network Launches (Jan-Feb 2026: 8 weeks)

**ACXNET Launch + Polygon Decommission (Weeks 1-4):**
- Deploy ACXNET subnet validators (min 5 institutional partners)
- Deploy STMv2 ledger to ACXNET
- Snapshot Polygon ACX/CPX state (ledger balances, assets, trades, spot market)
- Migrate ACX/CPX platform to ACXNET (includes CPX marketplace + spot/CLOB)
- **Hard cutover:** Switch all traffic to ACXNET, decommission Polygon simultaneously
- Monitor 24/7 for 1 week post-cutover

**Avalanche Mainnet Launch (Weeks 5-8):**
- Deploy FctTokenFactory + SwapBox to Avalanche C-Chain mainnet
- Configure backend with mainnet addresses
- Deploy indexer for Avalanche event tracking
- Launch DPX with **handpicked projects and buyers familiar with DeFi/crypto primitives**
- Monitor swap completion rates (target: >95%)

**Operations:**
- Grafana dashboards for both networks (ACXNET + Avalanche)
- Alerts: expired swaps, failed txs, network congestion
- Train support team on dual-network troubleshooting

**Deliverable:** Both CPX (ACXNET) and DPX (Avalanche) live in production

---

### Phase 1D – Production Scale (Mar-Apr 2026: 8 weeks)

**Rollout:**
- Expand DPX to additional crypto-native projects and buyers
- All ACX/CPX entities fully operational on ACXNET (Polygon decommissioned in Phase 1C)
- Launch $ACR token staking for swap fee discounts
- Implement tiered KYC/AML framework (self-attestation → document verification)
- Deploy geofencing controls per legal/operational requirements

**Optimization:**
- Investigate market appetite for DEX liquidity pools (e.g., Trader Joe FCT/USDC pairs)
- Add USDT, DAI support on Avalanche
- Batch swap settlement (reduce gas 30%)
- Enable Core Wallet, Rabby Wallet support

**Performance Targets:**
- DPX: <$1 gas per swap
- CPX: <$0.01 backend cost (user pays $0)
- 1,000+ active DPX wallets
- $15M+ USDC volume

**Deliverable:** Scaled production ready for Phase 2

---

### Phase 2 – Cross-Mode Bridge (May-Jun 2026: 8 weeks)

**Goal:** Enable seamless trading between CPX (ACXNET ledger) and DPX (Avalanche ERC-20).

**Architecture:**
1. **Bridge Contract:** Lock FCT ERC-20 on Avalanche → unlock on ACXNET ledger (and vice versa)
2. **Unified Order Book:** Matching engine matches CPX bids with DPX asks transparently
3. **Cross-Chain Messaging:** Avalanche Warp Messaging or Axelar
4. **Market Makers:** $ACR rewards for cross-mode liquidity

**Technical Challenges:**
- Cross-L1 message passing
- Atomic settlement guarantees
- Liquidity balancing

**Deliverable (June 30, 2026):** Unified liquidity pool, CPX ↔ DPX interoperability

**Success Metric:** >$50M combined TVL across ACXNET + Avalanche

---

# Part VI: Smart Contract Specifications

## 27. SwapBox Contract (Complete Implementation)

**Full Solidity code available in [AirSwap Github](https://github.com/airswap/airswap-protocols/blob/develop/source/swap-erc20/contracts/SwapERC20.sol)**

### 27.2 Key Functions

**Configuration (ACX backend only):**
```solidity
function configureSwap(
    address buyer,
    address seller,
    address buyerAsset,
    uint256 buyerAmount,
    address sellerAsset,
    uint256 sellerAmount,
    uint256 expiryTimestamp
) external onlyRole(CONFIGURATOR_ROLE) returns (uint256 swapId);
```

**Deposits (users):**
```solidity
function depositBuyerAsset(uint256 swapId) external nonReentrant;
function depositSellerAsset(uint256 swapId) external nonReentrant;
```

**Withdrawals (users, after both deposited):**
```solidity
function withdrawBuyerAsset(uint256 swapId) external nonReentrant;
function withdrawSellerAsset(uint256 swapId) external nonReentrant;
```

**Cancellation (after expiry):**
```solidity
function cancelSwap(uint256 swapId) external nonReentrant;
```

### 27.3 Security Features

- **ReentrancyGuard:** Prevents reentrancy attacks
- **SafeERC20:** Safe token transfer wrappers
- **AccessControl:** Role-based permissions (configurator, pauser)
- **Pausable:** Emergency stop mechanism
- **Time-bounded:** Automatic refunds after expiry

**Audit Requirements:**
- External audit by tier-1 firm (Halborn, Trail of Bits)
- Bug bounty program ($100K for critical vulnerabilities)
- Minimum 4 weeks testnet operation

---

## 28. FctTokenFactory Contract

```solidity
interface IFctTokenFactory {
    function createFctToken(
        string memory name,
        string memory symbol,
        address projectOwner,
        uint256 initialSupply,
        Metadata memory metadata
    ) external returns (address tokenAddress);
}

struct Metadata {
    string projectId;
    uint256 vintageYear;
    string registry;
    string methodology;
    bool corsiaEligible;
    bool article6Authorized;
}
```

**Usage:**
Each FCT project-vintage gets unique ERC-20 contract with embedded compliance metadata.

---

# Part VII: Comparative Analysis

## 29. CPX vs. DPX Side-by-Side

*Detailed comparison available in `src/CPX-vs-DPX-Technical-Comparison.md`*

### 29.1 Authentication

| Feature | CPX | DPX |
|---------|-----|-----|
| **Method** | Username/password (SHA256) | Wallet signature (SIWE) |
| **Session** | JWT cookies | JWT tied to wallet address |
| **MFA** | Email/SMS OTP | Wallet-native (Ledger, Trezor) |
| **Recovery** | Password reset | Seed phrase (user responsibility) |
| **Code** | `user.service.ts::login()` | `wallet-auth.service.ts::loginWithWallet()` |

### 29.2 Asset Custody

| Feature | CPX | DPX |
|---------|-----|-----|
| **Network** | ACXNET | Avalanche C-Chain |
| **Storage** | STMv2 ledger | User wallets (ERC-20) |
| **Private Keys** | ACX admin accounts | Users (Metamask, Core Wallet) |
| **Standard** | Custom ledger entries | ERC-20 (OpenZeppelin) |
| **Transferability** | Platform-only | Global (any EVM wallet/DEX) |
| **Composability** | Platform-only | Avalanche DeFi (Trader Joe, Aave, Benqi) |

### 29.3 Settlement

| Feature | CPX | DPX |
|---------|-----|-----|
| **Method** | `transferOrTrade()` atomic swap | SwapBox bilateral escrow |
| **Signer** | ACX admin | Buyer + seller (4 txs) |
| **Trigger** | Seller accepts on MBv2 → auto-settle | Seller accepts → users deposit |
| **Finality** | <1 second | ~4 seconds (4 transactions) |
| **Recovery** | Database rollback | Auto-refund after 24h expiry |
| **Custody** | ACX controls ledger | SwapBox holds escrow |

### 29.4 User Experience

| Aspect | CPX | DPX |
|--------|-----|-----|
| **Setup** | Register → email verify → login | Connect wallet (instant) |
| **Learning Curve** | Familiar (traditional exchange) | Requires wallet knowledge |
| **Trading** | MBv2 bilateral negotiation | Same (MBv2) |
| **Deposit Time** | 1-3 days (bank wire) | Instant (if USDC on Avalanche) |
| **Settlement** | Instant after acceptance | 4-step (deposit USDC → deposit FCT → withdraw each) |
| **Settlement Time** | <1 second | <5 minutes typical |

---

## 30. Shared Infrastructure

**100% Shared (No Changes):**
- Marketplace v2 (MBv2) listing and negotiation
- Project management and validation
- Entity permission graph
- Market data and analytics

**Not Used for CPX/DPX:**
- C# matching engine (OrderMatcher)
- Order Management System (OMS)
- Spot/CLOB trading APIs

These components serve **contract-based trading** (CET, GNT), not project-based FCT trading.

---

# Part VIII: Risk Assessment & Mitigation

## 31. Identified Risks & Responses

### 31.1 Smart Contract Risk

**Threat:** SwapBox bugs could lock user funds

**Mitigation:**
- External security audit (Trail of Bits or OpenZeppelin)
- $100K bug bounty program
- Emergency pause mechanism (admin-controlled)
- Gradual rollout (start with $1M TVL cap)
- 4+ weeks testnet operation before mainnet

---

### 31.2 UX Complexity Risk

**Threat:** Non-crypto users confused by wallets

**Mitigation:**
- Launch DPX with **handpicked projects and buyers familiar with DeFi/crypto primitives**
- In-app wallet setup guides (video tutorials)
- Fallback to CPX mode for users without wallets
- 24/7 support chat specialized in wallet troubleshooting
- Social recovery options (Argent, Safe{Wallet})

---

### 31.3 Liquidity Fragmentation Risk

**Threat:** CPX and DPX liquidity pools separate, reducing depth

**Mitigation:**
- Phase 2 cross-mode bridge unifies liquidity
- Market maker incentives ($ACR token rewards)
- Unified order book (both user types see same listings)

---

### 31.4 Regulatory Risk

**Threat:** Some jurisdictions prohibit non-custodial exchanges

**Mitigation:**
- DPX launched with handpicked crypto-native participants initially
- Tiered KYC framework (self-attestation → full document verification)
- Geofencing via IP-based detection + sanctions screening
- Legal review per market before broader activation
- CPX remains available in all markets regardless

---

### 31.5 Dual-Network Complexity

**Threat:** Operating on two L1s increases operational burden

**Mitigation:**
- Unified codebase with network-aware routing
- Comprehensive monitoring dashboards for both chains
- Dedicated support training for dual-network scenarios
- Feature toggle allows instant mode switching

---

### 31.6 ACXNET Subnet Launch Risk

**Threat:** Custom L1 deployment may encounter unforeseen technical challenges

**Mitigation:**
- Ava Labs partnership for technical support
- Extensive testnet period (Phases 1A-1B)
- Validator onboarding (institutional partners)
- Fallback: Parallel Polygon operation during migration window

---

### 31.7 Compressed Timeline Risk

**Threat:** 6-month delivery window leaves limited buffer

**Mitigation:**
- Start Phase 1A immediately (November 2025)
- Parallel development streams where possible
- Pre-approved contingency: Phase 2 can extend to mid-July 2026 if needed

---

## 32. Success Metrics & KPIs

### 32.1 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Swap success rate | >95% | SwapBox completed / configured |
| Settlement latency (DPX) | <5 minutes | Time from both deposits to both withdrawals |
| Gas cost (DPX) | <$1 per swap | Average Avalanche gas cost |
| ACXNET uptime | >99.9% | Network availability |
| STMv2 finality | <1 second | Block confirmation time |

### 32.2 Business Metrics

| Metric | Target | Timeline |
|--------|--------|----------|
| Active DPX wallets | 1,000+ | End Q1 2026 |
| USDC volume (SwapBox) | $15M+ | Q1 2026 |
| Projects onboarded (DPX) | 50+ | End Q1 2026 |
| Polygon → ACXNET cutover | 100% | Phase 1C (Feb 2026) |
| Phase 2 bridge launch | Complete | June 30, 2026 |

### 32.3 Operational Metrics

| Metric | Target |
|--------|--------|
| Code duplication (CPX/DPX) | <10% |
| Mode toggle time (new entity) | <1 hour |
| Rollback time (if critical bug) | <2 hours |
| Security incidents | Zero critical |
| Support tickets (wallet issues) | <5% |

---

# Part IX: Economic Model & Token Utility

## 33. $ACR Token Integration

### 33.1 Core Utility Functions

**0. Marketplace Access (Burn Mechanism):**
Burn $ACR to gain project listing access on CPX & DPX marketplaces. Anti-spam mechanism creating constant burn demand from project owners.

**DPX-Specific Utility:**

1. **Swap Fee Discounts:** Stake $ACR → reduce SwapBox gas costs by 50%
2. **Governance Rights:** Vote on:
   - Supported stablecoins (USDC, USDT, DAI)
   - Chain deployments (future multi-chain)
   - KYC policy tiers (compliance framework evolution)
3. **Liquidity Mining:** Earn $ACR by providing FCT/USDC liquidity on Avalanche DEXs
4. **Premium Features:** Access to advanced DeFi tools (limit orders, auto-compounding, portfolio analytics)

### 33.2 Buyback & Burn Mechanism

Platform revenues from **both CPX and DPX** flow into unified buyback pool:

**Revenue Sources:**
- CPX: Trading fees from STMv2 ledger settlements (ACXNET)
- DPX: Swap configuration fees (paid in $ACR)
- Project listing fees (burned $ACR for marketplace access)
- KYC verification fees (optional revenue stream)

**Buyback Flow:**
```
Combined revenues → Open market $ACR buyback → Burn
```

**Result:** Token value accrues from total platform throughput (CPX + DPX), not mode-specific activity. Deflationary pressure increases as project listings and swap volumes grow.

---

## 34. Competitive Positioning

### 34.1 Market Differentiation

**ACXRWA Unique Value:**

> *"ACXRWA is the only carbon exchange offering both centralized and decentralized access from a single platform, enabling institutions, DAOs, and retail investors to trade carbon credits with their preferred custody model—all backed by bilateral negotiation (Marketplace v2) for transparent project-based trading."*

**vs. Competitors:**
- **vs. Traditional Carbon Exchanges:** DPX offers DeFi composability
- **vs. Pure DEXs:** CPX offers institutional custody + zero gas fees
- **vs. Fragmented Platforms:** Unified liquidity across both modes (Phase 2)

### 34.2 Market Capture Strategy

**CPX Markets:**
- Regulated jurisdictions (Indonesia IDXCarbon, Brazil B3)
- Institutional compliance buyers
- Corporate sustainability teams
- Governments (Article 6 transactions)

**DPX Markets:**
- DAO treasuries (MakerDAO, Gitcoin)
- Crypto-native project developers
- DeFi-savvy retail investors
- Permissionless global access

**Phase 2 (Unified):**
- Cross-mode liquidity pool
- 100% TAM (total addressable market) regardless of custody preference

---

# Appendices

## Appendix A: Network Configuration Reference

### A.1 Avalanche C-Chain (DPX)

**Mainnet:**
- Chain ID: 43114
- RPC: `https://api.avax.network/ext/bc/C/rpc`
- Explorer: `https://snowtrace.io`

**Testnet (Fuji):**
- Chain ID: 43113
- RPC: `https://api.avax-test.network/ext/bc/C/rpc`

**Contract Addresses (Mainnet):**
- USDC: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`
- USDT: `0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7`
- SwapBox: TBD (Phase 1C deployment)
- FctTokenFactory: TBD (Phase 1C deployment)

### A.2 ACXNET Custom L1 (CPX)

**Configuration:**
- Chain ID: TBD (subnet deployment)
- RPC: `https://rpc.acxnet.io` (planned)
- Explorer: `https://explorer.acxnet.io` (planned)

**Validator Set:**
- Minimum 5 institutional partners
- ACX-operated nodes
- Configurable consensus parameters

**STMv2 Contract:**
- Address: TBD (migrated from Polygon)
- Deployment: Phase 1C (Jan 2026)

---

## Appendix B: Feature Toggle Configuration

### B.1 Environment Variables

```bash
# DPX Mode (Avalanche C-Chain)
FEATURE_DPX_MODE=true
DPX_NETWORK_ID=43114
DPX_TESTNET_ID=43113
DPX_RPC_URL=https://api.avax.network/ext/bc/C/rpc
DPX_EXPLORER=https://snowtrace.io

# Smart Contract Addresses (Avalanche)
SWAPBOX_ADDRESS_AVALANCHE=0x...
FCT_FACTORY_ADDRESS_AVALANCHE=0x...
USDC_ADDRESS_AVALANCHE=0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
USDT_ADDRESS_AVALANCHE=0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7

# CPX Mode (ACXNET)
FEATURE_DPX_MODE=false
CPX_NETWORK_ID=ACXNET_CHAIN_ID
CPX_RPC_URL=https://rpc.acxnet.io
CPX_EXPLORER=https://explorer.acxnet.io

# STMv2 Ledger (ACXNET)
STMV2_ADDRESS_ACXNET=0x...
ROOT_ACCOUNT_ACXNET=0x...

# Migration Config
POLYGON_SNAPSHOT_BLOCK=...
ACXNET_GENESIS_BLOCK=...
```

---

## Appendix C: Development Changelog

### C.1 Version History

**v1.0 → v1.1 (November 2025):**

**Network Changes:**
- DPX: Ethereum/Polygon/Arbitrum multi-chain → Avalanche C-Chain exclusive
- CPX: Remain on Polygon → Migrate to ACXNET custom L1

**Terminology:**
- ACXv2 → STMv2 (Security Token Manager v2)
- CPX → ACX/CPX (clarified as subsystem)
- ACXRWA token → $ACR token
- MB2 → MBv2 (Market Board v2)

**Timeline:**
- 12+ month gradual → 6-month aggressive
- Phase 2 target: June 30, 2026

**Content:**
- Added: Marketplace v2 (MBv2) bilateral negotiation clarification
- Added: KYC/AML tiered compliance framework
- Added: Geofencing strategy
- Added: $ACR marketplace access utility (burn to list)
- Removed: A/B testing references
- Removed: "Critical deadline" alarmist language
- Removed: All emojis (professional tone)

**Documents:**
- Combined: Executive Summary + Whitepaper Section → Whitepaper-ARR-Phase1.md
- New: SwapBox-Contract.md (complete Solidity)
- New: QUICK-REFERENCE.md (developer cheat sheet)

### C.2 Detailed Change Log

See `src/CHANGES-v1.1.md` for complete change-by-change documentation.

---

## Appendix D: Implementation Checklist

### D.1 Phase 1A (Nov 2025)

**Smart Contracts:**
- [ ] Deploy FctTokenFactory to Avalanche Fuji
- [ ] Deploy SwapBox to Avalanche Fuji
- [ ] Write comprehensive test suite (Hardhat)
- [ ] Initiate security audit

**CPX Migration:**
- [ ] Design ACXNET subnet (validators, gas, consensus)
- [ ] Plan state migration (snapshot strategy)
- [ ] Set up ACXNET testnet

**Backend:**
- [ ] Implement SIWE authentication
- [ ] Add Avalanche RPC integration
- [ ] Create `swapbox.service.ts`
- [ ] Add `geofence.service.ts` for compliance
- [ ] Feature toggle framework

**Database:**
- [ ] Create `user_wallet`, `swapbox_swap`, `kyc_attestation`
- [ ] Modify `x_asset`, `user_account`, `user`

### D.2 Phase 1B (Dec 2025)

**Frontend:**
- [ ] WalletConnect integration
- [ ] SwapBox deposit/withdraw UI
- [ ] Wallet balance displays
- [ ] USDC approval flow

**Backend:**
- [ ] Dual-network minting (`apx.mintFctTokens`)
- [ ] SwapBox settlement (`mb2.executeTradeSwapBox`)
- [ ] Avalanche indexer integration
- [ ] ACXNET RPC integration

**Testing:**
- [ ] End-to-end DPX flow
- [ ] End-to-end CPX (ACXNET testnet) flow
- [ ] Load testing (1000+ orders)

**Security:**
- [ ] Complete audit
- [ ] Remediate findings
- [ ] Launch bug bounty

### D.3 Phase 1C (Jan-Feb 2026)

**ACXNET (Weeks 1-4):**
- [ ] Deploy subnet validators
- [ ] Deploy STMv2 to ACXNET
- [ ] Snapshot Polygon
- [ ] Hard cutover + Polygon decommission
- [ ] 24/7 monitoring

**Avalanche (Weeks 5-8):**
- [ ] Deploy SwapBox + FctFactory (mainnet)
- [ ] Configure backend
- [ ] Deploy indexer
- [ ] Onboard handpicked participants
- [ ] Monitor swap rates

### D.4 Phase 1D (Mar-Apr 2026)

- [ ] Expand DPX to more crypto-native participants
- [ ] $ACR staking launch
- [ ] KYC framework deployment
- [ ] Geofencing implementation
- [ ] Investigate DEX liquidity appetite

### D.5 Phase 2 (May-Jun 2026)

- [ ] Deploy bridge contract (ACXNET ↔ Avalanche)
- [ ] Unified order book integration
- [ ] Cross-chain messaging (Warp/Axelar)
- [ ] Market maker program
- [ ] Go-live: June 30, 2026

---

## Appendix E: Code Organization

### E.1 Shared Modules (No Changes)

- `packages/wa-api/services/mb2/` – Marketplace v2 (100% shared)
- `packages/api/services/apx/` – Project management (95% shared)
- `packages/utils-server/entity-graph.ts` – Permissions (100% shared)
- `packages/api/services/carbon.service.ts` – Market data (100% shared)

### E.2 Mode-Specific Modules

**CPX Only (ACXNET):**
- `packages/api/fiat.service.ts` – Fiat deposits/withdrawals
- `packages/utils-server/ledger.ts` – STMv2 interactions

**DPX Only (Avalanche):**
- `packages/api/wallet-auth.service.ts` – SIWE authentication
- `packages/wa-api/services/swapbox.service.ts` – Swap configuration
- `packages/wa-api/services/fct-factory.service.ts` – ERC-20 deployment
- `packages/api/geofence.service.ts` – Compliance checks

**Shared with Conditional Logic:**
- `packages/api/user.service.ts` – Login routing
- `packages/wa-api/services/mb2/mb2.service.ts` – Settlement routing
- `packages/utils-server/balance.ts` – Balance queries

### E.3 Not Used for CPX/DPX

- `apps/OrderMatcher/` – C# matching engine (CLOB/spot only)
- `packages/oms/` – Order Management System (CLOB/spot only)

---

## Appendix F: Security Audit Scope

### F.1 Smart Contracts (Priority 1)

**SwapBox.sol:**
- Reentrancy protection verification
- Integer overflow/underflow checks
- Access control on `configureSwap()`
- Emergency pause mechanism
- Expiry timestamp validation
- Gas optimization review

**FctTokenFactory.sol:**
- ERC-20 standard compliance
- Metadata immutability
- Mint authorization
- Supply cap enforcement

**Third-Party Dependencies:**
- OpenZeppelin Contracts v5.0+ (up-to-date check)
- Slither/Mythril vulnerability scans

### F.2 Backend Services (Priority 2)

- Feature toggle logic (no bypasses)
- SIWE signature verification (replay attack prevention)
- SwapBox expiry monitoring (refund testing)
- Geofencing implementation (sanction list accuracy)

---

## Appendix G: Testing Strategy

### G.1 Unit Tests

```typescript
describe('Order Validation (Feature Toggle)', () => {
  it('validates CPX ledger balance', async () => {
    process.env.FEATURE_DPX_MODE = 'false';
    const result = await validateOrder(order);
    expect(result.balanceSource).toBe('ledger');
  });

  it('validates DPX wallet balance', async () => {
    process.env.FEATURE_DPX_MODE = 'true';
    const result = await validateOrder(order);
    expect(result.balanceSource).toBe('wallet');
  });
});
```

### G.2 Integration Tests

**CPX Flow (MBv2 Bilateral):**
```
Register → Deposit Fiat → Seller Lists Project → 
Buyer Submits Request → Negotiation → Acceptance → 
Auto-Settle (transferOrTrade on ACXNET)
```

**DPX Flow (MBv2 + SwapBox):**
```
Connect Wallet → Seller Lists Project (FCT ERC-20) → 
Buyer Submits Request → Negotiation → Acceptance → 
Configure SwapBox → Buyer Deposits USDC → Seller Deposits FCT → 
Both Withdraw
```

### G.3 Load Testing

- 1000+ concurrent orders across both networks
- 100+ simultaneous SwapBox deposits
- Network resilience under congestion

---

## Appendix H: Deployment Environments

### H.1 Development

- Local Avalanche fork (Hardhat)
- Local ACXNET testnet (Avalanche Network Runner)
- Mock KYC/geofencing services

### H.2 Staging

- Avalanche Fuji testnet (43113)
- ACXNET testnet subnet
- Full KYC/compliance integration

### H.3 Production

- Avalanche C-Chain mainnet (43114)
- ACXNET custom L1
- Production KYC providers (Chainalysis, Sumsub)

---

## Appendix I: Monitoring & Observability

### I.1 Grafana Dashboards

**ACXNET Monitoring:**
- Block production rate
- Transaction throughput
- Gas subsidy costs
- Validator health

**Avalanche Monitoring:**
- SwapBox deployment rate
- Swap completion percentage
- Average gas costs
- Failed transaction alerts

**MBv2 Metrics:**
- Project listings per day
- Trade request volume
- Negotiation success rate
- Settlement latency

### I.2 Alerts

- Expired SwapBox instances (refund required)
- Failed transactions (retry needed)
- Network congestion (gas spikes)
- Geofencing violations
- KYC verification backlogs

---

## Appendix J: Support & Documentation

### J.1 User Guides (To Be Created)

**For DPX Users:**
- "How to Connect Your Wallet (Metamask, Core Wallet)"
- "Understanding SwapBox Settlement"
- "Managing Gas Fees on Avalanche"
- "KYC Verification Levels Explained"

**For CPX Users:**
- "Trading on ACX/CPX (ACXNET)"
- "How Marketplace v2 (MBv2) Works"
- "Understanding Zero-Gas Trading"

### J.2 Admin Guides

- "Configuring CPX vs. DPX Mode"
- "Network-Specific Operations (ACXNET vs. Avalanche)"
- "Managing SwapBox Expirations"
- "KYC Tier Administration"

### J.3 API Documentation

**New Endpoints (DPX):**
- `POST /api/auth/wallet-login` – SIWE authentication
- `GET /api/balance/wallet/:address/:token` – Wallet balances
- `POST /api/mb2/configure-swap` – SwapBox configuration
- `GET /api/mb2/swap/:swapId` – Swap status
- `POST /api/compliance/kyc-attestation` – Submit KYC data

---

## Appendix K: External Dependencies

### K.1 Smart Contract Libraries

- OpenZeppelin Contracts v5.0+
- Hardhat / Foundry testing frameworks
- Avalanche Subnet EVM
- Slither / Mythril security scanners

### K.2 Frontend Libraries

- WalletConnect v2
- Wagmi / Viem (Ethereum + Avalanche)
- Core Wallet SDK (Avalanche native)
- RainbowKit (wallet UI)

### K.3 Backend Libraries

- ethers.js v6 (Avalanche RPC providers)
- TypeChain (contract type generation)
- Moleculer.js (microservices)
- Avalanche.js (subnet/C-Chain operations)

### K.4 Avalanche-Specific

- Avalanche Network Runner (local subnet testing)
- Subnet EVM (ACXNET custom L1)
- Avalanche Warp Messaging (Phase 2 bridge)
- Trader Joe SDK (DeFi integrations)

---

## Appendix L: Glossary

**ACXNET:** AvaLabs Custom Layer 1 blockchain for ACX/CPX platform (institutional-grade, zero-gas)

**CPX (Carbon Project Exchange):** Custodial marketplace subsystem of ACX centralized exchange

**DPX (Decentralized Project Exchange):** Non-custodial marketplace on Avalanche C-Chain

**FCT (Future Carbon Ton):** Tokenized forward carbon credit (1 FCT = 1 ton CO₂e future delivery)

**MBv2 (Marketplace v2):** Bilateral negotiation platform for project-based FCT trading

**SIWE (Sign-In with Ethereum):** Wallet-based authentication standard (EIP-4361)

**STMv2 (Security Token Manager v2):** Centralized ledger smart contract for CPX on ACXNET

**SwapBox:** Bilateral escrow smart contract for trustless DPX settlement on Avalanche

**$ACR:** ACXRWA platform utility token (burn for access, stake for discounts, earn via liquidity mining)

---

## Appendix M: Quick Reference

### M.1 Networks at a Glance

| Mode | Network | Chain ID | Gas (User) | Finality |
|------|---------|----------|------------|----------|
| DPX | Avalanche C-Chain | 43114 | ~$0.42 | <2 sec |
| CPX | ACXNET | TBD | $0.00 | <1 sec |

### M.2 Smart Contracts

| Contract | Network | Purpose |
|----------|---------|---------|
| STMv2.sol | ACXNET | CPX ledger (mint, fund, transfer) |
| SwapBox.sol | Avalanche | DPX bilateral escrow |
| FctTokenFactory.sol | Avalanche | Deploy ERC-20 FCTs |

### M.3 Timeline

| Phase | Dates | Key Deliverable |
|-------|-------|-----------------|
| 1A | Nov 2025 | Fuji testnet, ACXNET design |
| 1B | Dec 2025 | Development sprint, audit |
| 1C | Jan-Feb 2026 | ACXNET launch + Avalanche mainnet |
| 1D | Mar-Apr 2026 | Production scale |
| 2 | May-Jun 2026 | Cross-mode bridge (June 30) |

### M.4 API Endpoints (MBv2)

**Shared:**
- `GET /api/mb/orders` – List projects
- `POST /api/mb/order` – Create listing
- `POST /api/mb/trade-request` – Submit request

**DPX-Specific:**
- `POST /api/mb2/configure-swap` – Configure SwapBox
- `GET /api/mb2/swap/:swapId` – Swap status

---

## Appendix N: References

### N.1 Source Documents

All original markdown files preserved in `src/` directory:
- `src/Whitepaper-ARR-Phase1.md` – Whitepaper content
- `src/ARR-Phase1-DPX-Refactoring.md` – Complete technical spec
- `src/SwapBox-Contract.md` – Full Solidity implementation
- `src/CPX-vs-DPX-Technical-Comparison.md` – Detailed comparison
- `src/QUICK-REFERENCE.md` – Developer cheat sheet
- `src/UPDATE-SUMMARY.md` – Changelog
- `src/CHANGES-v1.1.md` – Detailed change log

### N.2 External Resources

**Avalanche:**
- Docs: https://docs.avax.network/
- Subnet EVM: https://github.com/ava-labs/subnet-evm
- Core Wallet: https://core.app/
- Snowtrace Explorer: https://snowtrace.io/

**DeFi Protocols:**
- Trader Joe: https://traderjoexyz.com/
- Aave (Avalanche): https://app.aave.com/
- Benqi: https://benqi.fi/

**Standards:**
- EIP-4361 (SIWE): https://eips.ethereum.org/EIPS/eip-4361
- ERC-20: https://eips.ethereum.org/EIPS/eip-20
- OpenZeppelin: https://www.openzeppelin.com/

---

# Conclusion

This Architecture Refactoring Roadmap delivers a comprehensive technical blueprint for transforming ACX's centralized Carbon Project Exchange into a dual-mode platform serving both institutional custodial (CPX on ACXNET) and DeFi-native non-custodial (DPX on Avalanche) markets.

**Key Achievements:**
- Single unified codebase (feature toggle architecture)
- Two optimized networks (ACXNET: zero-gas institutional | Avalanche: low-cost DeFi)
- Trustless settlement via SwapBox smart contract
- Comprehensive KYC/compliance framework
- Tiered marketplace access via $ACR token utility

**Phase 2 Vision:** Cross-mode liquidity bridge enabling seamless trading regardless of custody preference, positioning ACXRWA to capture 100% of carbon credit demand.

**Timeline:** 6-month rollout (Nov 2025 – Jun 2026) culminating in unified CPX ↔ DPX liquidity pool.

---

**Document Status:** Complete & Ready for Publication  
**Total Length:** ~80 pages  
**Classification:** Internal / Investor-Shareable

---

*End of Combined Technical Documentation*

