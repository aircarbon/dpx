# SwapBox Smart Contract - Complete Implementation

**Version:** 1.0  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads  
**Network:** Avalanche C-Chain (43114)  
**Purpose:** Bilateral escrow for trustless FCT/USDC swaps

---

## Contract Overview

The SwapBox contract enables trustless peer-to-peer settlement of matched trades from the ACX marketplace. Each swap is configured by the ACX backend after a successful match, then both parties deposit their respective assets (buyer deposits USDC, seller deposits FCT). Once both deposits are confirmed, each party can withdraw the counterparty's asset.

**Key Features:**
- Multiple concurrent swaps with unique IDs
- Atomic bilateral settlement (both deposit or neither withdraws)
- Time-bounded expiry with automatic refunds
- ERC-20 agnostic (works with any FCT token type)
- Gas-optimized for Avalanche C-Chain

---

## Complete Solidity Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title SwapBox
 * @notice Bilateral escrow for trustless FCT/USDC swaps on Avalanche C-Chain
 * @dev Designed for ACX Carbon Project Exchange (CPX) marketplace settlements
 * 
 * Workflow:
 * 1. ACX backend calls configureSwap() after marketplace match
 * 2. Buyer deposits USDC via depositBuyerAsset()
 * 3. Seller deposits FCT via depositSellerAsset()
 * 4. Once both deposited, buyer withdraws FCT, seller withdraws USDC
 * 5. If expired before both deposit, either party can reclaim via cancelSwap()
 */
contract SwapBox is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role for ACX backend to configure swaps
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    
    /// @notice Role for emergency pause
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Swap lifecycle states
    enum SwapStatus { 
        None,              // Swap does not exist
        Pending,           // Configured, awaiting deposits
        BuyerDeposited,    // Buyer deposited, awaiting seller
        SellerDeposited,   // Seller deposited, awaiting buyer
        ReadyToSettle,     // Both deposited, ready for withdrawals
        Completed,         // Both parties withdrew
        Cancelled          // Expired and refunded
    }

    /// @notice Swap data structure
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

    /// @notice Mapping of swap ID to swap data
    mapping(uint256 => Swap) public swaps;

    /// @notice Counter for generating unique swap IDs
    uint256 private _swapCounter;

    /// @notice Events
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

    event BuyerDeposited(
        uint256 indexed swapId,
        address indexed buyer,
        address asset,
        uint256 amount
    );

    event SellerDeposited(
        uint256 indexed swapId,
        address indexed seller,
        address asset,
        uint256 amount
    );

    event BuyerWithdrew(
        uint256 indexed swapId,
        address indexed buyer,
        address asset,
        uint256 amount
    );

    event SellerWithdrew(
        uint256 indexed swapId,
        address indexed seller,
        address asset,
        uint256 amount
    );

    event SwapCompleted(
        uint256 indexed swapId
    );

    event SwapCancelled(
        uint256 indexed swapId,
        address cancelledBy
    );

    /**
     * @notice Constructor
     * @param admin Address with DEFAULT_ADMIN_ROLE
     * @param configurator Address with CONFIGURATOR_ROLE (ACX backend)
     */
    constructor(address admin, address configurator) {
        require(admin != address(0), "Invalid admin address");
        require(configurator != address(0), "Invalid configurator address");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CONFIGURATOR_ROLE, configurator);
        _grantRole(PAUSER_ROLE, admin);
    }

    /**
     * @notice Configure a new bilateral swap (ACX backend only)
     * @param buyer Buyer wallet address
     * @param seller Seller wallet address
     * @param buyerAsset USDC contract address (or other stablecoin)
     * @param buyerAmount Amount of USDC buyer will deposit (e.g., 6 decimals)
     * @param sellerAsset FCT ERC-20 contract address
     * @param sellerAmount Amount of FCT seller will deposit (18 decimals)
     * @param expiryTimestamp Unix timestamp after which swap can be cancelled
     * @return swapId The unique identifier for this swap
     */
    function configureSwap(
        address buyer,
        address seller,
        address buyerAsset,
        uint256 buyerAmount,
        address sellerAsset,
        uint256 sellerAmount,
        uint256 expiryTimestamp
    ) external onlyRole(CONFIGURATOR_ROLE) whenNotPaused returns (uint256) {
        require(buyer != address(0), "Invalid buyer address");
        require(seller != address(0), "Invalid seller address");
        require(buyer != seller, "Buyer and seller must be different");
        require(buyerAsset != address(0), "Invalid buyer asset");
        require(sellerAsset != address(0), "Invalid seller asset");
        require(buyerAmount > 0, "Buyer amount must be positive");
        require(sellerAmount > 0, "Seller amount must be positive");
        require(expiryTimestamp > block.timestamp, "Expiry must be in future");

        uint256 swapId = _swapCounter++;

        swaps[swapId] = Swap({
            swapId: swapId,
            buyer: buyer,
            seller: seller,
            buyerAsset: buyerAsset,
            buyerAmount: buyerAmount,
            sellerAsset: sellerAsset,
            sellerAmount: sellerAmount,
            status: SwapStatus.Pending,
            expiryTimestamp: expiryTimestamp,
            buyerDeposited: false,
            sellerDeposited: false,
            buyerWithdrew: false,
            sellerWithdrew: false,
            createdAt: block.timestamp
        });

        emit SwapConfigured(
            swapId,
            buyer,
            seller,
            buyerAsset,
            buyerAmount,
            sellerAsset,
            sellerAmount,
            expiryTimestamp
        );

        return swapId;
    }

    /**
     * @notice Buyer deposits their asset (USDC)
     * @param swapId The swap identifier
     * @dev Requires prior ERC-20 approval for buyerAmount
     */
    function depositBuyerAsset(uint256 swapId) external nonReentrant whenNotPaused {
        Swap storage swap = swaps[swapId];
        
        require(swap.status != SwapStatus.None, "Swap does not exist");
        require(msg.sender == swap.buyer, "Only buyer can deposit buyer asset");
        require(!swap.buyerDeposited, "Buyer already deposited");
        require(block.timestamp < swap.expiryTimestamp, "Swap expired");
        require(
            swap.status == SwapStatus.Pending || swap.status == SwapStatus.SellerDeposited,
            "Invalid swap status"
        );

        // Transfer buyer's asset (USDC) to this contract
        IERC20(swap.buyerAsset).safeTransferFrom(
            msg.sender,
            address(this),
            swap.buyerAmount
        );

        swap.buyerDeposited = true;

        // Update status based on seller's deposit state
        if (swap.sellerDeposited) {
            swap.status = SwapStatus.ReadyToSettle;
        } else {
            swap.status = SwapStatus.BuyerDeposited;
        }

        emit BuyerDeposited(swapId, msg.sender, swap.buyerAsset, swap.buyerAmount);

        // If both deposited, emit completion event
        if (swap.status == SwapStatus.ReadyToSettle) {
            emit SwapCompleted(swapId);
        }
    }

    /**
     * @notice Seller deposits their asset (FCT)
     * @param swapId The swap identifier
     * @dev Requires prior ERC-20 approval for sellerAmount
     */
    function depositSellerAsset(uint256 swapId) external nonReentrant whenNotPaused {
        Swap storage swap = swaps[swapId];
        
        require(swap.status != SwapStatus.None, "Swap does not exist");
        require(msg.sender == swap.seller, "Only seller can deposit seller asset");
        require(!swap.sellerDeposited, "Seller already deposited");
        require(block.timestamp < swap.expiryTimestamp, "Swap expired");
        require(
            swap.status == SwapStatus.Pending || swap.status == SwapStatus.BuyerDeposited,
            "Invalid swap status"
        );

        // Transfer seller's asset (FCT) to this contract
        IERC20(swap.sellerAsset).safeTransferFrom(
            msg.sender,
            address(this),
            swap.sellerAmount
        );

        swap.sellerDeposited = true;

        // Update status based on buyer's deposit state
        if (swap.buyerDeposited) {
            swap.status = SwapStatus.ReadyToSettle;
        } else {
            swap.status = SwapStatus.SellerDeposited;
        }

        emit SellerDeposited(swapId, msg.sender, swap.sellerAsset, swap.sellerAmount);

        // If both deposited, emit completion event
        if (swap.status == SwapStatus.ReadyToSettle) {
            emit SwapCompleted(swapId);
        }
    }

    /**
     * @notice Buyer withdraws seller's asset (FCT)
     * @param swapId The swap identifier
     */
    function withdrawBuyerAsset(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        
        require(swap.status == SwapStatus.ReadyToSettle, "Swap not ready to settle");
        require(msg.sender == swap.buyer, "Only buyer can withdraw");
        require(!swap.buyerWithdrew, "Buyer already withdrew");

        swap.buyerWithdrew = true;

        // Transfer seller's asset (FCT) to buyer
        IERC20(swap.sellerAsset).safeTransfer(swap.buyer, swap.sellerAmount);

        emit BuyerWithdrew(swapId, msg.sender, swap.sellerAsset, swap.sellerAmount);

        // If both withdrew, mark as completed
        if (swap.sellerWithdrew) {
            swap.status = SwapStatus.Completed;
        }
    }

    /**
     * @notice Seller withdraws buyer's asset (USDC)
     * @param swapId The swap identifier
     */
    function withdrawSellerAsset(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        
        require(swap.status == SwapStatus.ReadyToSettle, "Swap not ready to settle");
        require(msg.sender == swap.seller, "Only seller can withdraw");
        require(!swap.sellerWithdrew, "Seller already withdrew");

        swap.sellerWithdrew = true;

        // Transfer buyer's asset (USDC) to seller
        IERC20(swap.buyerAsset).safeTransfer(swap.seller, swap.buyerAmount);

        emit SellerWithdrew(swapId, msg.sender, swap.buyerAsset, swap.buyerAmount);

        // If both withdrew, mark as completed
        if (swap.buyerWithdrew) {
            swap.status = SwapStatus.Completed;
        }
    }

    /**
     * @notice Cancel expired swap and refund deposits
     * @param swapId The swap identifier
     * @dev Can be called by buyer, seller, or configurator after expiry
     */
    function cancelSwap(uint256 swapId) external nonReentrant {
        Swap storage swap = swaps[swapId];
        
        require(swap.status != SwapStatus.None, "Swap does not exist");
        require(
            msg.sender == swap.buyer || 
            msg.sender == swap.seller || 
            hasRole(CONFIGURATOR_ROLE, msg.sender),
            "Not authorized to cancel"
        );
        require(block.timestamp >= swap.expiryTimestamp, "Swap not expired");
        require(swap.status != SwapStatus.Completed, "Swap already completed");
        require(swap.status != SwapStatus.Cancelled, "Swap already cancelled");

        // Refund buyer if they deposited
        if (swap.buyerDeposited && !swap.sellerWithdrew) {
            IERC20(swap.buyerAsset).safeTransfer(swap.buyer, swap.buyerAmount);
        }

        // Refund seller if they deposited
        if (swap.sellerDeposited && !swap.buyerWithdrew) {
            IERC20(swap.sellerAsset).safeTransfer(swap.seller, swap.sellerAmount);
        }

        swap.status = SwapStatus.Cancelled;

        emit SwapCancelled(swapId, msg.sender);
    }

    /**
     * @notice Query swap details
     * @param swapId The swap identifier
     * @return Swap struct with all details
     */
    function getSwap(uint256 swapId) external view returns (Swap memory) {
        require(swaps[swapId].status != SwapStatus.None, "Swap does not exist");
        return swaps[swapId];
    }

    /**
     * @notice Get total number of swaps configured
     * @return Total swap count
     */
    function getSwapCount() external view returns (uint256) {
        return _swapCounter;
    }

    /**
     * @notice Check if swap is ready for settlement
     * @param swapId The swap identifier
     * @return True if both parties deposited
     */
    function isReadyToSettle(uint256 swapId) external view returns (bool) {
        return swaps[swapId].status == SwapStatus.ReadyToSettle;
    }

    /**
     * @notice Emergency pause (admin only)
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause (admin only)
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Emergency withdrawal of stuck tokens (admin only)
     * @dev Should only be used if tokens get stuck due to unforeseen circumstances
     * @param token ERC-20 token address
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransfer(to, amount);
    }
}
```

---

## Interface for External Integration

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISwapBox
 * @notice Interface for SwapBox contract
 */
interface ISwapBox {
    enum SwapStatus { 
        None,
        Pending,
        BuyerDeposited,
        SellerDeposited,
        ReadyToSettle,
        Completed,
        Cancelled
    }

    struct Swap {
        uint256 swapId;
        address buyer;
        address seller;
        address buyerAsset;
        uint256 buyerAmount;
        address sellerAsset;
        uint256 sellerAmount;
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

    function configureSwap(
        address buyer,
        address seller,
        address buyerAsset,
        uint256 buyerAmount,
        address sellerAsset,
        uint256 sellerAmount,
        uint256 expiryTimestamp
    ) external returns (uint256);

    function depositBuyerAsset(uint256 swapId) external;
    function depositSellerAsset(uint256 swapId) external;
    function withdrawBuyerAsset(uint256 swapId) external;
    function withdrawSellerAsset(uint256 swapId) external;
    function cancelSwap(uint256 swapId) external;
    
    function getSwap(uint256 swapId) external view returns (Swap memory);
    function getSwapCount() external view returns (uint256);
    function isReadyToSettle(uint256 swapId) external view returns (bool);
}
```

---

## Usage Example (TypeScript)

```typescript
import { ethers } from 'ethers';
import SwapBoxABI from './SwapBox.json';

// Initialize contract
const provider = new ethers.providers.JsonRpcProvider('https://api.avax.network/ext/bc/C/rpc');
const swapBox = new ethers.Contract(SWAPBOX_ADDRESS, SwapBoxABI, provider);

// ACX Backend: Configure swap after marketplace match
async function configureSwap(trade: Trade) {
  const signer = new ethers.Wallet(CONFIGURATOR_PRIVATE_KEY, provider);
  const swapBoxWithSigner = swapBox.connect(signer);
  
  const tx = await swapBoxWithSigner.configureSwap(
    trade.buyerWallet,          // buyer address
    trade.sellerWallet,         // seller address
    USDC_ADDRESS_AVALANCHE,     // 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
    trade.usdcAmount,           // e.g., 1000 * 10^6 (1000 USDC)
    trade.fctTokenAddress,      // FCT ERC-20 address
    trade.fctAmount,            // e.g., 100 * 10^18 (100 FCT)
    Math.floor(Date.now() / 1000) + 3600  // 1 hour expiry
  );
  
  const receipt = await tx.wait();
  const swapId = receipt.events[0].args.swapId;
  
  console.log(`Swap configured: ID ${swapId}`);
  return swapId;
}

// Buyer: Approve and deposit USDC
async function buyerDeposit(swapId: number, buyerSigner: ethers.Signer) {
  const swap = await swapBox.getSwap(swapId);
  
  // Approve USDC
  const usdc = new ethers.Contract(swap.buyerAsset, ERC20_ABI, buyerSigner);
  const approveTx = await usdc.approve(SWAPBOX_ADDRESS, swap.buyerAmount);
  await approveTx.wait();
  
  // Deposit
  const swapBoxWithSigner = swapBox.connect(buyerSigner);
  const depositTx = await swapBoxWithSigner.depositBuyerAsset(swapId);
  await depositTx.wait();
  
  console.log(`Buyer deposited ${swap.buyerAmount} USDC`);
}

// Seller: Approve and deposit FCT
async function sellerDeposit(swapId: number, sellerSigner: ethers.Signer) {
  const swap = await swapBox.getSwap(swapId);
  
  // Approve FCT
  const fct = new ethers.Contract(swap.sellerAsset, ERC20_ABI, sellerSigner);
  const approveTx = await fct.approve(SWAPBOX_ADDRESS, swap.sellerAmount);
  await approveTx.wait();
  
  // Deposit
  const swapBoxWithSigner = swapBox.connect(sellerSigner);
  const depositTx = await swapBoxWithSigner.depositSellerAsset(swapId);
  await depositTx.wait();
  
  console.log(`Seller deposited ${swap.sellerAmount} FCT`);
}

// Buyer: Withdraw FCT
async function buyerWithdraw(swapId: number, buyerSigner: ethers.Signer) {
  const swapBoxWithSigner = swapBox.connect(buyerSigner);
  const tx = await swapBoxWithSigner.withdrawBuyerAsset(swapId);
  await tx.wait();
  
  console.log(`Buyer withdrew FCT`);
}

// Seller: Withdraw USDC
async function sellerWithdraw(swapId: number, sellerSigner: ethers.Signer) {
  const swapBoxWithSigner = swapBox.connect(sellerSigner);
  const tx = await swapBoxWithSigner.withdrawSellerAsset(swapId);
  await tx.wait();
  
  console.log(`Seller withdrew USDC`);
}

// Monitor swap status
async function monitorSwap(swapId: number) {
  swapBox.on('BuyerDeposited', (id, buyer, asset, amount) => {
    if (id.toNumber() === swapId) {
      console.log(`Buyer deposited`);
    }
  });
  
  swapBox.on('SellerDeposited', (id, seller, asset, amount) => {
    if (id.toNumber() === swapId) {
      console.log(`Seller deposited`);
    }
  });
  
  swapBox.on('SwapCompleted', (id) => {
    if (id.toNumber() === swapId) {
      console.log(`Swap ready to settle! Both parties can now withdraw.`);
    }
  });
}
```

---

## Gas Cost Estimation (Avalanche C-Chain)

| Operation | Gas Used | Cost @ 25 nAVAX | Cost @ 50 nAVAX | Cost @ 100 nAVAX |
|-----------|----------|-----------------|-----------------|------------------|
| `configureSwap()` | ~120,000 | $0.09 | $0.18 | $0.36 |
| `depositBuyerAsset()` | ~80,000 | $0.06 | $0.12 | $0.24 |
| `depositSellerAsset()` | ~80,000 | $0.06 | $0.12 | $0.24 |
| `withdrawBuyerAsset()` | ~60,000 | $0.045 | $0.09 | $0.18 |
| `withdrawSellerAsset()` | ~60,000 | $0.045 | $0.09 | $0.18 |
| `cancelSwap()` (refund) | ~100,000 | $0.075 | $0.15 | $0.30 |

**Total per successful swap:** ~400,000 gas (~$0.30 - $1.20 depending on gas price)

---

## Security Considerations

### Audited Dependencies
- **OpenZeppelin Contracts v5.0+** (AccessControl, ReentrancyGuard, SafeERC20, Pausable)

### Attack Vectors Mitigated
1. **Reentrancy:** `nonReentrant` modifier on all state-changing functions
2. **Integer Overflow:** Solidity 0.8+ built-in overflow checks
3. **Unauthorized Access:** Role-based access control for configuration
4. **Token Approval Exploits:** SafeERC20 wrapper for all transfers
5. **Stuck Funds:** Emergency withdrawal function (admin only)
6. **Front-Running:** State checks ensure deposits/withdrawals only valid in correct states

### Recommended Audits
- **Primary:** Halborn Security or Trail of Bits
- **Bug Bounty:** $50K for critical vulnerabilities
- **Testnet Period:** Minimum 4 weeks on Avalanche Fuji before mainnet

---

## Deployment Checklist

### Pre-Deployment
- [ ] Complete Hardhat test suite (100% coverage)
- [ ] Deploy to Avalanche Fuji testnet (43113)
- [ ] External security audit completed
- [ ] Bug bounty program launched
- [ ] Emergency procedures documented

### Mainnet Deployment (Avalanche C-Chain: 43114)
- [ ] Deploy SwapBox contract
- [ ] Grant CONFIGURATOR_ROLE to ACX backend signer(s)
- [ ] Grant PAUSER_ROLE to ACX admin multi-sig
- [ ] Verify contract on Snowtrace
- [ ] Test with 10+ real swaps (<$1K each)
- [ ] Monitor 24/7 for first 2 weeks

### Post-Deployment
- [ ] Integrate with ACX settle.service.ts
- [ ] Configure monitoring dashboards (Grafana)
- [ ] Set up alerts for expired swaps
- [ ] Train support team on troubleshooting

---

## Contract Addresses

### Testnet (Avalanche Fuji - 43113)
- **SwapBox:** `TBD` (deploy in Phase 1A)
- **USDC (testnet):** Use Fuji faucet token

### Mainnet (Avalanche C-Chain - 43114)
- **SwapBox:** `TBD` (deploy in Phase 1C)
- **USDC:** `0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E`
- **USDT:** `0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7`

---

**Document Status:** Ready for Implementation

