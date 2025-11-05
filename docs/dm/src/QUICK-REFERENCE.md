# CPX/DPX Architecture - Quick Reference Card

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

## Network Deployment

| Mode | Network | Chain ID | Purpose |
|------|---------|----------|---------|
| **DPX** | **Avalanche C-Chain** | 43114 (mainnet)<br>43113 (Fuji testnet) | Decentralized, non-custodial DeFi operations |
| **CPX** | **ACXNET Custom L1** | TBD | Centralized, custodial institutional exchange |

---

## Trading Platform

**CPX and DPX use:** **Marketplace v2 (MBv2)** - Bilateral Negotiation

| Feature | Description |
|---------|-------------|
| **Platform Type** | Bilateral negotiation (NOT CLOB matching) |
| **Seller Action** | Lists project with price, quantity, criteria |
| **Buyer Action** | Submits trade request with proposed terms |
| **Negotiation** | Counter-offers exchanged via messaging |
| **Settlement Trigger** | Seller accepts final terms |
| **Code** | `packages/wa-api/services/mb2/mb2.service.ts` |

**NOT Used:** C# matching engine (CLOB/spot market) - reserved for CET/GNT contract trading

---

## Settlement Mechanisms

### CPX (ACXNET - Centralized)

```
Seller Accepts Trade Request
  ↓
mb2.executeTrade()
  ↓
transferOrTrade() on ACXNET
  ↓
Atomic swap: USD ↔ FCT (single tx)
  ↓
Complete (<1 second)
```

**User Actions:** None (auto-settled by ACX backend)

### DPX (Avalanche - Decentralized)

```
Seller Accepts Trade Request
  ↓
mb2.executeTradeSwapBox()
  ↓
configureSwap() on Avalanche (creates swapId)
  ↓
Buyer: approve USDC + depositBuyerAsset(swapId)
  ↓
Seller: approve FCT + depositSellerAsset(swapId)
  ↓
Both deposited → ReadyToSettle
  ↓
Buyer: withdrawBuyerAsset() → gets FCT
Seller: withdrawSellerAsset() → gets USDC
  ↓
Complete (~4-5 min for 4 transactions)
```

**User Actions:** 4 transactions (2 deposits + 2 withdrawals)

---

## Smart Contracts

| Contract | Network | Purpose |
|----------|---------|---------|
| **STMv2.sol** | ACXNET | ACX/CPX centralized ledger (Security Token Manager v2: mint, fund, transfer) |
| **FctTokenFactory.sol** | Avalanche C-Chain | Deploy ERC-20 FCT tokens |
| **SwapBox.sol** | Avalanche C-Chain | Bilateral escrow settlement |
| **USDC** | Avalanche C-Chain | 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E |

**Full Implementation:** `SwapBox-Contract.md`

---

## Gas Costs

| Action | CPX (ACXNET) | DPX (Avalanche) |
|--------|--------------|-----------------|
| **FCT Mint** | $0 (ACX pays) | ~$0.50 (owner pays) |
| **Listing Project** | $0 | $0 (off-chain) |
| **Trade Request** | $0 | $0 (off-chain) |
| **Settlement** | $0 (ACX pays <$0.01) | ~$0.42 (users pay) |
| **Total User Cost** | **$0** | **~$0.42 per trade** |

*Avalanche gas assumes 50 nAVAX, AVAX=$30*

---

## Timeline

| Phase | Dates | Deliverable |
|-------|-------|-------------|
| **1A** | Nov 2025 (4w) | Avalanche Fuji testnet, ACXNET design |
| **1B** | Dec 2025 (4w) | Development sprint, security audit |
| **1C** | Jan-Feb 2026 (8w) | ACXNET launch + Avalanche mainnet |
| **1D** | Mar-Apr 2026 (8w) | Production scale, Polygon decommission |
| **2** | May-Jun 2026 (8w) | Cross-mode bridge (target: June 30, 2026) |

---

## Key Feature Toggles

```bash
# DPX Mode (Avalanche C-Chain)
FEATURE_DPX_MODE=true
DPX_NETWORK_ID=43114
DPX_RPC_URL=https://api.avax.network/ext/bc/C/rpc
SWAPBOX_ADDRESS_AVALANCHE=0x...
USDC_ADDRESS_AVALANCHE=0xB97E...

# CPX Mode (ACXNET)
FEATURE_DPX_MODE=false
CPX_NETWORK_ID=ACXNET_CHAIN_ID
CPX_RPC_URL=https://rpc.acxnet.io
STMV2_ADDRESS_ACXNET=0x...
```

---

## API Endpoints (MBv2)

### Shared (Both Modes)
- `GET /api/mb/orders` - List MBv2 project offerings
- `POST /api/mb/order` - Create project listing
- `GET /api/mb/trade-requests` - Get trade requests
- `POST /api/mb/trade-request` - Submit trade request
- `PUT /api/mb/trade-request/:id` - Update/counter-offer

### DPX-Specific
- `POST /api/mb2/configure-swap` - Configure SwapBox after acceptance
- `GET /api/mb2/swap/:swapId` - Get SwapBox status

---

## Code Files to Modify

### High Priority (Core Changes)

| File | CPX Function | DPX Changes |
|------|--------------|-------------|
| `user.service.ts` | Login with credentials | Add SIWE wallet login |
| `apx.service.ts` | Mint to ACXNET ledger | Deploy ERC-20 on Avalanche |
| `mb2.service.ts` | Execute trade via ledger | Add executeTradeSwapBox() |
| `balance.ts` | Query ACXNET ledger | Query Avalanche ERC-20 |

### Medium Priority

| File | Changes |
|------|---------|
| `auth.service.ts` | Add wallet signature verification |
| `notifier.service.ts` | Add SwapBox deposit notifications |
| Indexer | Add Avalanche C-Chain event sync |
| Frontend (MBv2) | Add SwapBox deposit/withdraw UI |

### Not Modified (Shared 100%)

- `mb2.service.ts` - Listing and negotiation logic
- `apx` project management - Validation, metadata
- `carbon.service.ts` - Project filtering, search
- Entity permission graph - Cross-entity rules

---

## Success Metrics (End Q1 2026)

| Metric | Target |
|--------|--------|
| DPX Active Wallets | 1,000+ |
| USDC Volume (SwapBox) | $15M+ |
| Swap Success Rate | >95% |
| Settlement Time (DPX) | <5 minutes |
| Gas Cost (DPX) | <$1 per swap |
| CPX Migration to ACXNET | 100% by May 1 |

---

## Security Checklist

**SwapBox Contract:**
- [ ] External audit by Halborn or Trail of Bits
- [ ] Bug bounty $50K+ for critical vulnerabilities
- [ ] 4+ weeks testnet operation on Avalanche Fuji
- [ ] ReentrancyGuard on all state-changing functions
- [ ] Emergency pause mechanism tested

**ACXNET Subnet:**
- [ ] Minimum 5 institutional validators
- [ ] Private mempool configuration (MEV protection)
- [ ] Disaster recovery procedures documented
- [ ] State migration from Polygon validated

---

## Quick Links

**Full Documentation:**
- Main Spec: `ARR-Phase1-DPX-Refactoring.md`
- Executive Summary: `ARR-Phase1-Executive-Summary.md`
- Whitepaper Content: `Whitepaper-ARR-Section.md`
- **SwapBox Code:** `SwapBox-Contract.md`
- Technical Comparison: `CPX-vs-DPX-Technical-Comparison.md`
- Navigation: `ARR-Phase1-Index.md`
- Changelog: `UPDATE-SUMMARY.md`

**External Resources:**
- Avalanche Docs: https://docs.avax.network/
- Avalanche Subnet EVM: https://github.com/ava-labs/subnet-evm
- Core Wallet: https://core.app/
- Snowtrace (Explorer): https://snowtrace.io/
- Trader Joe DEX: https://traderjoexyz.com/

---

**Status:** Ready for Implementation

