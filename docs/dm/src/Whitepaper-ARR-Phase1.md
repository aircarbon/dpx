# Architecture Refactoring Roadmap
## Phase 1 - Core DeFi Expansion/Refactoring

*For inclusion in ACXRWA White Paper – Section 7.5*

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

## Overview

The ACXRWA platform will evolve from the current **Carbon Project Exchange (CPX)** centralized architecture to support a parallel **Decentralized Project Exchange (DPX)** operating mode. This expansion will be delivered through a **single unified codebase** controlled by runtime feature toggles, enabling seamless deployment of both custodial (CPX) and non-custodial (DPX) variants across **two optimized blockchain networks** without code fragmentation.

**Network Strategy:**
- **DPX:** Deploys on **Avalanche C-Chain** for high-throughput DeFi operations
- **CPX:** Migrates to **ACXNET** (AvaLabs Custom Layer 1) for institutional-grade performance

**Key Principle:** *One platform, two custody models: interoperable institutional & retail markets*

---

## Architectural Transformation

### From Centralized to Dual-Mode

| Dimension | CPX (Current) | DPX (Target) |
|-----------|---------------|--------------|
| **Authentication** | Username/password | Metamask/WalletConnect (SIWE) |
| **FCT Custody** | ACX-controlled STMv2 ledger | User-controlled ERC-20 wallets |
| **Payment Rails** | Fiat USD (bank accounts) | USDC (on-chain stablecoin) |
| **Settlement** | Admin-signed atomic swap | SwapBox bilateral escrow |

### Core Technical Differentiators

**CPX (Custodial Exchange on ACXNET):**
- **CPX Context:** CPX is a subsystem of the wider ACX centralized exchange (includes spot/CLOB markets, custody, fiat rails)
- Ideal for **regulated markets** requiring oversight (Indonesia, Brazil)
- Deployed on **ACXNET** (AvaLabs Custom Layer 1) with dedicated validators
- ACX holds private keys; users never interact directly with blockchain
- Fiat on/off-ramps integrated (bank wires, payment processors)
- Instant settlement via STMv2 centralized ledger transactions
- **Zero gas fees** for users (ACX subsidizes validator rewards)
- Private mempool (MEV protection for institutional trades)

**DPX (Decentralized Protocol on Avalanche):**
- Serves **DeFi-native users** and permissionless global access
- Deployed on **Avalanche C-Chain** (Chain ID: 43114) for sub-second finality
- Users control private keys via Metamask, Core Wallet, WalletConnect
- USDC/USDT payments; users acquire stablecoins via CEX/DEX
- Trustless settlement via **SwapBox** smart contract escrow
- **Sub-$1 gas costs** (typically $0.42 per swap at standard gas prices)
- Integrates with Avalanche DeFi ecosystem (Trader Joe, Aave, Benqi)

---

## SwapBox: Trustless Bilateral Settlement

The **SwapBox** contract is the cornerstone innovation enabling DPX to eliminate ACX custody while maintaining exchange-grade reliability.

### Mechanism

```solidity
// Simplified SwapBox interface (see SwapBox-Contract.md for full implementation)
interface ISwapBox {
    function configureSwap(
        address buyer,
        address seller,
        address buyerAsset,     // USDC contract address
        uint256 buyerAmount,    // USDC amount
        address sellerAsset,    // FCT ERC-20 contract address
        uint256 sellerAmount,   // FCT amount
        uint256 expiryTimestamp
    ) external returns (uint256 swapId);

    function depositBuyerAsset(uint256 swapId) external;  // Buyer deposits USDC
    function depositSellerAsset(uint256 swapId) external; // Seller deposits FCT
    function withdrawBuyerAsset(uint256 swapId) external; // Buyer withdraws FCT
    function withdrawSellerAsset(uint256 swapId) external; // Seller withdraws USDC
    function cancelSwap(uint256 swapId) external;
    
    function getSwap(uint256 swapId) external view returns (Swap memory);
    function isReadyToSettle(uint256 swapId) external view returns (bool);
}
```

**Full implementation:** See `SwapBox-Contract.md` for complete Solidity code with multiple concurrent swaps support.

### Settlement Flow (Marketplace v2 - MBv2)

**ACXRWA uses Marketplace v2 (MBv2)** - a bilateral negotiation platform where sellers list projects and buyers negotiate directly.

1. **Project Listing:** Seller lists FCT project on MBv2 (price, quantity, criteria)
2. **Trade Request:** Buyer submits request with proposed terms
3. **Negotiation:** Counter-offers exchanged via MBv2 messaging
4. **Acceptance:** Seller accepts final terms → triggers settlement
5. **Swap Configuration:** Backend calls `configureSwap()` with agreed parameters (returns `swapId`)
6. **Buyer Deposits:** User approves USDC, calls `depositBuyerAsset(swapId)` → USDC escrowed
7. **Seller Deposits:** User approves FCT, calls `depositSellerAsset(swapId)` → FCT escrowed
8. **Ready to Settle:** Once both deposited, each party can withdraw counterparty's asset
9. **Withdrawals:**
   - Buyer calls `withdrawBuyerAsset(swapId)` → receives seller's FCT
   - Seller calls `withdrawSellerAsset(swapId)` → receives buyer's USDC
10. **Expiry Protection:** If one party fails to deposit before 24-hour deadline, either party can reclaim via `cancelSwap()`

**Key Features:**
- **Multiple Concurrent Swaps:** Contract supports 1000s of simultaneous swaps with unique IDs
- **Bilateral Negotiation:** MBv2 enables direct buyer-seller price discovery before swap configuration
- **Project Specificity:** Each swap tied to specific FCT project/vintage (not fungible contracts)

**Marketplace v2 vs. Spot Market:**
- **MBv2 (Used by CPX/DPX):** Bilateral negotiation, project-based FCT trading
- **CLOB Spot Market:** Anonymous matching engine, contract-based trading (CET, GNT) - not used for FCT in Phases 1-2 (possibly Phase 3)

### Security Features

- **Non-custodial:** ACX never holds user assets during settlement
- **Atomic completion:** Both parties receive assets simultaneously or neither does
- **Trustless:** Smart contract enforces rules; no trusted third party
- **Time-bounded:** Expired swaps auto-refund to prevent locked funds
- **Audited:** External security review by tier-1 blockchain audit firm

---

## True ERC-20 FCT Tokens

Unlike CPX where FCTs exist only as ledger entries, DPX mints **real ERC-20 tokens** to project owners' wallets.

### FctTokenFactory Contract

```solidity
// Simplified factory interface
interface IFctTokenFactory {
    function createFctToken(
        string memory name,        // e.g., "Carbon Removal 2025"
        string memory symbol,      // e.g., "FCT2025"
        address projectOwner,
        uint256 initialSupply,
        Metadata memory metadata   // Registry, vintage, methodology
    ) external returns (address tokenAddress);
}

struct Metadata {
    string projectId;
    uint256 vintageYear;
    string registry;         // Verra, Gold Standard, ART
    string methodology;
    bool corsiaEligible;
    bool article6Authorized;
}
```

### DeFi Composability (Avalanche Ecosystem)

ERC-20 FCTs on Avalanche C-Chain unlock ecosystem integrations impossible with centralized ledgers:

- **Trader Joe/Pangolin:** Liquidity pools for FCT/USDC trading on Avalanche's leading DEXs
- **Aave/Benqi:** Use FCTs as collateral for stablecoin loans on Avalanche lending protocols
- **Yield Yak:** Auto-compounding yield farming strategies for FCT holders
- **Cross-Chain Bridges:** Port FCTs to other EVM chains via LayerZero, Axelar
- **Avalanche Subnets:** Future integration with ACXNET for institutional liquidity

---

## Feature Toggle Architecture

### Single Codebase, Dual Behavior

The platform determines CPX vs. DPX behavior via environment configuration:

```typescript
// Environment variable
FEATURE_DPX_MODE=true  // or false

// Runtime decision logic
function authenticateUser(request) {
  if (config.FEATURE_DPX_MODE) {
    return authenticateWallet(request.signature, request.address);
  } else {
    return authenticateCredentials(request.username, request.password);
  }
}

function settleMatch(trade) {
  if (config.FEATURE_DPX_MODE) {
    return configureSwapBox(trade.buyer, trade.seller, trade.fctToken, ...);
  } else {
    return executeLedgerTransfer(trade.buyerAccount, trade.sellerAccount, ...);
  }
}
```

### Technical Benefits

**Efficiency:**
- ~50% reduction in code maintenance vs. separate platforms
- Shared business logic (Marketplace v2 negotiation, risk management, entity permissions)
- Unified test suite covers both modes

**Flexibility:**
- Enable DPX for select entities/regions via configuration
- Instant rollback to CPX if issues arise (toggle=false)
- Gradual rollout based on operational readiness

**Scalability:**
- CPX: Batched admin transactions reduce gas costs
- DPX: Parallel user settlements eliminate centralized bottleneck
- Horizontal scaling via decentralized architecture

---

## System Components & Changes

### Frontend (React/TypeScript)

**Modified Components:**
- `Login.tsx` – Add WalletConnect button (conditional on DPX mode)
- `Balances.tsx` – Display wallet balances instead of ledger balances
- `TradeRequestForm.tsx` – Add USDC approval step for MBv2 trade acceptance
- **New:** `SwapBoxDeposit.tsx` – UI for depositing assets to complete trades

### Backend (Node.js/Moleculer)

**Modified Services:**
- `auth.service.ts` – Add SIWE (Sign-In with Ethereum) authentication
- `user.service.ts` – Map wallet addresses to user entities
- `mb2.service.ts` – Add SwapBox settlement flow (listing/negotiation unchanged)
- **New:** `swapbox.service.ts` – Monitor swap status, handle expirations

### Smart Contracts (Solidity)

**New Deployments (Avalanche C-Chain):**
- `FctTokenFactory.sol` – Deploys ERC-20 FCT tokens per project-vintage
- `SwapBox.sol` – Bilateral escrow for trustless settlement
- `FctToken.sol` (per vintage) – Standard ERC-20 with carbon metadata

**Existing (CPX-only, ACXNET):**
- `STMv2.sol` – Centralized ledger (Security Token Manager v2)

### Database (SQL Server)

**New Tables:**
- `user_wallet` – Maps user IDs to wallet addresses
- `swapbox_swap` – Tracks swap status (Pending → Completed/Cancelled)
- `kyc_attestation` – Stores compliance data (geofencing, accreditation status)

**Modified Tables:**
- `x_asset` – Add `erc20_address` and `token_standard` columns
- `user_account` – Add `is_external_wallet` flag
- `user` – Add `kyc_level` enum (None, SelfAttestation, DocumentVerified)

---

## Marketplace v2: Project-Based Trading

**Context:** CPX and DPX operate on **Marketplace v2 (MBv2)**, a bilateral negotiation platform distinct from the C# matching engine (CLOB/spot market).

**Marketplace v2 Architecture:**
- **Project Listings:** Sellers list specific FCT projects (not fungible contract pools)
- **Bilateral Negotiation:** Direct buyer-seller price discovery via trade requests
- **Messaging System:** Counter-offers and terms negotiation
- **Settlement:** Triggered upon mutual acceptance (not automatic matching)

**Both CPX and DPX variants share:**
- Identical MBv2 listing and negotiation flows
- Project-based asset selection (vintage, registry, methodology filters)
- Counter-offer messaging system
- Entity permission validation

**Only settlement mechanism differs:**
- **CPX (ACXNET):** Admin signs `transferOrTrade` ledger transaction → instant settlement
- **DPX (Avalanche):** Backend configures SwapBox → users deposit assets → withdraw counterparty assets

**CLOB/Spot Market (C# Matching Engine):**
- Used for **contract-based trading** (CET, GNT fungible tokens)
- **Not used** for CPX/DPX project-based FCT trading in Phases 1-2
- Potential Phase 3+ integration if CLOB-style FCT trading is desired

This ensures **consistent negotiation and discovery** regardless of custody model, with settlement adapted to custodial (CPX) vs. non-custodial (DPX) requirements.

---

## Deployment Strategy

**Timeline:** 6-month rollout culminating in Phase 2 cross-mode liquidity by end Q2 2026 (June 30, 2026).

### Phase 1A – Foundation (Nov 2025: 4 weeks)

- Deploy SwapBox + FctTokenFactory to **Avalanche Fuji testnet** (Chain ID: 43113)
- Design **ACXNET custom L1** subnet configuration (validators, gas schedule)
- Implement SIWE authentication backend
- Begin security audit (Ava Labs-recommended: Halborn, Trail of Bits)

### Phase 1B – Development Sprint (Dec 2025: 4 weeks)

- Complete WalletConnect frontend integration (Avalanche C-Chain)
- Build SwapBox deposit UI with AVAX gas estimation
- Refactor backend for dual-network support (Avalanche + ACXNET)
- Load testing: 1000+ concurrent orders across both networks

### Phase 1C – Network Launches (Jan-Feb 2026: 8 weeks)

**ACXNET Custom L1 Deployment + Polygon Decommission (Weeks 1-4):**
- Deploy STMv2 ledger to ACXNET subnet
- Migrate ACX/CPX platform from Polygon to ACXNET (state snapshot + replay)
- **Hard cutover:** Decommission Polygon simultaneously with ACXNET go-live
- **Zero-gas experience** for CPX users (ACX subsidizes)

**Avalanche Mainnet Deployment (Weeks 5-8):**
- Deploy SwapBox + FctTokenFactory to Avalanche C-Chain
- Enable DPX mode for handpicked projects and buyers familiar with DeFi/crypto primitives
- Monitor swap completion rates (target: >95%)

### Phase 1D – Production Scale (Mar-Apr 2026: 8 weeks)

- Expand DPX to additional crypto-native projects and buyers on Avalanche C-Chain
- All ACX/CPX entities fully operational on ACXNET (Polygon decommissioned in Phase 1C)
- Investigate market appetite for DEX liquidity pools (e.g., Trader Joe FCT/USDC pairs)
- Launch $ACR token staking for swap fee discounts

### Phase 2 – Cross-Mode Liquidity Bridge (May-Jun 2026: 8 weeks)

- **Bridge Contract:** ACXNET ↔ Avalanche C-Chain for FCT wrapping
- **Unified Order Book:** CPX bids match DPX asks transparently
- **Cross-Chain Messaging:** Avalanche Warp Messaging or Axelar integration
- **Market Makers:** $ACR token rewards for cross-mode liquidity provision
- **Result:** Seamless trading between ACXNET STMv2 ledger and Avalanche ERC-20 FCTs

**Go-Live Date:** June 30, 2026

---

## Compliance & Access Control

### KYC/AML Framework for DPX

While DPX uses wallet-based login (no traditional account creation), compliance requirements remain critical for regulated carbon markets.

**Tiered Approach:**

**Level 0 – Wallet-Only Access (Browsing):**
- Connect wallet via Metamask/WalletConnect
- View project listings, market data
- No trading permitted

**Level 1 – Self-Attestation (Accredited Investors):**
- Complete on-platform questionnaire
- Attest to accredited investor status
- Geo-location verification (IP-based)
- Trading cap: $50K per project
- **Implementation:** Browser-based form, signed attestation stored with wallet address

**Level 2 – Document Verification (Institutional):**
- Upload identity documents (passport, utility bill)
- Corporate verification (business registration, beneficial ownership)
- Third-party KYC provider integration (Chainalysis, Elliptic, Sumsub)
- Unlimited trading
- **Implementation:** Integration with existing ACX KYC workflows

**Level 3 – Enhanced Due Diligence (Large Institutions):**
- Video verification call
- Source of funds documentation
- Enhanced AML screening
- Preferred pricing, priority support

### Geofencing Strategy

**Approach:**
- IP-based geolocation detection at wallet connection
- Restrict access from OFAC-sanctioned jurisdictions
- Regional compliance tiers (e.g., US: accredited investors only)
- Override mechanism for VPN false-positives (manual review)

**Implementation:**
```typescript
// services/compliance/geofence.service.ts
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

**Database Schema:**
```sql
-- KYC attestation tracking
CREATE TABLE kyc_attestation (
    id INT PRIMARY KEY IDENTITY,
    wallet_address NVARCHAR(42) NOT NULL,
    kyc_level NVARCHAR(20) NOT NULL, -- None, SelfAttestation, DocumentVerified, EnhancedDueDiligence
    country_code NVARCHAR(2),
    ip_address NVARCHAR(45),
    attestation_data NVARCHAR(MAX), -- JSON: questionnaire responses, document hashes
    verified_at_utc DATETIME,
    verified_by INT, -- Admin user ID if manual review
    expiry_utc DATETIME,
    created_at_utc DATETIME DEFAULT GETUTCDATE()
);
```

**Flexibility:**
- Legal and operational teams determine KYC requirements per jurisdiction
- Framework supports range from permissionless (self-attestation) to highly regulated (full KYC)
- Enforcement at smart contract level (optional): whitelist verified addresses

---

## Economic Model Integration

### $ACR Token Utility

**0. Access to CPX & DPX Project Marketplaces:** Burn $ACR to gain listing access as a Project to the marketplaces (anti-spam mechanism)

**DPX-Specific Utility:**

1. **Swap Fee Discounts:** Stake $ACR to reduce SwapBox gas costs by 50%
2. **Governance Rights:** Vote on supported stablecoins, chain deployments, KYC policy tiers
3. **Liquidity Mining:** Earn $ACR by providing FCT/USDC liquidity on Avalanche DEXs
4. **Premium Features:** Access to advanced DeFi tools (limit orders, auto-compounding)

### Buyback & Burn Mechanism

Platform revenues from **both CPX and DPX** flow into unified buyback pool:

- CPX: Trading fees from STMv2 ledger-based settlements (ACXNET)
- DPX: Portion of swap configuration fees (paid in $ACR)
- Project listing fees (burned $ACR for marketplace access)
- KYC verification fees (optional revenue stream)
- Combined revenues → open market $ACR buyback → burn

**Result:** Token value accrues from total platform throughput, not mode-specific activity.

---

## Risk Mitigation

### Smart Contract Risk

**Threat:** SwapBox bugs could lock user funds  
**Mitigation:**
- External audit by Trail of Bits or OpenZeppelin
- $100K bug bounty program
- Emergency pause function (admin-controlled)
- Gradual rollout starting with $1M TVL cap

### UX Complexity Risk

**Threat:** Non-crypto users confused by wallets  
**Mitigation:**
- Onboard handpicked projects and buyers familiar with DeFi primitives first
- In-app wallet setup guides with video tutorials
- Fallback to CPX mode for users without wallets
- 24/7 support chat specializing in wallet troubleshooting

### Liquidity Fragmentation Risk

**Threat:** CPX and DPX liquidity separate, reducing market depth  
**Mitigation:**
- Phase 2 cross-mode bridge unifies liquidity pools
- Market makers incentivized to provide liquidity across both modes
- Unified order book visible to both user types

### Regulatory Risk

**Threat:** Some jurisdictions prohibit non-custodial exchanges  
**Mitigation:**
- DPX launched with handpicked crypto-native participants initially
- Geofencing via IP + KYC verification tiers
- Legal review per market before broader DPX activation
- CPX remains available in all markets regardless
- Flexible KYC framework (self-attestation → full document verification) based on legal/operational requirements

---

## Success Metrics

**Technical:**
- Swap completion rate >95%
- Average settlement time <5 minutes
- Gas cost per swap <$1 (on Avalanche C-Chain)
- ACXNET uptime >99.9%

**Business:**
- 1,000+ active DPX wallets by end Q1 2026
- $15M+ USDC volume via SwapBox in Q1 2026
- 50+ handpicked projects onboarded to DPX
- Complete Polygon → ACXNET hard cutover during Phase 1C

**Operational:**
- Zero critical security incidents
- <2 hours rollback time if DPX mode disabled
- <5% user support tickets related to wallet issues
- <10% code duplication between CPX/DPX modes

---

## Conclusion: The Best of Both Worlds

Phase 1 ARR delivers a **unique competitive advantage** for ACXRWA:

**Institutional Trust (CPX):** Custodial option for regulated markets and traditional finance  
**DeFi Innovation (DPX):** Non-custodial protocol for crypto-native users  
**Unified Liquidity (Phase 2):** Seamless cross-mode trading via bridge  
**Single Codebase:** Operational efficiency without compromise  

**Market Positioning:**

> *"ACXRWA is the **only** carbon exchange offering both centralized and decentralized access from a single platform, enabling institutions, DAOs, and retail investors to trade carbon credits with their preferred custody model—all backed by bilateral negotiation (Marketplace v2) for transparent project-based trading."*

This dual-mode architecture positions ACXRWA to capture:
- **CPX:** Regulated markets (Indonesia IDXCarbon, Brazil B3, compliance buyers)
- **DPX:** DeFi markets (DAO treasuries, crypto investors, crypto-native projects)
- **Phase 2:** Unified global liquidity pool bridging both ecosystems

**Total Addressable Market:** 100% of carbon credit demand, regardless of custody preference.

---

## Technical Appendix: SwapBox Interface Reference

**Full Implementation:** See `SwapBox-Contract.md` for complete production-ready Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISwapBox
 * @notice Interface for SwapBox bilateral escrow contract
 * @dev Full implementation supports multiple concurrent swaps with unique IDs
 */
interface ISwapBox {
    enum SwapStatus { 
        None,              // Swap does not exist
        Pending,           // Configured, awaiting deposits
        BuyerDeposited,    // Buyer deposited, awaiting seller
        SellerDeposited,   // Seller deposited, awaiting buyer
        ReadyToSettle,     // Both deposited, ready for withdrawals
        Completed,         // Both parties withdrew
        Cancelled          // Expired and refunded
    }

    struct Swap {
        uint256 swapId;
        address buyer;
        address seller;
        address buyerAsset;        // USDC contract address
        uint256 buyerAmount;       // USDC amount (6 decimals)
        address sellerAsset;       // FCT ERC-20 contract address
        uint256 sellerAmount;      // FCT amount (18 decimals)
        SwapStatus status;
        uint256 expiryTimestamp;
        bool buyerDeposited;
        bool sellerDeposited;
        bool buyerWithdrew;
        bool sellerWithdrew;
        uint256 createdAt;
    }

    event SwapConfigured(
        uint256 indexed swapId,
        address indexed buyer,
        address indexed seller,
        address buyerAsset,
        uint256 buyerAmount,
        address sellerAsset,
        uint256 sellerAmount,
        uint256 expiryTimestamp
    );

    event BuyerDeposited(uint256 indexed swapId, address indexed buyer, address asset, uint256 amount);
    event SellerDeposited(uint256 indexed swapId, address indexed seller, address asset, uint256 amount);
    event BuyerWithdrew(uint256 indexed swapId, address indexed buyer, address asset, uint256 amount);
    event SellerWithdrew(uint256 indexed swapId, address indexed seller, address asset, uint256 amount);
    event SwapCompleted(uint256 indexed swapId);
    event SwapCancelled(uint256 indexed swapId, address cancelledBy);

    // Configuration (ACX backend only)
    function configureSwap(
        address buyer,
        address seller,
        address buyerAsset,
        uint256 buyerAmount,
        address sellerAsset,
        uint256 sellerAmount,
        uint256 expiryTimestamp
    ) external returns (uint256 swapId);

    // Deposits
    function depositBuyerAsset(uint256 swapId) external;
    function depositSellerAsset(uint256 swapId) external;

    // Withdrawals
    function withdrawBuyerAsset(uint256 swapId) external;
    function withdrawSellerAsset(uint256 swapId) external;

    // Cancellation
    function cancelSwap(uint256 swapId) external;
    
    // Queries
    function getSwap(uint256 swapId) external view returns (Swap memory);
    function getSwapCount() external view returns (uint256);
    function isReadyToSettle(uint256 swapId) external view returns (bool);
}
```

**Implementation Highlights:**
- **Multiple Concurrent Swaps:** Each swap has unique ID, supports 1000s of simultaneous swaps
- **Flexible Assets:** Works with any ERC-20 (FCT vintages, USDC, USDT, DAI)
- **Atomic Settlement:** Both parties deposit → both can withdraw (trustless)
- **Gas Optimized:** ~400K gas total per swap (~$0.42 on Avalanche C-Chain)
- **Security:** OpenZeppelin ReentrancyGuard, SafeERC20, AccessControl, Pausable

**Contract Source:** `SwapBox-Contract.md`

### Gas Cost Breakdown (Avalanche C-Chain)

| Action | Gas Used | Cost @ 25 nAVAX | Cost @ 50 nAVAX | Cost @ 100 nAVAX |
|--------|----------|-----------------|-----------------|------------------|
| Configure Swap | 120,000 | $0.09 | $0.18 | $0.36 |
| Deposit USDC | 80,000 | $0.06 | $0.12 | $0.24 |
| Deposit FCT | 80,000 | $0.06 | $0.12 | $0.24 |
| **Total per Trade** | **280,000** | **$0.21** | **$0.42** | **$0.84** |

*Assumes AVAX = $30, gas price 25-100 nAVAX (typical Avalanche C-Chain range)*

**Avalanche vs. Alternatives:**

| Network | Avg. Cost | Finality | Throughput |
|---------|-----------|----------|------------|
| **Avalanche C-Chain** | **$0.42** | **<2 seconds** | **4,500 TPS** |
| Polygon PoS | $0.10 | ~30 seconds | ~7,000 TPS |
| Arbitrum | $2.00 | ~15 min (L1) | ~40,000 TPS |
| Ethereum | $50+ | ~12 min | ~15 TPS |

**Why Avalanche:**
- **Sub-second finality** (faster than Polygon/Arbitrum)
- **Low gas costs** (~$0.42 typical, competitive with Polygon)
- **High throughput** (4,500 TPS on C-Chain)
- **Subnet architecture** enables future ACXNET integration
- **Robust DeFi ecosystem** (Trader Joe, Aave, Benqi)
- **Institutional adoption** (Ava Labs partnerships with traditional finance)

**ACXNET Custom L1 (CPX):**
- **User gas cost:** $0.00 (fully subsidized)
- **ACX backend cost:** <$0.01 per transaction
- **Benefit:** Institutional users experience zero blockchain friction, ideal for regulated markets

**Conclusion:** DPX on Avalanche offers **<$1 gas costs** with **institutional-grade finality**, making it economically viable even for small trades (<$100) while maintaining the performance required for high-frequency carbon trading.

---

*This section integrates with ACXRWA White Paper Section 7 (Technical Design), providing detailed architecture for the platform's dual-mode evolution.*

**Document Status:** Ready for whitepaper inclusion


