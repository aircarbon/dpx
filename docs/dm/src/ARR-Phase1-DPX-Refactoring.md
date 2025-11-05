# Architecture Refactoring Roadmap (ARR)
## Phase 1 - Core DeFi Expansion/Refactoring

**Version:** 1.1  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads

---

## Executive Summary

This document outlines the technical architecture and refactoring strategy to transform the current **Carbon Project Exchange (CPX)** into a dual-mode platform capable of operating as both a centralized exchange and a **Decentralized Project Exchange (DPX)**.

The DPX variant represents a fundamental shift from custodial, centralized operations to a non-custodial, DeFi-native architecture while maintaining backward compatibility with existing CPX deployments. This will be achieved through a **single unified codebase** operating under **runtime feature toggles**, enabling seamless deployment across both operational modes without code duplication or fragmentation.

**Deployment Strategy:**
- **DPX:** Launches on **Avalanche C-Chain** for high throughput and low gas costs
- **CPX:** Migrates from Polygon to **ACXNET** (AvaLabs Custom Layer 1) for institutional-grade performance
- **Timeline:** 6-month rollout culminating in Phase 2 cross-mode liquidity by end Q2 2026 (June 30, 2026)

**Key Principle:** *One codebase, two operating modes, two optimized networks, zero compromise on security or functionality.*

---

## 1. Current CPX Architecture Overview

### 1.1 Authentication & User Management

**Current Implementation:**
- Username/password authentication via SHA256-hashed credentials stored in SQL Server
- JWT-based session management with cookie-based token storage
- Multi-factor authentication (MFA) support via email/SMS OTP
- Cognito integration for select deployments
- IP whitelisting for enhanced account security

**Key Components:**
- `packages/wa-api/services/user/user.service.ts` – Login/authentication handlers
- `packages/utils-server/src/services/auth.service.ts` – Authentication middleware
- `apps/surveillance/Pages/Login.razor` – Admin portal login (C#/Blazor)
- `packages/web/src/pages/Login.tsx` – User-facing React login

### 1.2 Custody Model – Centralized Ledger

**Current Implementation:**
- Users **do not hold private keys** to their blockchain addresses
- ACX-controlled "admin accounts" (whitelisted contract signers) execute all blockchain transactions on behalf of users
- Addresses are pre-generated (5000 per contract deployment) and assigned to users upon registration
- Balances are maintained in the **STMv2 smart contract** (`STMv2.sol`)—a custom, centralized ledger contract
- All asset movements (FCT minting, USD deposits, trades) occur **on-ledger** via admin-signed transactions

**Smart Contract Architecture:**
- **Contract:** `STMv2` (Security Token Manager v2) (Solidity, EVM-compatible)
- **Key Methods:**
  - `mintSecTokenBatch()` – Mints FCTs to user ledger accounts
  - `fundOrWithdraw()` – Credits/debits fiat currency on-ledger
  - `transferOrTrade()` – Executes bilateral asset transfers (trade settlement)
  - `getLedgerEntry()` – Retrieves account balances (tokens + currencies)

**Database Integration:**
- SQL Server stores user-to-address mappings (`user_account` table)
- MongoDB-based **blockchain indexer** reconstructs ledger state from emitted events for fast queries
- Transaction queue managed via RabbitMQ for async processing

**Network Migration (Concurrent with DPX Launch):**
- **CPX Context:** CPX is a subsystem of the wider **ACX centralized exchange** platform, which includes spot/CLOB markets, custody services, and fiat on/off-ramps
- Current ACX/CPX deployment: Polygon PoS
- Target ACX/CPX deployment: **ACXNET** (AvaLabs Custom Layer 1)
- Benefits: Dedicated throughput, customizable gas economics, institutional SLAs, zero-gas for users
- Migration strategy: Parallel deployment → liquidity migration → hard cutover (simultaneous Polygon decommission)

### 1.3 Asset Lifecycle – FCT Minting

**Current Workflow:**

1. **Project Onboarding:**
   - Carbon project developer submits ERPA details via admin portal
   - Project stored in `carbon_project_apx` table with status workflow (Draft → Review → Approved)
   - Vintages defined in `carbon_project_apx_vintage` with offered credit quantities

2. **FCT Asset Creation:**
   - Admin creates FCT asset type via `token.service.ts` (`addTokenMint` action)
   - Asset registered in `x_asset` table with link to project vintage
   - Trading pair created in `x_pair` (e.g., `FCT2025/USD`)

3. **Minting to Ledger:**
   - Admin triggers `apx.mintFctTokens` action
   - System calls `Ledger.mintBatch()` with:
     - `tokTypeId` – FCT asset ID on smart contract
     - `qtyUnit` – Quantity to mint (tons CO₂e)
     - `receiver` – Project owner's **centralized ledger address**
     - `metadata` – IPFS hash, vintage year, registry IDs
   - Transaction signed by ACX admin account, broadcast to blockchain
   - Event emitted: `MintedSecToken(batchId, tokTypeId, owner, qty)`
   - Indexer processes event → updates MongoDB balance cache

**Key Point:** FCTs exist **only on the STMv2 ledger**, not as true ERC-20s transferable to external wallets.

### 1.4 Payment & Settlement – Fiat USD

**Current Workflow:**

1. **Buyer Deposits Fiat:**
   - User initiates deposit request via `fiat.depositUserNotify` action
   - Admin reviews bank transfer, marks deposit as verified
   - Processor service calls `fundOrWithdraw()` to credit USD on-ledger
   - Balance updated in smart contract under user's ledger account

2. **Marketplace v2 Trading:**
   - **Seller:** Lists FCT project on MBv2 with price, quantity, criteria
   - **Buyer:** Browses listings, submits trade request with proposed terms
   - **Negotiation:** Counter-offers exchanged via messaging system
   - **Acceptance:** Seller accepts final terms
   - System validates buyer's available USD balance via `getAvailableBalance()`

3. **Trade Execution (MBv2):**
   - Upon acceptance, `mb2.executeTrade` action triggered
   - Settlement service calls `transferOrTrade()`:
     - Debits USD from buyer's ledger account
     - Credits USD to seller's ledger account
     - Transfers FCT tokens from seller to buyer
   - Atomic bilateral swap completed **on-chain** in single transaction
   - Both parties notified of settlement completion

4. **Seller Withdraws Fiat:**
   - Seller requests withdrawal via `fiatWithdrawal.createWithdrawalRequest`
   - Admin reviews, approves, initiates bank wire
   - On-ledger USD burned via `fundOrWithdraw(direction=WITHDRAW)`

**Key Point:** USD exists as **ledger-based balances**, not stablecoins. Custody held by ACX.

### 1.5 Marketplace v2 (MBv2) – Bilateral Trading Platform

**Architecture:**

The **Marketplace v2 (MBv2)** is a bilateral negotiation platform distinct from the CLOB/spot market. It enables project-based trading with direct buyer-seller negotiation:

- **`mb2.service.ts`:** TypeScript/Node.js service handling project listings, offers, and trade requests
- **Seller Workflow:**
  - Lists projects/FCTs with criteria (vintage, registry, methodology)
  - Sets asking price and quantity
  - Receives trade requests from buyers
  - Can accept, reject, or counter-offer
- **Buyer Workflow:**
  - Browses project listings
  - Submits trade requests with proposed price/quantity
  - Negotiates via messaging/counter-offers
  - Confirms final terms
- **Settlement Layer:** `mb2.executeTrade` action triggers bilateral settlement

**Trade Flow (MBv2 - Bilateral Negotiation):**

```
Seller Lists Project → Buyer Submits Trade Request → Negotiation (Counter-Offers) → Acceptance → Settlement (transferOrTrade)
```

**Marketplace v2 vs. Spot Market:**

| Feature | Marketplace v2 (MBv2) | Spot Market (CLOB) |
|---------|----------------------|--------------------|
| **Trading Type** | Project-based (bilateral) | Contract-based (anonymous) |
| **Matching** | Direct negotiation | Price-time priority matching engine (C#) |
| **Assets** | Specific FCTs (project + vintage) | Fungible contracts (CET, GNT) |
| **Settlement** | `mb2.executeTrade` | OMS → C# engine → `settle.service` |
| **CPX/DPX Usage** | **Used for Phases 1-2** | Not used for FCT trading |

**Note:** CPX/DPX (Phases 1-2) operate **exclusively on Marketplace v2**. The C# matching engine (CLOB/spot market) is a separate trading venue for contract-based trading (CET, GNT) and is **not used** for CPX/DPX project-based FCT trading.

### 1.6 Multi-Entity Architecture

**Key Feature:**
- Entities form a **directed graph** of trading permissions
- Parent entities extend permissions to child entities
- Real-time graph traversal during matching ensures only permitted counterparties trade
- Supports B2B marketplaces, jurisdictional restrictions, private pools

**Example:**
- Entity A (Singapore) ↔ Entity B (Brazil) allowed to trade
- Entity C (USA) restricted from trading with Entity A (sanctions)

---

## 2. Target DPX Architecture

### 2.1 Authentication – Metamask Integration

**Proposed Changes:**

- **Frontend:**
  - Remove username/password login forms
  - Add **Web3Modal** or **RainbowKit** UI for wallet connection
  - Support Metamask, WalletConnect, Coinbase Wallet, etc.
  - Display connected address as user identifier

- **Backend:**
  - Implement **SIWE (Sign-In with Ethereum)** standard
    - User signs nonce message with private key
    - Backend verifies signature, issues JWT tied to wallet address
  - Map wallet address → user entity (auto-create on first login)
  - Remove password hashing, MFA (authentication is wallet-based)

- **Smart Contract:**
  - No whitelist required—any address can interact
  - Entity assignment logic moved to off-chain indexing or on-chain registry

**Feature Toggle:**
```typescript
// config/features.ts
export const FEATURE_DPX_MODE = process.env.DPX_MODE === 'true';

// In auth.service.ts
if (FEATURE_DPX_MODE) {
  return await authenticateWallet(req);
} else {
  return await authenticateCredentials(req);
}
```

### 2.2 Asset Custody – ERC-20 FCTs

**Proposed Changes:**

**Current (CPX):**
- FCTs minted via `mintSecTokenBatch()` to centralized ledger addresses
- Non-transferable outside ledger ecosystem

**Target (DPX):**
- FCTs minted as **true ERC-20 tokens** directly to project owner's wallet
- Fully transferable, composable, DeFi-compatible
- Standard `transfer()`, `approve()`, `transferFrom()` methods

**Implementation Options:**

**Option A – New ERC-20 Contract Factory:**
```solidity
// contracts/FctTokenFactory.sol
contract FctToken is ERC20, ERC20Metadata {
    struct Metadata {
        string projectId;
        string vintageYear;
        string registry;
        string methodology;
        bool corsiaEligible;
        bool article6Authorized;
    }
    
    Metadata public metadata;
    
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply,
        Metadata memory _metadata
    ) ERC20(name, symbol) {
        metadata = _metadata;
        _mint(initialOwner, initialSupply);
    }
}

contract FctTokenFactory {
    event FctTokenCreated(address indexed tokenAddress, string projectId, uint256 vintageYear);
    
    function createFctToken(
        string memory name,
        string memory symbol,
        address projectOwner,
        uint256 supply,
        FctToken.Metadata memory metadata
    ) external returns (address) {
        FctToken token = new FctToken(name, symbol, projectOwner, supply, metadata);
        emit FctTokenCreated(address(token), metadata.projectId, metadata.vintageYear);
        return address(token);
    }
}
```

**Option B – ERC-1155 Multi-Token:**
```solidity
// contracts/FctMultiToken.sol
contract FctMultiToken is ERC1155, ERC1155Supply {
    struct TokenMetadata {
        string projectId;
        uint256 vintageYear;
        string registry;
        // ... other metadata
    }
    
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    uint256 private _currentTokenId;
    
    function mintFct(
        address to,
        uint256 amount,
        TokenMetadata memory metadata
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _currentTokenId++;
        tokenMetadata[tokenId] = metadata;
        _mint(to, tokenId, amount, "");
        return tokenId;
    }
}
```

**Recommended:** **Option A (ERC-20 per vintage)** for maximum DeFi compatibility (Trader Joe DEX, Aave, Benqi on Avalanche)

**Network-Specific Configuration:**
- **DPX (Avalanche C-Chain):**
  - Chain ID: 43114 (mainnet), 43113 (Fuji testnet)
  - Native token: AVAX (for gas)
  - Target DEX: Trader Joe, Pangolin
  - USDC contract: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E

- **CPX (ACXNET - Custom L1):**
  - Custom subnet validator set (ACX-controlled)
  - Configurable gas fees (subsidized for users)
  - Private mempool (MEV protection)
  - Dedicated block space (no congestion)

**Database Changes:**
- Add `erc20_address` column to `x_asset` table
- Add `token_standard` enum: `LEDGER` (CPX) | `ERC20` (DPX) | `ERC1155` (DPX)
- Add `network_id` column: `43114` (Avalanche C-Chain) | `ACXNET_ID` (custom L1)
- Modify `apx.mintFctTokens` to:
  - Check `FEATURE_DPX_MODE` and `network_id`
  - If DPX: Deploy new ERC-20 contract on Avalanche C-Chain, mint to `msg.sender` (project owner's wallet)
  - If CPX: Use existing `mintSecTokenBatch()` flow on ACXNET

**Feature Toggle:**
```typescript
// services/apx/apx.service.ts
async mintFctTokens(ctx) {
  if (FEATURE_DPX_MODE) {
    // Deploy ERC-20 contract on Avalanche C-Chain
    const avalancheProvider = new ethers.providers.JsonRpcProvider(
      'https://api.avax.network/ext/bc/C/rpc'
    );
    const factory = new ethers.Contract(
      FACTORY_ADDRESS_AVALANCHE, 
      factoryAbi, 
      signer.connect(avalancheProvider)
    );
    const tx = await factory.createFctToken(
      name, symbol, projectOwnerWallet, quantity, metadata
    );
    const receipt = await tx.wait();
    const tokenAddress = receipt.events[0].args.tokenAddress;
    
    // Store in database with network ID
    await dbORM.updateAsset(assetId, { 
      erc20Address: tokenAddress, 
      tokenStandard: 'ERC20',
      networkId: 43114 // Avalanche C-Chain
    });
  } else {
    // Existing ledger mint on ACXNET (custom L1)
    const acxnetProvider = new ethers.providers.JsonRpcProvider(
      process.env.ACXNET_RPC_URL
    );
    const ledger = new Ledger(acxnetProvider, { address: ACXNET_STMV2_ADDRESS, ... });
    await ledger.mintBatch({ tokTypeId, receiver, qtyUnit, ... });
  }
}
```

### 2.3 Payment Rails – USDC Integration

**Proposed Changes:**

**Current (CPX):**
- Fiat USD held in bank accounts, credited on-ledger via `fundOrWithdraw()`

**Target (DPX):**
- Buyers hold **USDC** (or USDT, DAI) in their wallets
- No ACX custody—users responsible for acquiring stablecoins

**Implementation:**

1. **Asset Configuration:**
   - Add USDC as quote currency in `x_asset` table
   - Configure USDC contract address for Avalanche C-Chain
     - Mainnet: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` (USDC.e - bridged)
     - Native USDC: `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E` (check latest Avalanche docs)
   - Support USDT as alternative: `0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7`

2. **Balance Checks:**
   - Modify `getAvailableBalance()` to query wallet balances via ERC-20 `balanceOf()` on Avalanche
   ```typescript
   async function getWalletBalance(address: string, tokenAddress: string) {
     const avalancheProvider = new ethers.providers.JsonRpcProvider(
       'https://api.avax.network/ext/bc/C/rpc'
     );
     const erc20 = new ethers.Contract(tokenAddress, erc20Abi, avalancheProvider);
     return await erc20.balanceOf(address);
   }
   ```

3. **Order Placement:**
   - Before submitting bid, frontend calls `usdc.approve(SWAPBOX_ADDRESS, amount)`
   - User signs approval transaction
   - Order submitted to OMS with approval transaction hash

**Feature Toggle:**
```typescript
// services/order.service.ts
async validateBalance(userId, assetId, amount) {
  if (FEATURE_DPX_MODE) {
    const wallet = await getUserWallet(userId);
    const balance = await getWalletBalance(wallet, USDC_ADDRESS);
    return balance >= amount;
  } else {
    return await getLedgerBalance(userId, assetId) >= amount;
  }
}
```

### 2.4 Settlement – SwapBox Smart Contract

**Core Innovation:**
The **SwapBox** contract replaces the centralized `transferOrTrade()` ledger settlement with a **trustless, bilateral escrow mechanism**.

**SwapBox Interface:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SwapBox
 * @notice Bilateral escrow for trustless FCT/USDC swaps
 * @dev Configured by ACX backend after marketplace match, settled by users
 */
contract SwapBox is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    enum SwapStatus { Pending, BuyerDeposited, SellerDeposited, Completed, Cancelled }

    struct Swap {
        uint256 swapId;
        address buyer;
        address seller;
        address fctToken;        // ERC-20 FCT contract address
        uint256 fctAmount;       // Tons CO₂e (18 decimals)
        address stablecoin;      // USDC/USDT/DAI address
        uint256 stablecoinAmount; // Price in stablecoin (6 decimals for USDC)
        SwapStatus status;
        uint256 expiryTimestamp;
        bool buyerDeposited;
        bool sellerDeposited;
    }

    mapping(uint256 => Swap) public swaps;
    uint256 private _swapCounter;

    event SwapConfigured(
        uint256 indexed swapId,
        address indexed buyer,
        address indexed seller,
        address fctToken,
        uint256 fctAmount,
        address stablecoin,
        uint256 stablecoinAmount,
        uint256 expiryTimestamp
    );

    event BuyerDeposited(uint256 indexed swapId, uint256 amount);
    event SellerDeposited(uint256 indexed swapId, uint256 amount);
    event SwapCompleted(uint256 indexed swapId);
    event SwapCancelled(uint256 indexed swapId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CONFIGURATOR_ROLE, admin);
    }

    /**
     * @notice Configure a new swap (called by ACX backend after match)
     * @param buyer Buyer wallet address
     * @param seller Seller wallet address
     * @param fctToken FCT ERC-20 contract address
     * @param fctAmount Quantity of FCT tokens (18 decimals)
     * @param stablecoin USDC/USDT contract address
     * @param stablecoinAmount Payment amount in stablecoin (e.g. 6 decimals for USDC)
     * @param expiryTimestamp Unix timestamp after which swap can be cancelled
     */
    function configureSwap(
        address buyer,
        address seller,
        address fctToken,
        uint256 fctAmount,
        address stablecoin,
        uint256 stablecoinAmount,
        uint256 expiryTimestamp
    ) external onlyRole(CONFIGURATOR_ROLE) returns (uint256) {
        require(buyer != address(0) && seller != address(0), "Invalid addresses");
        require(fctToken != address(0) && stablecoin != address(0), "Invalid token addresses");
        require(fctAmount > 0 && stablecoinAmount > 0, "Invalid amounts");
        require(expiryTimestamp > block.timestamp, "Invalid expiry");

        uint256 swapId = _swapCounter++;
        swaps[swapId] = Swap({
            swapId: swapId,
            buyer: buyer,
            seller: seller,
            fctToken: fctToken,
            fctAmount: fctAmount,
            stablecoin: stablecoin,
            stablecoinAmount: stablecoinAmount,
            status: SwapStatus.Pending,
            expiryTimestamp: expiryTimestamp,
            buyerDeposited: false,
            sellerDeposited: false
        });

        emit SwapConfigured(swapId, buyer, seller, fctToken, fctAmount, stablecoin, stablecoinAmount, expiryTimestamp);
        return swapId;
    }

    /**
     * @notice Buyer deposits stablecoin payment
     * @param swapId The swap identifier
     */
    function depositStablecoin(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        require(msg.sender == swap.buyer, "Not buyer");
        require(swap.status == SwapStatus.Pending || swap.status == SwapStatus.SellerDeposited, "Invalid state");
        require(block.timestamp < swap.expiryTimestamp, "Swap expired");
        require(!swap.buyerDeposited, "Already deposited");

        IERC20(swap.stablecoin).safeTransferFrom(msg.sender, address(this), swap.stablecoinAmount);
        swap.buyerDeposited = true;

        if (swap.sellerDeposited) {
            swap.status = SwapStatus.Completed;
            _executeSwap(swapId);
        } else {
            swap.status = SwapStatus.BuyerDeposited;
        }

        emit BuyerDeposited(swapId, swap.stablecoinAmount);
    }

    /**
     * @notice Seller deposits FCT tokens
     * @param swapId The swap identifier
     */
    function depositFct(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        require(msg.sender == swap.seller, "Not seller");
        require(swap.status == SwapStatus.Pending || swap.status == SwapStatus.BuyerDeposited, "Invalid state");
        require(block.timestamp < swap.expiryTimestamp, "Swap expired");
        require(!swap.sellerDeposited, "Already deposited");

        IERC20(swap.fctToken).safeTransferFrom(msg.sender, address(this), swap.fctAmount);
        swap.sellerDeposited = true;

        if (swap.buyerDeposited) {
            swap.status = SwapStatus.Completed;
            _executeSwap(swapId);
        } else {
            swap.status = SwapStatus.SellerDeposited;
        }

        emit SellerDeposited(swapId, swap.fctAmount);
    }

    /**
     * @notice Execute bilateral swap (internal)
     */
    function _executeSwap(uint256 swapId) private {
        Swap storage swap = swaps[swapId];

        // Transfer FCT to buyer
        IERC20(swap.fctToken).safeTransfer(swap.buyer, swap.fctAmount);

        // Transfer stablecoin to seller
        IERC20(swap.stablecoin).safeTransfer(swap.seller, swap.stablecoinAmount);

        emit SwapCompleted(swapId);
    }

    /**
     * @notice Cancel expired swap and refund deposits
     * @param swapId The swap identifier
     */
    function cancelSwap(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        require(
            msg.sender == swap.buyer || msg.sender == swap.seller || hasRole(CONFIGURATOR_ROLE, msg.sender),
            "Not authorized"
        );
        require(block.timestamp >= swap.expiryTimestamp, "Not expired");
        require(swap.status != SwapStatus.Completed, "Already completed");

        if (swap.buyerDeposited) {
            IERC20(swap.stablecoin).safeTransfer(swap.buyer, swap.stablecoinAmount);
        }

        if (swap.sellerDeposited) {
            IERC20(swap.fctToken).safeTransfer(swap.seller, swap.fctAmount);
        }

        swap.status = SwapStatus.Cancelled;
        emit SwapCancelled(swapId);
    }

    /**
     * @notice Query swap details
     */
    function getSwap(uint256 swapId) external view returns (Swap memory) {
        return swaps[swapId];
    }
}
```

**Settlement Flow (Marketplace v2):**

1. **Trade Request Accepted:**
   - Seller accepts buyer's trade request (or counter-offer)
   - Trade request status becomes `ACCEPTED`
   - `mb2.executeTrade` action triggered

2. **SwapBox Configuration:**
   ```typescript
   // services/mb2/actions/executeTradeSwapBox.action.ts (NEW for DPX)
   async function executeTradeSwapBox(tradeRequest: TradeRequest) {
     const swapBox = new ethers.Contract(SWAPBOX_ADDRESS, swapBoxAbi, signer);
     
     const tx = await swapBox.configureSwap(
       tradeRequest.buyerWallet,      // Buyer wallet address
       tradeRequest.sellerWallet,     // Seller wallet address
       USDC_ADDRESS_AVALANCHE,        // 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
       tradeRequest.price * tradeRequest.quantity,  // USDC amount
       tradeRequest.fctTokenAddress,  // FCT ERC-20 address
       tradeRequest.quantity,         // FCT amount (tons)
       Math.floor(Date.now() / 1000) + 86400 // 24 hour expiry
     );
     
     const receipt = await tx.wait();
     const swapId = receipt.events[0].args.swapId;
     
     // Store in database
     await dbORM.updateTradeRequest(tradeRequest.id, { 
       swapBoxId: swapId, 
       status: 'SWAP_CONFIGURED' 
     });
     
     // Notify both parties
     await notifier.send(tradeRequest.buyerUserId, { 
       type: 'DEPOSIT_USDC_REQUIRED', 
       swapId,
       amount: tradeRequest.price * tradeRequest.quantity
     });
     await notifier.send(tradeRequest.sellerUserId, { 
       type: 'DEPOSIT_FCT_REQUIRED', 
       swapId,
       amount: tradeRequest.quantity,
       projectName: tradeRequest.project.name
     });
   }
   ```

3. **User Deposits:**
   - **Frontend UI** displays pending swap with deposit instructions
   - Buyer approves USDC, then calls `swapBox.depositBuyerAsset(swapId)`
   - Seller approves FCT, then calls `swapBox.depositSellerAsset(swapId)`
   - Once **both deposit**, swap status becomes `ReadyToSettle`

4. **Withdrawals:**
   - Buyer calls `swapBox.withdrawBuyerAsset(swapId)` → receives seller's FCT
   - Seller calls `swapBox.withdrawSellerAsset(swapId)` → receives buyer's USDC
   - No ACX custody at any point

**Feature Toggle:**
```typescript
// services/settle/actions/executeSettle.action.ts
async function executeSettle(trade: Trade) {
  if (FEATURE_DPX_MODE) {
    return await executeSettleDPX(trade);
  } else {
    return await executeSettleCPX(trade); // Existing transferOrTrade flow
  }
}
```

---

## 3. Codebase Refactoring Plan

### 3.1 Top-Level Components & Subsystems

| Component | CPX Function | DPX Changes | Feature Toggle |
|-----------|--------------|-------------|----------------|
| **Authentication** | Username/password, JWT | SIWE (Sign-In with Ethereum) | `auth.service.ts` |
| **User Accounts** | SQL-based user profiles | Wallet address mapping | `user.service.ts` |
| **FCT Minting** | `mintSecTokenBatch()` to ledger | Deploy ERC-20, mint to wallet | `apx.service.ts` |
| **Project Listings** | Seller lists on MBv2 | Same (MBv2) | `mb2.service.ts::createOrder` |
| **Trade Requests** | Buyer submits bid on listing | Same (MBv2) | `mb2.service.ts::createTradeRequest` |
| **Negotiation** | Counter-offers via MBv2 messaging | Same (MBv2) | `mb2.service.ts::updateTradeRequest` |
| **Balance Queries** | `getLedgerEntry()` from ACXNET | `balanceOf()` from ERC-20 (Avalanche) | `balance.ts` |
| **Trade Acceptance** | Seller accepts → reserves assets | Seller accepts → requires approvals | `mb2.service.ts::updateTradeRequest` |
| **Settlement** | `transferOrTrade()` ledger swap | `SwapBox` bilateral escrow | `mb2.executeTrade` |
| **Fiat On/Off-Ramp** | Bank wire + `fundOrWithdraw()` | External DEX/CEX (user responsibility) | `fiat.service.ts` (disabled in DPX) |
| **Notifications** | Email/SMS for deposits | Wallet notifications (WalletConnect) | `notifier.service.ts` |

### 3.2 Public Interfaces & Entry Points

#### 3.2.1 Web Applications

**packages/web (User-Facing App)**

- **Login Flow:**
  - Add `WalletConnect` button alongside existing login
  - Route: `/login` → check `FEATURE_DPX_MODE` → render wallet UI or credentials form
  - New component: `components/auth/WalletLogin.tsx`

- **Balance Display:**
  - Existing: Query `/api/balance` → returns ledger balances
  - DPX: Query `/api/balance/wallet` → returns `balanceOf()` from ERC-20s
  - Component: `pages/account/Balances.tsx` (add conditional rendering)

- **Project Listings (MBv2):**
  - Existing: Seller lists project with price/quantity
  - DPX: Same listing flow, but specify wallet address for FCT custody
  - Component: `pages/market-board-v2/CreateListing.tsx`

- **Trade Requests (MBv2):**
  - Existing: Buyer submits request → negotiation → acceptance
  - DPX: Same negotiation flow, but requires USDC approval before acceptance
  - Component: `pages/market-board-v2/TradeRequestForm.tsx` (add approval step)

- **Trade Settlement (MBv2):**
  - Existing: Auto-settled by backend (`transferOrTrade` on ACXNET)
  - DPX: Display SwapBox deposit UI → buyer/seller deposit assets → withdraw
  - New component: `components/market-board-v2/SwapBoxDeposit.tsx`

**packages/wa-web (Admin Portal)**

- **Project Management:**
  - Existing: Create project → select "Mint to Ledger"
  - DPX: Add option "Mint as ERC-20" with project owner wallet input
  - Component: `components/carbon/apx/ProjectForm.tsx`

- **User Management:**
  - Existing: User list shows usernames
  - DPX: User list shows wallet addresses
  - Component: `components/users/UserList.tsx`

#### 3.2.2 API Services

**packages/api (Main API)**

- **New Endpoints:**
  ```typescript
  // Login with wallet
  POST /api/auth/wallet-login
  Body: { address: string, signature: string, message: string }
  
  // Get wallet balance
  GET /api/balance/wallet/:address/:tokenAddress
  
  // Get SwapBox status
  GET /api/swapbox/:swapId
  ```

- **Modified Endpoints:**
  ```typescript
  // Existing: POST /api/apx/projects (create project)
  // Add field: { erc20Minting: boolean, ownerWallet?: string }
  
  // Existing: POST /api/mb/order (create MBv2 listing)
  // No changes - listing flow identical for CPX/DPX
  
  // Modified: PUT /api/mb/trade-request/:id/accept (accept trade request)
  // DPX: Requires buyer USDC approval tx hash before acceptance
  ```

**packages/wa-api (Admin API)**

- **New Endpoints:**
  ```typescript
  // Deploy FCT ERC-20 (DPX mode)
  POST /api/apx/deploy-fct-token
  Body: { vintageId: number, ownerWallet: string, supply: number }
  
  // Configure SwapBox after MBv2 trade request acceptance
  POST /api/mb2/configure-swap
  Body: { tradeRequestId: number }
  
  // Get SwapBox status
  GET /api/mb2/swap/:swapId
  ```

#### 3.2.3 Background Services

**apps/processors (Transaction Processor)**

- **Existing:** Monitors `transaction` table for pending txs → signs → broadcasts
- **DPX Changes:**
  - Distinguish between **admin-signed** (CPX) and **user-signed** (DPX) transactions
  - For DPX: Monitor SwapBox events instead of ledger events
  - Add queue: `SWAPBOX_MONITOR_QUEUE`

**apps/indexer (Blockchain Indexer)**

- **Existing:** Indexes `ACXv2` ledger events (Minted, Transferred, FundedOrWithdrawn)
- **DPX Changes:**
  - Add indexing for:
    - `FctTokenCreated` (from FctTokenFactory)
    - `SwapConfigured`, `SwapCompleted`, `SwapCancelled` (from SwapBox)
    - Standard ERC-20 `Transfer` events (for FCTs)
  - Store in MongoDB: `erc20_transfers`, `swapbox_swaps` collections

**apps/cron (Scheduled Tasks)**

- **New Job:** Expire stale SwapBox configurations
  ```typescript
  // services/swapbox/actions/expire-swaps.action.ts
  async function expireSwaps() {
    const expiredSwaps = await dbORM.getSwapsBy({ 
      status: 'PENDING', 
      expiryTimestamp: { $lt: Date.now() } 
    });
    
    for (const swap of expiredSwaps) {
      await swapBox.cancelSwap(swap.swapBoxId);
    }
  }
  ```

#### 3.2.4 Matching Engine (Not Used for CPX/DPX)

**apps/OrderMatcher (C# Matching Engine)**

- **No Changes Required:** This component is used **only** for CLOB/spot market trading (CET, GNT contracts)
- CPX/DPX use **Marketplace v2 (MBv2)** bilateral negotiation platform instead
- Matching engine remains available for future integration if CLOB trading of FCTs is desired (Phase 3+)

### 3.3 Smart Contract Deployment Strategy

**New Contracts Required:**

1. **FctTokenFactory.sol** – Deploys ERC-20 FCTs on Avalanche C-Chain
2. **SwapBox.sol** – Bilateral escrow for trades on Avalanche C-Chain
3. **Optional: FctRegistry.sol** – On-chain registry of FCT token addresses mapped to project metadata

**Deployment Strategy:**

**DPX (Avalanche C-Chain):**
- Deploy FctTokenFactory, SwapBox to Avalanche Mainnet (Chain ID: 43114)
- Testnet: Avalanche Fuji (Chain ID: 43113)
- Grant `CONFIGURATOR_ROLE` to ACX backend signer addresses
- Integrate with Avalanche's Subnet EVM for potential future custom subnet

**ACX/CPX (ACXNET - Custom L1):**
- Deploy STMv2 ledger contract to ACXNET custom L1
- Migrate existing Polygon state via snapshot + replay
- Configure custom gas schedule (subsidized/zero fees for users)
- Set up dedicated validator set (ACX + institutional partners)

**Database Integration:**
- Store contract addresses in `contract_deployed` table with `contract_type` enum
- Add `network_id` field: `43114` (Avalanche) | `ACXNET_CHAIN_ID` (custom L1)
- Track deployment block numbers for indexer sync

### 3.4 Database Schema Changes

**New Tables:**

```sql
-- Wallet mappings
CREATE TABLE user_wallet (
    id INT PRIMARY KEY IDENTITY,
    user_id INT FOREIGN KEY REFERENCES [user](id),
    wallet_address NVARCHAR(42) UNIQUE NOT NULL,
    chain_id INT NOT NULL, -- 1=Ethereum, 137=Polygon, etc.
    created_at_utc DATETIME DEFAULT GETUTCDATE()
);

-- SwapBox tracking
CREATE TABLE swapbox_swap (
    id INT PRIMARY KEY IDENTITY,
    swap_box_id BIGINT NOT NULL,
    trade_id INT FOREIGN KEY REFERENCES trade(id),
    buyer_wallet NVARCHAR(42) NOT NULL,
    seller_wallet NVARCHAR(42) NOT NULL,
    fct_token_address NVARCHAR(42) NOT NULL,
    fct_amount DECIMAL(26,18) NOT NULL,
    stablecoin_address NVARCHAR(42) NOT NULL,
    stablecoin_amount DECIMAL(26,18) NOT NULL,
    status NVARCHAR(20) NOT NULL, -- Pending, BuyerDeposited, SellerDeposited, Completed, Cancelled
    expiry_timestamp DATETIME NOT NULL,
    created_at_utc DATETIME DEFAULT GETUTCDATE(),
    completed_at_utc DATETIME NULL
);
```

**Modified Tables:**

```sql
-- Add ERC-20 address to assets
ALTER TABLE x_asset
ADD erc20_address NVARCHAR(42) NULL,
    token_standard NVARCHAR(10) DEFAULT 'LEDGER' CHECK (token_standard IN ('LEDGER', 'ERC20', 'ERC1155'));

-- Add wallet support to user_account
ALTER TABLE user_account
ADD is_external_wallet BIT DEFAULT 0; -- True if user controls private key
```

### 3.5 Feature Toggle Implementation

**Configuration:**

```typescript
// config/features.ts
export const Features = {
  DPX_MODE: process.env.FEATURE_DPX_MODE === 'true',
  DPX_NETWORKS: process.env.DPX_NETWORKS?.split(',') || ['1', '137'], // Ethereum, Polygon
  SWAPBOX_ADDRESS: process.env.SWAPBOX_ADDRESS,
  FCT_FACTORY_ADDRESS: process.env.FCT_FACTORY_ADDRESS,
  USDC_ADDRESS: process.env.USDC_ADDRESS,
};
```

**Runtime Checks:**

```typescript
// utils/feature-toggle.ts
export function isDpxMode(): boolean {
  return Features.DPX_MODE;
}

export function getAuthStrategy(): 'credentials' | 'wallet' {
  return isDpxMode() ? 'wallet' : 'credentials';
}

export function getSettlementStrategy(): 'ledger' | 'swapbox' {
  return isDpxMode() ? 'swapbox' : 'ledger';
}
```

**Usage Example:**

```typescript
// services/order.service.ts
async function validateOrderBalance(userId: number, assetId: number, amount: number) {
  if (isDpxMode()) {
    const wallet = await getUserWallet(userId);
    const tokenAddress = await getAssetErc20Address(assetId);
    return await getWalletBalance(wallet, tokenAddress) >= amount;
  } else {
    return await getLedgerBalance(userId, assetId) >= amount;
  }
}
```

---

## 4. Technical Benefits of Unified Architecture

### 4.1 Codebase Efficiency

- **Single Codebase:** All logic shared between CPX/DPX reduces maintenance burden by ~50%
- **Shared Business Logic:** Order matching, risk management, entity permissions identical across modes
- **Unified Testing:** Test suite covers both modes with parameterized tests
- **No Code Duplication:** Feature toggles eliminate need for parallel implementations

### 4.2 Operational Flexibility

- **Gradual Migration:** Deploy CPX first, enable DPX for select entities via config toggle
- **Hybrid Deployments:** Same infrastructure supports both CPX (Indonesia) and DPX (global DeFi)
- **A/B Testing:** Run controlled experiments comparing centralized vs. decentralized UX
- **Rollback Safety:** Disable DPX mode instantly via env var if issues arise

### 4.3 Security & Compliance

- **Separation of Concerns:** Authentication, settlement, custody cleanly abstracted
- **Audit Trail:** All toggles logged; compliance teams can verify mode per entity
- **Custodial vs. Non-Custodial:** Clear distinction eliminates regulatory ambiguity
- **Smart Contract Upgradability:** SwapBox versioning allows fixes without redeploying core platform

### 4.4 Developer Experience

- **Consistent APIs:** Frontend devs interact with same endpoints regardless of mode
- **Type Safety:** TypeScript interfaces enforce correct toggle usage
- **Graceful Degradation:** If DPX features unavailable (e.g., wallet not connected), fall back to CPX UI
- **Documentation:** Single set of docs with mode-specific annotations

### 4.5 Performance & Scalability

- **Reduced Blockchain Load (CPX):** Batched ledger transactions save gas
- **Parallel Processing (DPX):** SwapBox deposits happen async, no bottleneck on ACX signers
- **Horizontal Scaling:** DPX eliminates centralized transaction queue; users settle directly
- **Lower Latency (DPX):** No admin approval required; settlement is peer-to-peer

### 4.6 Market Expansion

- **CPX (Centralized):** Ideal for jurisdictions requiring custodial oversight (Indonesia, Brazil)
- **DPX (Decentralized):** Attracts DeFi-native users, DAO treasuries, permissionless access
- **Cross-Mode Liquidity (Phase 2):** Unified order book allows CPX users to trade with DPX users via bridge

---

## 5. Implementation Roadmap

**Timeline:** 6-month development cycle targeting Phase 2 cross-mode liquidity by end Q2 2026 (June 30, 2026).

**Phase Overview:**
- **Phase 2 Cross-Mode Bridge:** May-June 2026 (8 weeks)
- **Phase 1D Production Scale:** March-April 2026 (8 weeks)
- **Phase 1C ACXNET Migration + DPX Mainnet:** January-February 2026 (8 weeks)
- **Phase 1B Development Sprint:** December 2025 (4 weeks)
- **Phase 1A Foundation:** November 2025 (4 weeks)

### 5.1 Phase 1A – Foundation (Nov 2025: 4 weeks)

**Smart Contracts:**
- [ ] Deploy `FctTokenFactory.sol` to **Avalanche Fuji testnet** (Chain ID: 43113)
- [ ] Deploy `SwapBox.sol` to Avalanche Fuji
- [ ] Write comprehensive test suite (Hardhat with Avalanche fork)
- [ ] Begin security audit (Ava Labs-recommended auditor: Halborn, Trail of Bits)

**CPX Network Migration Planning:**
- [ ] Design ACXNET subnet configuration (validator set, gas economics)
- [ ] Plan Polygon → ACXNET state migration strategy
- [ ] Set up ACXNET testnet environment

**Backend:**
- [ ] Implement SIWE authentication in `auth.service.ts`
- [ ] Add Avalanche RPC integration (`balance.ts`)
- [ ] Create `swapbox.service.ts` for swap configuration
- [ ] Add feature toggle framework (`features.ts`) with network-aware routing

**Database:**
- [ ] Create `user_wallet`, `swapbox_swap` tables
- [ ] Migrate `x_asset` to support `erc20_address`, `network_id`

**Deliverable:** Fully functional DPX testnet + ACXNET migration plan

### 5.2 Phase 1B – Development Sprint (Dec 2025: 4 weeks)

**Frontend:**
- [ ] Add WalletConnect integration targeting Avalanche C-Chain
- [ ] Build SwapBox deposit UI with AVAX gas estimation
- [ ] Update balance displays for wallet balances (USDC on Avalanche)
- [ ] Add approval flow for USDC (Avalanche contract addresses)

**Backend:**
- [ ] Refactor `apx.mintFctTokens` for dual-network support (Avalanche + ACXNET)
- [ ] Refactor `settle.executeSettle` to support SwapBox on Avalanche
- [ ] Add SwapBox event monitoring to indexer (Avalanche C-Chain sync)
- [ ] Implement ACXNET RPC integration for CPX mode

**Testing:**
- [ ] End-to-end test: Wallet login → mint FCT on Avalanche → place order → settle via SwapBox
- [ ] Integration test: CPX (ACXNET testnet) and DPX (Avalanche Fuji) modes side-by-side
- [ ] Load testing: 1000+ concurrent orders across both networks

**Security:**
- [ ] Complete external smart contract audit
- [ ] Remediate critical/high findings
- [ ] Launch bug bounty program ($50K rewards)

**Deliverable:** Production-ready codebase for both networks

### 5.3 Phase 1C – Network Migrations & Mainnet Launch (Jan-Feb 2026: 8 weeks)

**ACXNET Custom L1 Launch + Polygon Decommission (Weeks 1-4):**
- [ ] Deploy ACXNET subnet validators (minimum 5 institutional partners)
- [ ] Deploy STMv2 ledger contract to ACXNET
- [ ] Snapshot Polygon ACX/CPX state (all ledger balances, assets, trades, spot market data)
- [ ] Migrate ACX/CPX platform to ACXNET (includes CPX marketplace + spot/CLOB market)
- [ ] **Hard cutover:** Switch all traffic to ACXNET, decommission Polygon simultaneously
- [ ] Monitor 24/7 for 1 week post-cutover

**DPX Avalanche Mainnet Launch (Weeks 5-8):**
- [ ] Deploy FctTokenFactory + SwapBox to Avalanche C-Chain mainnet
- [ ] Configure backend with mainnet contract addresses
- [ ] Deploy indexer for Avalanche C-Chain event tracking
- [ ] Launch DPX mode with handpicked projects and buyers familiar with DeFi/crypto primitives
- [ ] Monitor swap completion rates (target: >95%)

**Operations:**
- [ ] Set up Grafana dashboards for both networks (ACXNET + Avalanche)
- [ ] Configure alerts: expired swaps, failed txs, network congestion
- [ ] Train support team on dual-network troubleshooting

**Documentation:**
- [ ] User guide: "Trading on DPX (Avalanche) vs. CPX (ACXNET)"
- [ ] Admin guide: "Network-Specific Configuration"
- [ ] API docs: Updated with network parameters

**Deliverable:** Both CPX (ACXNET) and DPX (Avalanche) live in production

### 5.4 Phase 1D – Production Scale & Optimization (Mar-Apr 2026: 8 weeks)

**Rollout:**
- [ ] Expand DPX to additional crypto-native projects and buyers on Avalanche C-Chain
- [ ] All ACX/CPX entities fully operational on ACXNET (Polygon decommissioned in Phase 1C)
- [ ] Launch $ACR token staking for swap fee discounts
- [ ] Implement KYC/AML framework (tiered: self-attestation → document verification)
- [ ] Deploy geofencing controls based on legal/operational requirements

**Optimization:**
- [ ] Investigate market appetite for DEX liquidity pools (e.g., Trader Joe FCT/USDC pairs)
- [ ] Add support for USDT, DAI on Avalanche
- [ ] Implement batch swap settlement (reduce gas costs 30%)
- [ ] Enable Core Wallet, Rabby Wallet support (beyond Metamask)

**Performance Targets:**
- [ ] DPX: <$1 average gas cost per swap (Avalanche)
- [ ] CPX: <$0.01 gas cost (subsidized on ACXNET)
- [ ] 1,000+ active DPX wallets
- [ ] $15M+ USDC volume via SwapBox

**Deliverable:** Scaled production systems ready for Phase 2 bridge

---

### Phase 2 Preview – Cross-Mode Liquidity Bridge (May-Jun 2026: 8 weeks)

**Goal:** Enable seamless trading between CPX (ACXNET ledger) and DPX (Avalanche ERC-20) users

**Architecture:**
1. **Bridge Contract (Avalanche):**
   - Lock FCT ERC-20 on Avalanche → unlock equivalent on ACXNET ledger
   - Burn ledger FCT on ACXNET → mint ERC-20 on Avalanche

2. **Unified Order Book:**
   - Matching engine matches CPX bids with DPX asks transparently
   - Backend routes settlements to appropriate network

3. **Market Maker Incentives:**
   - $ACR token rewards for providing cross-mode liquidity
   - Reduced trading fees for bridge users

**Technical Challenges:**
- Cross-chain message passing (likely Avalanche Warp Messaging or Axelar)
- Atomic settlement guarantees across two L1s
- Liquidity balancing between networks

**Deliverable (End Q2 2026):** Unified liquidity pool, CPX ↔ DPX interoperability

**Success Metric:** >$50M combined TVL across ACXNET + Avalanche

---

## 6. Risk Mitigation

### 6.1 Smart Contract Risks

**Risk:** SwapBox bugs could lock user funds  
**Mitigation:**
- Comprehensive test coverage (>95%)
- External security audit (Trail of Bits, OpenZeppelin)
- Bug bounty program ($50K reward for critical vulnerabilities)
- Emergency pause mechanism (admin can disable SwapBox temporarily)

### 6.2 User Experience Risks

**Risk:** Users unfamiliar with wallets may struggle with DPX  
**Mitigation:**
- In-app tooltips explaining wallet approval, gas fees
- Fallback to CPX mode for users without wallets
- 24/7 support chat with wallet onboarding assistance

### 6.3 Liquidity Fragmentation

**Risk:** CPX and DPX liquidity pools separate, reducing depth  
**Mitigation:**
- Phase 2 will introduce **cross-mode bridge** (covered in separate ARR)
- Unified order book routing matches CPX bids with DPX asks
- Market makers incentivized to provide liquidity across both modes

### 6.4 Regulatory Uncertainty

**Risk:** Some jurisdictions may prohibit non-custodial exchanges  
**Mitigation:**
- DPX deployed only in permissive jurisdictions initially (Singapore, Switzerland, UAE)
- Legal review per market before launch
- Geofencing via IP checks + KYC verification

---

## 7. Success Metrics

### 7.1 Technical Metrics

- **Swap Success Rate:** >95% of configured SwapBoxes complete successfully
- **Settlement Latency:** <10 minutes average from match to completion
- **Gas Efficiency:** <$5 average cost per swap (on Polygon)
- **Uptime:** 99.9% availability for DPX APIs

### 7.2 Business Metrics

- **User Adoption:** 500+ active DPX wallets within 6 months
- **Trading Volume:** $10M+ USDC volume settled via SwapBox in first quarter
- **Liquidity Retention:** <5% slippage on top 10 FCT/USDC pairs
- **Customer Satisfaction:** >4.5/5 rating for DPX user experience

### 7.3 Operational Metrics

- **Codebase Health:** <10% code duplication between CPX/DPX branches
- **Deployment Efficiency:** <1 hour to toggle DPX mode for new entity
- **Incident Response:** <2 hours to rollback DPX mode if critical bug detected

---

## 8. Conclusion

The transition from CPX to DPX represents a **paradigm shift** in how AirCarbon delivers carbon market infrastructure. By maintaining a **single, feature-toggle-driven codebase**, we achieve:

1. **Operational Efficiency:** No parallel codebases to maintain
2. **Market Flexibility:** Serve both custodial and non-custodial user bases
3. **Future-Proofing:** Foundation for Phase 2 cross-mode liquidity
4. **Risk Management:** Gradual, controlled rollout with instant rollback capability

The **SwapBox** smart contract is the linchpin of this architecture, enabling trustless settlement while preserving the exchange-grade matching engine and risk management that differentiates AirCarbon from pure DEXs.

**Phase 1 delivers:**
- Metamask login for DPX users
- True ERC-20 FCT tokens (non-custodial)
- USDC-based payments (user-controlled wallets)
- SwapBox bilateral settlement (on-chain escrow)
- Single codebase with runtime toggles (zero fragmentation)

**Phase 2 will extend this foundation to enable:**
- Cross-mode liquidity (CPX ↔ DPX bridge)
- Multi-chain deployments (Ethereum, Polygon, Arbitrum, Base)
- Advanced DeFi integrations (Uniswap liquidity pools, Aave collateralization)
- DAO governance for protocol parameters

This ARR provides a **clear technical roadmap** to achieve the ACXRWA whitepaper vision: a scalable, institution-ready, DeFi-compatible global carbon finance infrastructure.

---


---

## Appendix A: SwapBox Gas Cost Analysis (Avalanche C-Chain)

| Operation | Gas Used | Cost @ 25 nAVAX | Cost @ 50 nAVAX | Cost @ 100 nAVAX |
|-----------|----------|-----------------|-----------------|------------------|
| Configure Swap | 120,000 | $0.09 | $0.18 | $0.36 |
| Deposit USDC | 80,000 | $0.06 | $0.12 | $0.24 |
| Deposit FCT | 80,000 | $0.06 | $0.12 | $0.24 |
| **Total per Trade** | **280,000** | **$0.21** | **$0.42** | **$0.84** |

*Assumptions: AVAX = $30, gas price 25-100 nAVAX (typical Avalanche C-Chain range during normal congestion)*

**Avalanche vs. Other Networks:**

| Network | Avg. Cost per Swap | Block Time | Finality |
|---------|-------------------|------------|----------|
| **Avalanche C-Chain** | **$0.21 - $0.84** | **2 seconds** | **<2 seconds** |
| Polygon PoS | $0.05 - $0.50 | 2 seconds | ~30 seconds |
| Arbitrum | $0.50 - $5.00 | ~0.3 seconds | ~15 minutes (L1 finality) |
| Ethereum Mainnet | $15 - $150 | 12 seconds | 12-15 minutes |

**Why Avalanche C-Chain:**
- Sub-second finality (faster than Polygon, Arbitrum)
- Low gas costs (~$0.42 typical)
- High throughput (4,500 TPS on C-Chain)
- Native institutional adoption (Ava Labs partnerships)
- Subnet extensibility for future ACXNET integration
- Strong DeFi ecosystem (Trader Joe, Aave, Benqi)

**ACXNET Custom L1 Gas Costs:**
- **Subsidized Model:** ACX covers all gas costs for CPX users
- **Effective cost to user:** $0.00
- **Backend cost to ACX:** <$0.01 per transaction (subsidized validator rewards)
- **Benefit:** Institutional users experience zero blockchain friction

---

## Appendix B: Feature Toggle Configuration Example

```bash
# .env.dpx (DPX mode enabled - Avalanche C-Chain)
FEATURE_DPX_MODE=true
DPX_NETWORK_ID=43114  # Avalanche C-Chain Mainnet
DPX_TESTNET_ID=43113  # Avalanche Fuji Testnet
DPX_RPC_URL=https://api.avax.network/ext/bc/C/rpc
DPX_EXPLORER=https://snowtrace.io

# Smart Contract Addresses (Avalanche Mainnet)
SWAPBOX_ADDRESS_AVALANCHE=0x... # TBD upon deployment
FCT_FACTORY_ADDRESS_AVALANCHE=0x... # TBD upon deployment
USDC_ADDRESS_AVALANCHE=0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
USDT_ADDRESS_AVALANCHE=0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7

# .env.cpx (CPX mode - ACXNET custom L1)
FEATURE_DPX_MODE=false
CPX_NETWORK_ID=ACXNET_CHAIN_ID # TBD during subnet deployment
CPX_RPC_URL=https://rpc.acxnet.io # Custom subnet RPC
CPX_EXPLORER=https://explorer.acxnet.io # Custom subnet explorer

# STMv2 Ledger Contract (ACXNET)
STMV2_ADDRESS_ACXNET=0x... # Migrated from Polygon
ROOT_ACCOUNT_ACXNET=0x... # ACX admin signer

# Network Migration Config (Hard Cutover)
POLYGON_SNAPSHOT_BLOCK=... # Final Polygon block before hard cutover
ACXNET_GENESIS_BLOCK=... # First ACXNET block after migration
```

---

## Appendix C: Cross-Reference to Whitepaper Sections

| Whitepaper Section | ARR Implementation |
|--------------------|--------------------|
| **Section 4.1 – Listing Engine** | Unchanged; PINs apply to both CPX/DPX |
| **Section 4.2 – Tokenization** | DPX: ERC-20 factory; CPX: Existing ledger |
| **Section 4.3 – Primary Auctions** | Unchanged; settlement method varies (SwapBox vs. ledger) |
| **Section 4.4 – CPX Secondary Market** | DPX variant uses SwapBox; order book logic identical |
| **Section 4.5 – Filtering** | Unchanged; applies to both modes |
| **Section 7 – Technical Design** | DPX extends with ERC-20 + SwapBox; CPX retains ACXv2 ledger |

---

*End of Architecture Refactoring Roadmap – Phase 1*

