# CPX vs. DPX: Detailed Technical Comparison

**Architecture Refactoring Roadmap – Reference Document**

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

**Network Deployment:**
- **DPX:** Avalanche C-Chain (Chain ID: 43114)
- **CPX:** ACXNET (AvaLabs Custom Layer 1)

---

## System Architecture Comparison

### Authentication & User Identity

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Login Method** | Username + password (SHA256) | Wallet signature (SIWE) |
| **Session Management** | JWT in HTTP-only cookies | JWT tied to wallet address |
| **MFA Support** | Email/SMS OTP | Wallet-native (Ledger, Trezor) |
| **Account Recovery** | Password reset via email | Seed phrase (user responsibility) |
| **Identity Storage** | SQL Server `user` table | `user_wallet` table mapping |
| **KYC Integration** | Required, stored on-platform | Optional, wallet-based verification |
| **Code Files** | `user.service.ts::login()` | `wallet-auth.service.ts::loginWithWallet()` |

---

### Asset Custody & Tokenization

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Blockchain Network** | **ACXNET (Custom L1)** | **Avalanche C-Chain (43114)** |
| **FCT Storage** | Centralized STMv2 ledger contract (ACXNET) | User wallets (ERC-20 on Avalanche) |
| **Private Key Control** | ACX admin accounts | Users (Metamask, Core Wallet, WalletConnect) |
| **Token Standard** | Custom ledger entries | ERC-20 (OpenZeppelin) |
| **Transferability** | Only within platform | Global (any EVM wallet/DEX) |
| **Minting Process** | `mintSecTokenBatch()` to ledger address (ACXNET) | Deploy new ERC-20 on Avalanche → mint to wallet |
| **Metadata Storage** | On-chain (STMv2 metaKeys/metaValues) | On-chain + IPFS (ERC-20 metadata) |
| **Fractional Ownership** | Ledger balance divisibility | ERC-20 decimals (18) |
| **Composability** | Platform-only | Avalanche DeFi (Trader Joe, Aave, Benqi) |
| **Asset Registry** | SQL `x_asset` table | `FctTokenFactory` events + SQL |
| **Code Files** | `ledger.ts::mintBatch()` | `fct-factory.service.ts::deployFctToken()` |

---

### Payment & Currency Management

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Blockchain Network** | **ACXNET (Custom L1)** | **Avalanche C-Chain (43114)** |
| **Quote Currency** | Fiat USD (ledger balance on ACXNET) | USDC/USDT (ERC-20 on Avalanche) |
| **Custody** | ACX bank accounts + ledger | User wallets (self-custody) |
| **Deposit Method** | Bank wire → admin credits ledger | Buy USDC on Avalanche (Trader Joe, CEX bridge) |
| **Withdrawal Method** | Admin debits ledger → bank wire | Transfer USDC to external wallet |
| **Balance Queries** | `getLedgerEntry()` contract call (ACXNET) | `balanceOf()` on USDC contract (Avalanche) |
| **Transaction Fees** | Zero gas fees (ACX subsidized) + platform fees | AVAX gas fees (~$0.42) + platform fees |
| **Settlement Currency** | Ledger USD | On-chain USDC (Avalanche native) |
| **Fiat On/Off-Ramp** | ACX-managed (Wise, local banks) | User responsibility (Coinbase, Kraken, Avalanche Bridge) |
| **Code Files** | `fiat.service.ts::depositUserNotify()` | Disabled in DPX mode |

---

### Order Placement & Validation

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Balance Check** | Query ledger balance via contract | Query wallet via `balanceOf()` |
| **Fund Reservation** | Transfer to reserve account (ledger) | ERC-20 `approve()` to SwapBox |
| **Order Submission** | OMS API → RabbitMQ → Matching Engine | Same flow, approval tx hash required |
| **Risk Validation** | Pre-trade balance check (server-side) | Approval verification (on-chain) |
| **User Action** | Click "Place Order" | Sign approval → click "Place Order" |
| **Failure Mode** | Insufficient ledger balance | Insufficient wallet balance / approval |
| **Code Files** | `order.service.ts::validateBalance()` | `order.service.ts::validateWalletBalance()` |

---

### Trade Negotiation (Identical Across Modes - Marketplace v2)

| Feature | CPX | DPX | Notes |
|---------|-----|-----|-------|
| **Trading Platform** | Marketplace v2 (MBv2) | Marketplace v2 (MBv2) | **No changes** |
| **Discovery** | Bilateral negotiation | Bilateral negotiation | **No changes** |
| **Listing Flow** | Seller lists project | Same | **No changes** |
| **Trade Requests** | Buyer submits request | Same | **No changes** |
| **Messaging** | Counter-offer system | Same | **No changes** |
| **Acceptance** | Seller accepts terms | Same | **No changes** |
| **Entity Permissions** | Graph-based cross-entity rules | Same | **No changes** |

*Marketplace v2 negotiation logic is **100% shared** – only settlement differs*

**Note:** CPX/DPX use **Marketplace v2 (bilateral negotiation)**, not the C# matching engine. The matching engine (CLOB/spot market) is used only for contract-based trading (CET, GNT), not FCT trading.

---

### Trade Settlement

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Trading Platform** | **Marketplace v2 (MBv2)** | **Marketplace v2 (MBv2)** |
| **Settlement Method** | `transferOrTrade()` atomic swap | SwapBox bilateral escrow |
| **Transaction Signer** | ACX admin account | Buyer + seller (4 separate txs: 2 deposits + 2 withdrawals) |
| **Settlement Trigger** | Seller accepts trade request → auto-settle | Seller accepts → configure SwapBox → users deposit |
| **Buyer Action** | None (auto-settled) | 1) Deposit USDC, 2) Withdraw FCT |
| **Seller Action** | None (auto-settled) | 1) Deposit FCT, 2) Withdraw USDC |
| **Atomicity** | Single on-chain transaction (ACXNET) | Contract-enforced (both deposit before either withdraws) |
| **Finality** | Immediate (<1 second on ACXNET) | Upon both withdrawals (~4 seconds on Avalanche) |
| **Failure Recovery** | Rollback via database | Auto-refund after 24-hour expiry |
| **Custody During Settlement** | ACX controls ledger | SwapBox contract holds escrow |
| **Smart Contract** | STMv2.sol `transferOrTrade()` (ACXNET) | SwapBox.sol (Avalanche C-Chain) |
| **Code Files** | `mb2.service.ts::executeTrade()` | `mb2.service.ts::executeTradeSwapBox()` |
| **Matching Engine Used?** | No (MBv2 bilateral only) | No (MBv2 bilateral only) |

---

### Smart Contracts

| Contract | CPX | DPX | Network | Purpose |
|----------|-----|-----|---------|---------|
| **STMv2.sol** | Core ledger | Not used | **ACXNET** | Centralized balance tracking (Security Token Manager v2) |
| **FctTokenFactory.sol** | Not used | Deploys ERC-20s | **Avalanche C-Chain** | Creates FCT tokens per vintage |
| **FctToken.sol (ERC-20)** | Not used | Per project-vintage | **Avalanche C-Chain** | Tradable carbon credit tokens |
| **SwapBox.sol** | Not used | Settlement escrow | **Avalanche C-Chain** | Bilateral trade settlement |
| **USDC.sol (external)** | Not used | Quote currency | **Avalanche C-Chain** | Stablecoin payment rail (0xB97E...) |

---

### Database Schema

| Table/Column | CPX | DPX | Notes |
|--------------|-----|-----|-------|
| **user** | Username, password hash | Legacy support | DPX adds wallet mapping |
| **user_wallet** | Not used | New table | Maps wallet addresses to users |
| **user_account** | Ledger addresses | `is_external_wallet` flag | DPX marks external wallets |
| **x_asset** | Ledger asset types | + `erc20_address`, `token_standard` | Extended for ERC-20 support |
| **swapbox_swap** | Not used | New table | Tracks SwapBox swap status |
| **transaction** | Admin-signed txs | User-signed txs | DPX adds `user_signed` flag |

---

### API Endpoints

| Endpoint | CPX | DPX | Changes |
|----------|-----|-----|---------|
| **POST /api/users/login** | Username/password | Disabled | Use `/api/auth/wallet-login` |
| **POST /api/auth/wallet-login** | Not available | SIWE | New endpoint |
| **GET /api/balance** | Ledger balance | Wallet balance | Conditional logic |
| **POST /api/order** | Place order | + `approvalTxHash` | DPX adds approval field |
| **POST /api/settle/execute** | `transferOrTrade()` | `configureSwap()` | Different smart contract call |
| **GET /api/swapbox/:swapId** | Not available | Swap status | New endpoint |
| **POST /api/apx/mint-fct** | Mint to ledger | Deploy ERC-20 | Conditional logic |

---

### Frontend Components

| Component | CPX | DPX | Implementation |
|-----------|-----|-----|----------------|
| **Login.tsx** | Username/password form | WalletConnect button | Conditional render |
| **Balances.tsx** | Display ledger balances | Display wallet balances | Conditional data source |
| **OrderForm.tsx** | Submit order | Approve USDC → submit order | Add approval step |
| **TradeHistory.tsx** | Auto-settled trades | Link to SwapBox deposits | Conditional UI |
| **SwapBoxDeposit.tsx** | Not used | New component | Deposit USDC/FCT UI |

---

### Background Services

| Service | CPX Function | DPX Function | Shared Logic |
|---------|--------------|--------------|--------------|
| **processors** | Signs admin txs for ledger | Monitors SwapBox events | Transaction queue management |
| **indexer** | Indexes ACXv2 events | Indexes ERC-20 + SwapBox events | MongoDB storage |
| **cron** | Auto-fund new users | Expire stale SwapBoxes | Scheduled task framework |
| **notifier** | Email deposit confirmations | Wallet notifications (WalletConnect) | Message templating |

---

### Security & Compliance

| Feature | CPX (Centralized) | DPX (Decentralized) |
|---------|-------------------|---------------------|
| **Custody** | ACX holds private keys | Users hold private keys |
| **KYC/AML** | Mandatory on registration | Optional (wallet-based KYC) |
| **Transaction Approval** | Admin signs all txs | Users sign own txs |
| **Fund Recovery** | ACX can reverse txs (before finality) | Irreversible (blockchain native) |
| **Regulatory Classification** | Custodial exchange | Non-custodial protocol |
| **Audit Trail** | SQL database + blockchain events | Blockchain events only |
| **IP Whitelisting** | Supported | Not applicable (permissionless) |
| **Multi-Sig** | ACX admin multi-sig for ops | SwapBox admin multi-sig for config |

---

### Gas Costs & Transaction Fees

| Transaction Type | CPX (ACXNET) | DPX (Avalanche C-Chain) |
|------------------|--------------|-------------------------|
| **Network** | **ACXNET Custom L1** | **Avalanche C-Chain (43114)** |
| **FCT Mint** | ~150K gas (ACX pays) | ~200K gas (project owner pays) |
| **Order Approval** | N/A (ledger balance) | ~50K gas (user pays) |
| **Settlement** | ~300K gas (ACX pays) | Buyer: 80K + Seller: 80K (each pays) |
| **Gas Cost to User** | **$0** (fully subsidized) | **~$0.42** typical (~$0.21-$0.84 range) |
| **Gas Cost to ACX** | **<$0.01** per tx | **$0** (users pay own gas) |
| **Platform Fee** | Configurable (e.g., 0.5%) | Same |

**Network Comparison:**

| Metric | ACXNET (CPX) | Avalanche C-Chain (DPX) | Polygon (Legacy) |
|--------|--------------|-------------------------|------------------|
| **Finality** | <1 second | <2 seconds | ~30 seconds |
| **Throughput** | Configurable (10K+ TPS) | 4,500 TPS | ~7,000 TPS |
| **Gas Model** | ACX-subsidized ($0 to user) | User-paid (~$0.42) | User-paid (~$0.10) |
| **Validator Set** | ACX + institutional partners | Public Avalanche validators | Public Polygon validators |
| **MEV Protection** | Private mempool | Standard | Standard |

**Conclusion:** 
- **CPX on ACXNET** offers **zero-friction** experience for institutions (no gas fees, instant finality)
- **DPX on Avalanche** offers **<$1 gas costs** with **sub-second finality**, superior to Polygon/Arbitrum alternatives

---

### Operational Workflows

#### FCT Minting Workflow

**CPX (ACXNET):**
```
1. Admin approves project → creates x_asset
2. Admin triggers mint → system calls ledger.mintBatch() on ACXNET
3. Admin account signs tx → broadcasts to ACXNET
4. FCTs appear in project owner's ledger account
5. Indexer processes MintedSecToken event
```

**DPX (Avalanche C-Chain):**
```
1. Admin approves project → creates x_asset
2. Admin triggers mint → system deploys FctToken ERC-20 on Avalanche
3. Factory contract mints to project owner's wallet
4. ERC-20 address stored in x_asset.erc20_address
5. Indexer processes FctTokenCreated + Transfer events on Avalanche
```

#### Trade Settlement Workflow (Marketplace v2)

**CPX (ACXNET - Bilateral Negotiation):**
```
1. Seller lists project on MBv2
2. Buyer submits trade request
3. Negotiation via counter-offers
4. Seller accepts → mb2.executeTrade triggered
5. System builds transferOrTrade params
6. Admin signs transaction on ACXNET
7. Ledger atomically swaps USD ↔ FCT (single tx)
8. Trade marked complete → both parties notified
```

**DPX (Avalanche C-Chain - Bilateral Negotiation + SwapBox):**
```
1. Seller lists project on MBv2
2. Buyer submits trade request
3. Negotiation via counter-offers
4. Seller accepts → mb2.executeTradeSwapBox triggered
5. System calls swapBox.configureSwap() on Avalanche
6. Buyer notified → approves USDC → calls depositBuyerAsset(swapId)
7. Seller notified → approves FCT → calls depositSellerAsset(swapId)
8. Both deposited → swap becomes ReadyToSettle
9. Buyer calls withdrawBuyerAsset() → receives FCT
10. Seller calls withdrawSellerAsset() → receives USDC
11. Trade marked complete
```

**Key Difference:** Both use **Marketplace v2 (MBv2)** bilateral negotiation. CPX auto-settles after acceptance; DPX requires user deposits/withdrawals.

---

### User Experience

| Aspect | CPX | DPX |
|--------|-----|-----|
| **Account Setup** | Register → verify email → login | Connect wallet (instant) |
| **Learning Curve** | Familiar (like traditional exchange) | Requires wallet knowledge |
| **Trading Workflow** | MBv2 bilateral negotiation | Same (MBv2 bilateral negotiation) |
| **Deposit Time** | 1-3 days (bank wire for USD) | Instant (if user has USDC on Avalanche) |
| **Withdrawal Time** | 1-3 days (bank wire) | Instant (wallet transfer) |
| **Trade Settlement** | Instant after acceptance (auto-settled on ACXNET) | 4-step after acceptance (deposit USDC → deposit FCT → withdraw FCT → withdraw USDC) |
| **Settlement Time** | <1 second (ACXNET finality) | <5 minutes typical (4 Avalanche transactions) |
| **Transaction Visibility** | Platform UI + ACXNET explorer | Platform UI + Snowtrace (Avalanche explorer) |
| **Customer Support** | 24/7 email/chat | Community + docs (self-service) |

---

### Performance & Scalability

| Metric | CPX (ACXNET) | DPX (Avalanche) |
|--------|--------------|-----------------|
| **Listing Capacity** | Unlimited (MBv2 bilateral platform) | Same |
| **Trade Request Throughput** | Limited by database write speed | Same |
| **Settlement Throughput** | 100 trades/sec (admin signing bottleneck) | Unlimited (parallel user SwapBox txs) |
| **Concurrent Users** | 50K (database limit) | Unlimited (stateless wallets) |
| **Blockchain TPS** | 10K+ TPS (ACXNET custom L1) | 4,500 TPS (Avalanche C-Chain) |
| **Database Load** | High (all balances + MBv2 data in SQL) | Medium (MBv2 data in SQL, balances on-chain) |

**Conclusion:** 
Both CPX and DPX use **Marketplace v2** (no matching engine bottleneck). DPX scales **horizontally** via decentralized SwapBox settlement. CPX limited by centralized admin signing (~100 settlements/sec max). Neither mode uses the C# matching engine (reserved for CLOB/spot market).

---

## Feature Toggle Strategy

### Configuration-Driven Behavior

```typescript
// Runtime check at every decision point
const settlementMethod = FEATURE_DPX_MODE ? 'swapbox' : 'ledger';

// Example: Balance validation
async function validateOrderBalance(order: Order) {
  if (FEATURE_DPX_MODE) {
    const wallet = await getUserWallet(order.userId);
    return await erc20.balanceOf(wallet) >= order.amount;
  } else {
    return await ledger.getLedgerEntry(order.userAddress).ccys[USD_ID] >= order.amount;
  }
}
```

### Feature Toggle Matrix

| Feature | Toggle Variable | Default | Production |
|---------|-----------------|---------|------------|
| **DPX Mode** | `FEATURE_DPX_MODE` | `false` | Per entity |
| **Wallet Auth** | Derived from DPX mode | CPX | DPX if enabled |
| **ERC-20 Minting** | Derived from DPX mode | Ledger | ERC-20 if enabled |
| **SwapBox Settlement** | Derived from DPX mode | Ledger | SwapBox if enabled |
| **Fiat Services** | Inverse of DPX mode | Enabled | Disabled in DPX |

---

## Migration Path

### Gradual Rollout Strategy

**Phase 1:** Internal testing (testnet)
```
Entity ID 999 (ACX Test) → FEATURE_DPX_MODE=true
All others → FEATURE_DPX_MODE=false
```

**Phase 2:** Beta partners (mainnet)
```
Entity IDs [1001, 1002, 1003] → FEATURE_DPX_MODE=true
All others → FEATURE_DPX_MODE=false
```

**Phase 3:** Public launch
```
New users → FEATURE_DPX_MODE=true (default)
Existing users → FEATURE_DPX_MODE=false (opt-in upgrade)
```

### Data Migration

**Not required** – both modes share same database schema:
- CPX users: `user_account.is_external_wallet = 0`
- DPX users: `user_account.is_external_wallet = 1`

Users can be **migrated** by:
1. Creating wallet mapping in `user_wallet`
2. Setting `is_external_wallet = 1`
3. Enabling DPX mode for their entity

---

## Code Organization

### Shared Modules (No Changes)

- **Marketplace v2** (`packages/wa-api/services/mb2/`) – 100% shared (listing, negotiation, trade requests)
- **Project Management** (`packages/api/services/apx/`) – 95% shared (add ERC-20 minting)
- **Entity Permissions** (`packages/utils-server/entity-graph.ts`) – 100% shared
- **Market Data** (`packages/api/services/carbon.service.ts`) – 100% shared

### Modules NOT Used for CPX/DPX

- **Matching Engine** (`apps/OrderMatcher`) – Used only for CLOB/spot market (CET, GNT contracts), not FCT trading
- **Order Management System** (`packages/oms`) – Used only for CLOB/spot market
- **Spot Trading APIs** – Separate from Marketplace v2; not applicable to project-based FCT trading in Phases 1-2

### Mode-Specific Modules

**CPX Only (ACXNET):**
- `packages/api/fiat.service.ts` – Fiat deposits/withdrawals
- `packages/utils-server/ledger.ts` – STMv2 ledger interactions on ACXNET

**DPX Only (Avalanche C-Chain):**
- `packages/api/wallet-auth.service.ts` – SIWE authentication
- `packages/wa-api/services/swapbox.service.ts` – SwapBox configuration (NEW)
- `packages/wa-api/services/fct-factory.service.ts` – ERC-20 deployment (NEW)

**Shared with Conditional Logic:**
- `packages/api/user.service.ts` – Login (CPX) vs. wallet login (DPX)
- `packages/wa-api/services/mb2/mb2.service.ts` – Settlement (ledger vs. SwapBox)
- `packages/utils-server/balance.ts` – Balance checks (ACXNET ledger vs. Avalanche wallet)

---

## Testing Strategy

### Unit Tests

```typescript
describe('Order Validation', () => {
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

### Integration Tests

- **CPX Flow (MBv2 Bilateral):** Register → deposit fiat → seller lists project → buyer submits trade request → negotiation → acceptance → auto-settle (transferOrTrade on ACXNET)
- **DPX Flow (MBv2 Bilateral + SwapBox):** Connect wallet → seller lists project (with FCT ERC-20) → buyer submits request → negotiation → acceptance → configure SwapBox → buyer deposits USDC → seller deposits FCT → both withdraw

### End-to-End Tests

- **Hybrid Mode:** CPX user trades with DPX user (Phase 2 cross-mode bridge)

---

## Conclusion

This comparison demonstrates that **CPX and DPX share >80% of codebase** while serving fundamentally different market needs:

- **CPX** excels in regulated, custodial environments (Indonesia IDXCarbon, Brazil B3)
- **DPX** excels in permissionless, DeFi-native environments (global crypto users)

The **feature toggle architecture** enables:
- Zero code duplication
- Single deployment pipeline
- Shared business logic (matching, risk, permissions)
- Mode-specific user experiences (credentials vs. wallet)

**Result:** AirCarbon can serve **both markets** without the complexity and cost of maintaining separate platforms.

---

**See Also:**
- `ARR-Phase1-DPX-Refactoring.md` (full technical specification)
- `Whitepaper-ARR-Phase1.md` (whitepaper-ready content)

