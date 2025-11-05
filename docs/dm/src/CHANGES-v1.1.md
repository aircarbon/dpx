# ARR Phase 1 Documentation Changes - v1.1

**Date:** November 2025  
**Version:** 1.0 → 1.1  

---

## Summary of All Changes Applied

### 1. Contract Naming: ACXv2 → STMv2

**Changed throughout all documents:**
- Old: `ACXv2.sol`, `ACXv2 contract`, `ACXv2 ledger`
- New: `STMv2.sol`, `STMv2 contract`, `STMv2 ledger`
- **Full name:** Security Token Manager v2

**Rationale:** STMv2 more accurately describes the contract's purpose (security token management) vs. generic contract name.

**Files updated:**
- ARR-Phase1-DPX-Refactoring.md
- Whitepaper-ARR-Section.md
- ARR-Phase1-Executive-Summary.md
- CPX-vs-DPX-Technical-Comparison.md
- QUICK-REFERENCE.md
- ARR-Phase1-Index.md
- UPDATE-SUMMARY.md

---

### 2. Platform Context: CPX → ACX/CPX

**Changed throughout all documents:**
- Old: "CPX migration", "CPX platform"
- New: "ACX/CPX migration", "ACX/CPX platform"
- **Added context:** "CPX is a subsystem of the wider ACX centralized exchange (includes spot/CLOB markets, custody, fiat rails)"

**Rationale:** CPX (Carbon Project Exchange) is one component of the broader ACX platform. The migration moves the entire ACX platform (including CPX, spot market, custody) to ACXNET.

**Key additions:**
- Explicitly noted CPX is part of wider ACX ecosystem
- Clarified ACX includes: CPX marketplace + spot/CLOB markets + custody + fiat rails
- Migration affects entire ACX platform, not just CPX subsystem

---

### 3. Migration Timeline: Parallel → Hard Cutover

**Changed:**
- Old: "Migrate CPX... parallel operation for 2 weeks"
- New: "Hard cutover: Decommission Polygon simultaneously with ACXNET go-live"

**Changed:**
- Old: Phase 1D: "Complete Polygon → ACXNET migration" + "Decommission Polygon (May 1, 2026)"
- New: Phase 1C: "Hard cutover + Polygon decommission" | Phase 1D: "All ACX/CPX fully operational on ACXNET (Polygon decommissioned in Phase 1C)"

**Rationale:** Migration is a hard cutover event, not gradual. Polygon decommissioning happens immediately during Phase 1C, not later in Phase 1D.

**Timeline impact:**
- Phase 1C (Jan-Feb 2026): ACXNET go-live + Polygon shutdown (same day)
- Phase 1D (Mar-Apr 2026): Optimization on ACXNET (Polygon already gone)

---

### 4. DEX Integration: Definitive → Exploratory

**Changed:**
- Old: "Integrate with Trader Joe DEX for FCT/USDC liquidity pools"
- New: "Investigate market appetite for DEX liquidity pools (e.g., Trader Joe FCT/USDC pairs)"

**Rationale:** DEX integration is not confirmed for Phase 1D; depends on market demand assessment first.

**Files updated:**
- ARR-Phase1-DPX-Refactoring.md (Section 5.4)
- Whitepaper-ARR-Section.md (Phase 1D)
- ARR-Phase1-Executive-Summary.md (Phase 1D)
- ARR-Phase1-Index.md (Phase 1D)

---

### 5. Token Branding: ACXRWA → $ACR

**Changed throughout all documents:**
- Old: "ACXRWA token", "ACXRWA"
- New: "$ACR token", "$ACR"

**Examples:**
- "Stake $ACR to reduce SwapBox gas costs"
- "$ACR token rewards for cross-mode liquidity"
- "Launch $ACR token staking"
- "Burn $ACR to gain marketplace access"

**Files updated:**
- ARR-Phase1-DPX-Refactoring.md
- Whitepaper-ARR-Section.md
- ARR-Phase1-Executive-Summary.md
- ARR-Phase1-Index.md

---

### 6. Token Utility: Added Marketplace Access Fee

**Added to Economic Model Integration (ALL documents):**

**New utility #0 (top of list):**
```
0. Access to CPX & DPX Project Marketplaces: 
   Burn $ACR to gain listing access as a Project to the marketplaces (anti-spam mechanism)
```

**Locations added:**
- Whitepaper-ARR-Section.md: Section "Economic Model Integration"
- UPDATE-SUMMARY.md: Overview of Changes

**Rationale:** 
- Anti-spam mechanism for project listings
- Creates $ACR burn demand from project owners
- Aligns with buyback-and-burn tokenomics

---

### 7. Trading Platform Clarification: Matching Engine → Marketplace v2

**Comprehensive updates across all documents:**

**Key Changes:**
- Clarified CPX/DPX use **Marketplace v2 (MBv2)** bilateral negotiation
- Emphasized **NOT** C# matching engine (CLOB/spot market)
- Added comparison tables: MBv2 vs. Spot Market
- Updated settlement flows to show: Listing → Trade Request → Negotiation → Acceptance → Settlement
- Noted matching engine used only for CET/GNT contract trading

**Sections added/modified:**
- ARR-Phase1-DPX-Refactoring.md: Section 1.5 completely rewritten
- Whitepaper-ARR-Section.md: New section "Marketplace v2: Project-Based Trading"
- CPX-vs-DPX-Technical-Comparison.md: "Trade Negotiation" section
- All settlement workflows updated to show bilateral negotiation flow

---

## Complete Change Log by Document

### ARR-Phase1-DPX-Refactoring.md

1. ACXv2 → STMv2 (all occurrences)
2. CPX → ACX/CPX in migration contexts
3. Added "CPX is subsystem of ACX" context
4. Hard cutover language for Polygon decommission
5. "Integrate with Trader Joe" → "Investigate market appetite for DEX pools"
6. ACXRWA → $ACR token
7. Section 1.5 rewritten for Marketplace v2 clarity
8. Section 3.2.4 clarified matching engine not used for CPX/DPX
9. Updated all settlement flows to show MBv2 bilateral negotiation

### Whitepaper-ARR-Section.md

1. ACXv2 → STMv2
2. Added "CPX is subsystem of ACX" in Core Technical Differentiators
3. Hard cutover in Phase 1C deployment section
4. "Integrate" → "Investigate market appetite" for DEX
5. ACXRWA → $ACR
6. **Added:** $ACR utility #0 - Marketplace access (burn to list)
7. Settlement flow updated to 10-step MBv2 bilateral process
8. New section: "Marketplace v2: Project-Based Trading"

### ARR-Phase1-Executive-Summary.md

1. ACXv2 → STMv2
2. CPX → ACX/CPX for migration
3. Hard cutover language
4. "Integrate" → "Investigate" for DEX
5. Added "CPX Context" paragraph at end
6. Updated timeline descriptions

### CPX-vs-DPX-Technical-Comparison.md

1. ACXv2 → STMv2 (all tables)
2. "Trade Matching" → "Trade Negotiation (Marketplace v2)"
3. Added "Modules NOT Used for CPX/DPX" section
4. Updated settlement workflows to show full MBv2 flow (11 steps for DPX)
5. Updated performance metrics to clarify no matching engine bottleneck
6. Updated code organization to show MBv2 as shared module

### ARR-Phase1-Index.md

1. ACXv2 → STMv2
2. CPX → ACX/CPX context added
3. Hard cutover language in timeline
4. "Integrate" → "Investigate" for DEX
5. Updated CPX definition with "subsystem of ACX" context

### QUICK-REFERENCE.md

1. ACXv2 → STMv2
2. LEDGER_ADDRESS → STMV2_ADDRESS in config examples
3. Updated Smart Contracts table

### UPDATE-SUMMARY.md

1. Added "Trading Platform Clarification" to overview
2. Added "Token Branding" section
3. Added Marketplace v2 (MBv2) detailed explanation
4. Added CPX context explanation
5. Hard cutover language in ACXNET deployment

---

## New Terminology Standardized

### Contract Names

| Old | New | Full Name |
|-----|-----|-----------|
| ACXv2 | **STMv2** | Security Token Manager v2 |
| ACXv2.sol | **STMv2.sol** | Smart contract file name |

### Platform Names

| Old | New | Context |
|-----|-----|---------|
| CPX | **ACX/CPX** (when referring to migration) | CPX is subsystem of ACX |
| CPX platform | **ACX centralized exchange** (when referring to full platform) | Includes CPX + spot/CLOB + custody + fiat |
| CPX | **CPX** (when referring to marketplace only) | Project-based marketplace subsystem |

### Token Names

| Old | New |
|-----|-----|
| ACXRWA token | **$ACR token** |
| ACXRWA | **$ACR** |
| Stake ACXRWA | **Stake $ACR** |

### Migration Language

| Old | New |
|-----|-----|
| Parallel operation | **Hard cutover** |
| Decommission Polygon (May 1) | **Decommission Polygon simultaneously** (Phase 1C, Feb 2026) |
| Migrate CPX | **Migrate ACX/CPX** |

### DEX Integration Language

| Old | New |
|-----|-----|
| Integrate with Trader Joe DEX | **Investigate market appetite for DEX pools (e.g., Trader Joe)** |
| FCT/USDC liquidity pools | **FCT/USDC pairs** |

---

## Token Utility Updated

### New Utility Added (#0)

**Access to CPX & DPX Project Marketplaces:**
- Burn $ACR to gain listing access as a Project
- Anti-spam mechanism
- Creates burn demand from project owners
- Aligns with buyback-and-burn economics

### Existing Utilities (Renumbered)

1. Swap Fee Discounts (stake $ACR)
2. Governance Rights
3. Liquidity Mining (earn $ACR)
4. Premium Features

---

## Validation Checklist

### Terminology Consistency

All "ACXv2" → "STMv2" (7 documents)
All "ACXRWA token" → "$ACR token" (4 documents)
All "CPX migration" → "ACX/CPX migration" (7 documents)
"Parallel operation" → "Hard cutover" (3 documents)
"Integrate with Trader Joe" → "Investigate market appetite" (4 documents)

### Content Accuracy

Marketplace v2 (MBv2) correctly described as bilateral negotiation
C# matching engine correctly noted as NOT used for CPX/DPX
Settlement flows show MBv2: List → Request → Negotiate → Accept → Settle
CPX described as subsystem of wider ACX platform
Polygon decommission in Phase 1C (not Phase 1D)

### New Content Added

SwapBox-Contract.md (complete Solidity implementation)
QUICK-REFERENCE.md (developer cheat sheet)
$ACR marketplace access utility (#0)
MBv2 vs. Spot Market comparison tables
ACX/CPX platform context explanations

---

## Document Suite Status

**Version:** 1.1  
**Total Documents:** 8  
**Total Pages:** ~100

| Document | Status | Changes |
|----------|--------|---------|
| ARR-Phase1-Executive-Summary.md | Complete | 6 updates |
| ARR-Phase1-DPX-Refactoring.md | Complete | 15+ updates |
| Whitepaper-ARR-Section.md | Complete | 12 updates |
| CPX-vs-DPX-Technical-Comparison.md | Complete | 10 updates |
| SwapBox-Contract.md | Complete | New document |
| ARR-Phase1-Index.md | Complete | 8 updates |
| QUICK-REFERENCE.md | Complete | New document |
| UPDATE-SUMMARY.md | Complete | 4 updates |

---

## Ready for Whitepaper Integration

**Primary document for whitepaper:**
- `Whitepaper-ARR-Section.md` (15 pages, ready to insert)

**Supporting technical documents:**
- `ARR-Phase1-DPX-Refactoring.md` (full technical spec)
- `SwapBox-Contract.md` (complete smart contract implementation)

**Quick reference for teams:**
- `QUICK-REFERENCE.md` (1-page developer guide)

---

**All changes applied consistently across entire documentation suite.**

**Status:** **Ready for stakeholder review and Word integration**

