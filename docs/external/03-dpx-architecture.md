# DPX Architecture

## Overview

DPX (Decentralized Project Exchange) is a non-custodial protocol for tokenizing Future Carbon Credits derived from Emission Reduction Purchase Agreements (ERPAs) as tradeable RWAs. Unlike CPX's custodial model, DPX enables users to hold assets in their own wallets, execute trades through trustless smart contracts, and integrate with the broader DeFi ecosystem.

### Protocol Vision

DPX is designed as a comprehensive carbon RWA infrastructure protocol with three core functions:

1. **Tokenization:** Converting ERPAs into ERC-20 compliant Future Carbon Tokens (FCTs) that represent claims on future carbon credit deliveries
2. **Trading:** Facilitating trustless peer-to-peer exchange of FCT tokens through the SwapBox mechanism
3. **Redemption:** Enabling token holders to claim their pro-rata share of proceeds when underlying carbon credits are sold

The long-term vision for DPX extends beyond these core functions. As the protocol matures, it will evolve toward greater decentralization through DAO governance—enabling token holders to participate in key protocol decisions such as project listing criteria, fee structures, and platform development priorities. This progressive decentralization ensures that DPX can adapt to the needs of its community while maintaining the security and reliability required for RWA infrastructure.

This section details the current technical architecture and core components that form the foundation for this vision.

---

## Network Choice: Avalanche C-Chain

DPX is deployed on **Avalanche C-Chain**, the primary smart contract platform within the Avalanche ecosystem.

### Why Avalanche

**Technical Advantages:**
- **Sub-Second Finality:** Transactions achieve finality in under 2 seconds, enabling near-instant settlement
- **Low Transaction Costs:** Typical swap costs approximately $0.40-0.50, making small trades economically viable
- **High Throughput:** 4,500+ transactions per second on C-Chain
- **EVM Compatibility:** Full Ethereum Virtual Machine compatibility enables use of standard tooling, libraries, and developer expertise

**Ecosystem Benefits:**
- **Established DeFi Ecosystem:** Native integration potential with protocols like Trader Joe, Aave, Benqi, and other Avalanche-native DeFi applications
- **Institutional Credibility:** Avalanche has significant institutional adoption and partnerships with traditional finance entities
- **Native USDC Support:** Circle's native USDC deployment on Avalanche provides reliable stablecoin infrastructure
- **Large Total Value Locked:** Avalanche hosts billions in TVL across DeFi protocols, indicating ecosystem maturity and liquidity depth

**Strategic Alignment with ACXNET:**
Avalanche's subnet architecture provides a natural bridge to ACXNET (ACX's custom Avalanche subnet for CPX). Both networks exist within the Avalanche ecosystem, enabling future cross-chain liquidity through Avalanche's native interoperability features. This positions DPX for seamless integration with institutional CPX liquidity in later phases.

---

## Wallet-Based Authentication

DPX uses wallet-based authentication instead of traditional username/password systems, aligning with Web3 standards for decentralized identity.

### How It Works

When a user connects to DPX:

1. **Wallet Connection:** User connects their Web3 wallet (MetaMask, Core Wallet, WalletConnect-compatible wallets)
2. **Message Signing:** The platform presents a unique message containing a nonce (random value) and timestamp
3. **Cryptographic Verification:** User signs the message with their private key—this is a signature operation only, not a transaction, so no gas is consumed
4. **Session Creation:** The backend verifies the signature cryptographically, confirming the user controls the wallet address, and issues a session token

### Advantages

- **No Passwords:** Eliminates password management, reset flows, and credential storage risks
- **Self-Sovereign Identity:** Users control their identity through their wallet—no centralized identity provider
- **Gas-Free Authentication:** Signing a message costs nothing; only actual asset transactions require gas
- **Hardware Wallet Support:** Users can authenticate with hardware wallets (Ledger, Trezor) for enhanced security
- **Portable Identity:** The same wallet address works across all Web3 applications

This approach enables permissionless global access while maintaining the ability to implement compliance layers (KYC verification linked to wallet addresses) as needed.

---

## Core Smart Contracts

DPX is powered by three primary smart contract systems, each serving a distinct purpose in the Future Carbon Credit tokenization lifecycle.

### FctFactory: Project Registry & Token Deployment

The **FctFactory** is the central registry and factory contract for all DPX projects. It manages the lifecycle of Future Carbon Credit tokenization from project creation through redemption.

**Responsibilities:**
- **Project Registration:** Maintains a registry of all tokenized carbon projects with metadata (name, vintage year, registry code, custom attributes)
- **Token Deployment:** Automatically deploys a new FutureCarbonToken (FCT) contract for each approved project
- **Vault Deployment:** Deploys RedemptionVault contracts when projects reach the redemption phase
- **Registry Mappings:** Maintains bidirectional lookups between project IDs, token addresses, and vault addresses

**Design Rationale:**
- **Upgradeability:** FctFactory uses the UUPS (Universal Upgradeable Proxy Standard) pattern, allowing the platform to add features or fix issues without disrupting existing projects
- **Centralized Registry:** A single factory ensures consistent token standards and enables platform-wide queries (e.g., "list all projects," "find token by project ID")
- **Owner-Controlled:** Project creation is permissioned to ensure only verified carbon projects are tokenized

### FutureCarbonToken (FCT): Future Carbon Credit RWA Tokens

Each carbon project receives its own **FutureCarbonToken**—an ERC-20 compatible token representing future carbon credits from a specific ERPA (Emission Reduction Purchase Agreement). FCT tokens are claims on carbon credits that will be delivered in the future, not representations of already-issued credits.

**ERC-20 Compatibility:**
FCT tokens implement the full ERC-20 standard, ensuring compatibility with any wallet, exchange, or protocol that supports ERC-20 tokens. This standard compliance is what enables the DeFi composability discussed later in this document.

**Carbon-Specific Extensions:**
Beyond standard ERC-20 functionality, FCT tokens include Future Carbon Credit metadata:
- **Vintage Year:** The year the carbon credits are expected to be issued
- **Registry Code:** Identifier linking to the carbon registry (e.g., Verra, Gold Standard)
- **Custom Metadata:** Key-value pairs for additional project-specific attributes (methodology, geography, project type)

**Metadata Storage Approach:**

For storing extended metadata beyond on-chain storage, DPX will leverage Avalanche-native solutions:

*Current Implementation (C-Chain):*
- **Compressed Metadata Hashes:** Will store content-addressed hashes on-chain within FCT contracts
- **Avalanche Indexer:** Will use Avalanche's GraphQL indexer to expose human-readable metadata tied to token contracts
- **EVM-Native Lookups:** Will enable fast queries without requiring IPFS infrastructure
- This approach will provide reliability and simplicity while maintaining ERC-20 compatibility

*Future Considerations (Phase 2):*
- **Avalanche Warp Messaging (AWM) + Blob Storage:** Native subnet messaging with upcoming blob storage primitives (similar to Ethereum's EIP-4844) could provide compact, low-cost off-chain-like data anchoring for FCT metadata references
- **Cross-Subnet Metadata:** AWM will enable future metadata sharing between DPX (C-Chain) and ACXNET (custom subnet) without traditional IPFS dependencies

Note: While IPFS remains a viable option for decentralized metadata storage, Avalanche-native solutions will offer tighter integration with our C-Chain deployment and align with the platform's subnet interoperability strategy.

**Additional Features:**
- **Permit (EIP-2612):** Enables gasless approvals via off-chain signatures, improving user experience for trading workflows
- **Burnable:** Required for the redemption process—tokens are burned when exchanged for proceeds
- **Pausable:** Emergency capability to halt transfers if issues arise
- **Mintable:** Owner can mint tokens during initial issuance (typically done once at project creation)
- **Flexible Token Distribution:** Initial supply is minted to a specified receiver address, allowing separation between administrative ownership and token holdings

**One Token Per Project:**
Each project has its own distinct FCT token contract. This design ensures:
- Clear provenance tracking (token address uniquely identifies the project)
- Project-specific metadata embedded in the token contract
- Independent lifecycle management per project
- No commingling of different project credits

### RedemptionVault: Proceeds Distribution

The **RedemptionVault** manages the final stage of the Future Carbon Credit lifecycle—distributing proceeds to token holders after the underlying carbon credits are delivered and sold.

**Lifecycle:**
1. **Vault Deployment:** When a project's carbon credits are ready for sale, a RedemptionVault is deployed and linked to the project's FCT token
2. **Funding:** Sale proceeds (typically USDC or USDT) are deposited into the vault
3. **Activation:** Owner activates redemption, which calculates the pro-rata redemption rate based on total proceeds and token supply
4. **Redemption:** Token holders swap their FCT tokens for stablecoin proceeds; tokens are burned upon redemption

**Pro-Rata Distribution Example:**
- Total proceeds deposited: 1,000,000 USDC
- Total FCT token supply: 10,000,000 tokens
- Redemption rate: 0.10 USDC per token
- User holding 50,000 tokens receives: 5,000 USDC

**Design Rationale:**
- **Immutable Logic:** Unlike FctFactory, vaults are non-upgradeable—redemption rules are fixed at deployment, providing certainty to token holders
- **Burn-on-Redeem:** Tokens are burned during redemption, preventing double-claiming and ensuring accurate accounting
- **Configurable Stablecoin:** Vaults can be configured for USDC, USDT, or other ERC-20 stablecoins based on the currency used in the carbon credit sale

---

## SwapBox: Atomic Token Trading

**SwapBox** is DPX's mechanism for trustless, peer-to-peer token swaps between users. It enables atomic exchanges of FCT tokens for stablecoins (or other ERC-20 tokens) without requiring a centralized intermediary.

### Technology Foundation

SwapBox is powered by **AirSwap's SwapERC20 protocol (v5.0.0)**—a well-audited, battle-tested protocol widely used for atomic token swaps. DPX deploys its own SwapERC20 instance to:
- Collect protocol fees from swaps
- Maintain control over swap parameters
- Ensure consistent behavior within the DPX ecosystem

### How SwapBox Works

SwapBox uses **off-chain signed orders** combined with **on-chain atomic settlement**:

**Order Creation (Off-Chain):**
1. **Maker Creates Order:** A user (the "signer") creates an order specifying:
   - Token they're offering (e.g., 1,000 FCT tokens)
   - Token they want in return (e.g., 500 USDC)
   - Expiration timestamp
   - Unique nonce (prevents replay attacks)
   - Optional: specific counterparty address (for private swaps)
2. **Cryptographic Signature:** The maker signs the order using EIP-712 typed data signing
3. **Order Distribution:** The signed order can be shared via any channel (DPX marketplace, direct messaging, public order book)

**Order Execution (On-Chain):**
1. **Taker Reviews Order:** A counterparty (the "sender") reviews the signed order terms
2. **Token Approval:** Both parties must have approved the SwapBox contract to transfer their tokens
3. **Atomic Execution:** The taker submits the signed order to the SwapBox contract
4. **Simultaneous Transfer:** The contract atomically transfers both assets—either both transfers succeed, or neither does
5. **Nonce Invalidation:** The used nonce is marked as consumed, preventing order replay

### Swap Types

**Public Swaps:**
- Maker sets counterparty address to zero
- Any user can execute the swap
- First valid execution wins (race condition)
- Suitable for open marketplace listings

**Private Swaps:**
- Maker specifies exact counterparty address
- Only the designated address can execute
- Enables pre-negotiated bilateral trades
- Useful for OTC deals and known counterparties

### Fee Structure

SwapBox collects protocol fees on each swap:
- **Standard Swaps:** Configurable fee in basis points (e.g., 30 basis points = 0.3%)
- **Light Swaps:** Reduced fee for gas-optimized swap variant
- **Fee Wallet:** All fees are collected in a designated protocol fee wallet

Fees are deducted from the maker's (signer's) token amount during settlement.

### Why AirSwap Protocol

The decision to build on AirSwap rather than a custom implementation was driven by:

- **Security:** AirSwap v5.0.0 has undergone extensive security audits and has been battle-tested with significant trading volume
- **Simplicity:** Off-chain order signing with on-chain settlement is gas-efficient and user-friendly
- **Flexibility:** Supports both public and private swaps, enabling diverse trading scenarios
- **Non-Custodial:** At no point does the protocol or platform custody user assets
- **Immutability:** The SwapERC20 contract is non-upgradeable, providing certainty about settlement behavior

### User Journey Example

**Seller wants to sell 10,000 FCT tokens for 5,000 USDC:**

1. Seller approves SwapBox contract to spend their FCT tokens
2. Seller creates and signs an order: "I offer 10,000 FCT for 5,000 USDC, expires in 24 hours"
3. Order is posted to DPX marketplace
4. Buyer reviews the order and decides to accept
5. Buyer approves SwapBox contract to spend their USDC
6. Buyer submits the signed order to SwapBox contract
7. Contract atomically transfers: 10,000 FCT → Buyer, 5,000 USDC → Seller
8. Both parties receive their assets in a single transaction

---
### Strategic Upgradeability Design

DPX employs a deliberate approach to smart contract upgradeability that balances platform evolution with user trust:

- **Upgradeable Components (FctFactory):** The factory contract uses UUPS proxy pattern, allowing the platform to add features, improve functionality, and respond to ecosystem changes without disrupting existing projects
- **Immutable Components (FCT Tokens, RedemptionVaults, SwapBox):** All contracts that directly control user funds are non-upgradeable, ensuring that token behavior, redemption rules, and swap mechanics cannot be altered after deployment

This design provides the best of both worlds: flexibility where the platform needs to evolve, and immutability where trust and security are paramount.

---

## DeFi Composability

A core advantage of DPX's ERC-20 based architecture is native composability with the broader DeFi ecosystem. FCT tokens can integrate with existing protocols without requiring custom integrations.

### Potential Use Cases

**Decentralized Exchange Trading:**
- FCT tokens can be listed on Avalanche DEXs (Trader Joe, Pangolin)
- Automated market makers (AMMs) can provide continuous liquidity
- Users can swap FCT tokens without counterparty negotiation

**Lending & Borrowing:**
- FCT tokens could serve as collateral in lending protocols
- Token holders could borrow stablecoins against their carbon credit positions
- Enables leverage and capital efficiency for carbon credit investors

**Yield Strategies:**
- Liquidity provision in FCT/USDC pools earns trading fees
- Yield aggregators could optimize FCT-related strategies
- Staking mechanisms could incentivize long-term holding

**Cross-Chain Bridging:**
- Standard bridge protocols can transfer FCT tokens to other EVM chains
- Expands market access beyond Avalanche
- Enables integration with Ethereum-native DeFi protocols

### Important Considerations

While DeFi composability opens many possibilities, integration with external protocols involves considerations:
- Protocol-specific risk (smart contract vulnerabilities, economic exploits)
- Liquidity requirements for AMM-based trading
- Price oracle availability for lending protocol integration
- Regulatory implications of DeFi protocol usage

DPX focuses on providing the foundational infrastructure (ERC-20 tokens, atomic swaps). Third-party DeFi integrations depend on those protocols' support and community adoption.

---

## $ACR Token Integration

The **$ACR token** is the native utility token of the ACXRWA ecosystem, providing various functions across both CPX and DPX platforms.

### Role in DPX

$ACR is designed to be increasingly integrated with DPX as the protocol grows. Initial integration focuses on:

- **Fee Discounts:** Users holding or staking $ACR may receive reduced SwapBox protocol fees
- **Governance Participation:** $ACR holders can participate in protocol governance decisions as the DAO structure develops

As DPX matures and adoption increases, $ACR integration will deepen—potentially including enhanced platform benefits for token holders, governance weight in project listing decisions, and other utility mechanisms that align token holder incentives with protocol growth. This progressive integration ensures that $ACR accrues value alongside DPX adoption.

### Token Architecture

$ACR is implemented as an upgradeable ERC-20 token with governance capabilities:
- **ERC20Votes:** Enables on-chain voting with delegation
- **Permit (EIP-2612):** Gasless approvals for improved UX
- **UUPS Upgradeable:** Allows feature additions while preserving state
- **Governor Integration:** Compatible with OpenZeppelin Governor for DAO governance

Detailed tokenomics, distribution, and governance mechanisms are covered in the dedicated [$ACR Token section](./06-acr-token.md).

---

## Architecture Summary

| Component | Purpose | Standard | Upgradeability |
|-----------|---------|----------|----------------|
| **FctFactory** | Project registry, token/vault deployment | Custom | UUPS Upgradeable |
| **FutureCarbonToken** | Carbon credit RWA representation | ERC-20 + Extensions | Non-upgradeable |
| **RedemptionVault** | Proceeds distribution to token holders | Custom | Non-upgradeable |
| **SwapBox** | Atomic peer-to-peer token swaps | AirSwap SwapERC20 v5.0.0 | Non-upgradeable |
| **$ACR Token** | Platform utility and governance | ERC-20 + ERC20Votes | UUPS Upgradeable |

### Design Principles

**Standards-Based:**
Building on established standards (ERC-20, EIP-712, OpenZeppelin contracts, AirSwap protocol) ensures compatibility, security, and developer familiarity.

**Separation of Concerns:**
Each contract has a focused responsibility—FctFactory manages project lifecycle, FCT tokens represent assets, RedemptionVault handles proceeds, and SwapBox enables trading. This modularity simplifies auditing and reduces attack surface.

---

*Previous: [02 - ACX & CPX Platform](./02-acx-cpx-platform.md)*
*Next: [04 - Integration Strategy](./04-integration-strategy.md)*
