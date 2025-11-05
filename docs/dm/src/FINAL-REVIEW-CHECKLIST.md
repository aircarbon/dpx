# ARR Phase 1 Documentation - Final Review Checklist

**Version:** 1.1 (Final)  
**Date:** November 2025  
**Prepared by:** ACX CTO  
**Reviewed by:** ACX Engineering Leads  
**Status:** Ready for Whitepaper Integration

---

## All Updates Applied

### Terminology Standardization

- [COMPLETE] ACXv2 → **STMv2** (Security Token Manager v2)
- [COMPLETE] CPX → **ACX/CPX** (in migration contexts)
- [COMPLETE] ACXRWA token → **$ACR token**
- [COMPLETE] "Parallel migration" → **"Hard cutover"**
- [COMPLETE] "Integrate with Trader Joe" → **"Investigate market appetite for DEX pools"**
- [COMPLETE] All emojis removed (professional technical documentation)

### Content Accuracy

- [COMPLETE] Marketplace v2 (MBv2) bilateral negotiation correctly described
- [COMPLETE] C# matching engine noted as NOT used for CPX/DPX FCT trading
- [COMPLETE] CPX described as subsystem of wider ACX platform
- [COMPLETE] Polygon decommission concurrent with ACXNET launch (Phase 1C hard cutover)
- [COMPLETE] $ACR marketplace access utility added (burn to list projects)

### Technical Specifications

- [COMPLETE] SwapBox contract: Complete Solidity implementation with multiple concurrent swaps
- [COMPLETE] Network deployment: DPX on Avalanche C-Chain, CPX on ACXNET
- [COMPLETE] Settlement flows: MBv2 bilateral negotiation → acceptance → settlement
- [COMPLETE] Timeline: Compressed to 6 months, Phase 2 by end Q2 2026

---

## Document Suite (8 Documents, ~100 Pages)

| Document | Pages | Purpose | Status |
|----------|-------|---------|--------|
| **Whitepaper-ARR-Phase1.md** | 20 | **For whitepaper insertion** | READY |
| ARR-Phase1-DPX-Refactoring.md | 30 | Complete technical spec | READY |
| SwapBox-Contract.md | 10 | Complete Solidity code | READY |
| CPX-vs-DPX-Technical-Comparison.md | 20 | Technical comparison | READY |
| QUICK-REFERENCE.md | 1 | Developer cheat sheet | READY |
| ARR-Phase1-Index.md | 10 | Navigation guide | READY |
| UPDATE-SUMMARY.md | 8 | v1.0 → v1.1 changelog | READY |
| CHANGES-v1.1.md | 6 | Detailed change log | READY |
| FINAL-REVIEW-CHECKLIST.md | 5 | Pre-publication checklist | READY |

**Total:** ~100 pages of professional technical documentation

---

## Key Technical Points (For Whitepaper)

### Networks

**DPX:** Avalanche C-Chain (43114)
- Sub-second finality (<2 seconds)
- ~$0.42 gas per swap
- DeFi ecosystem: Trader Joe, Aave, Benqi

**CPX:** ACXNET (AvaLabs Custom Layer 1)
- Zero gas fees for users (ACX subsidized)
- <1 second finality
- Private mempool, dedicated validators

### Trading Platform

**Marketplace v2 (MBv2)** - Bilateral Negotiation
- Sellers list FCT projects
- Buyers submit trade requests
- Negotiation via counter-offers
- Settlement after mutual acceptance

**NOT the C# matching engine** (used only for CET/GNT contract trading)

### SwapBox Contract

**Multiple concurrent swaps** with unique IDs:
- Each swap: buyer, seller, buyerAsset (USDC), sellerAsset (FCT), amounts
- Both deposit → each withdraws inverse asset
- 24-hour expiry with automatic refunds
- ~400K gas per swap (~$0.42 on Avalanche)

**Full implementation:** `SwapBox-Contract.md`

### $ACR Token Utility

**0. Marketplace Access** - Burn $ACR to list projects (anti-spam)
1. Swap fee discounts - Stake $ACR
2. Governance rights
3. Liquidity mining rewards
4. Premium DeFi features

### Timeline (Critical)

**Phase 2 deadline:** June 30, 2026

| Phase | Duration | Dates | Key Event |
|-------|----------|-------|-----------|
| 1A | 4 weeks | Nov 2025 | Avalanche Fuji testnet |
| 1B | 4 weeks | Dec 2025 | Development sprint |
| 1C | 8 weeks | Jan-Feb 2026 | ACXNET launch + Polygon hard cutover |
| 1D | 8 weeks | Mar-Apr 2026 | Production scale |
| 2 | 8 weeks | May-Jun 2026 | Cross-mode bridge GO-LIVE |

---

## Whitepaper Integration Instructions

### Primary Document

**Use:** `Whitepaper-ARR-Phase1.md` (20 pages - combined executive summary + whitepaper content)

**How to insert:**

1. **Install Pandoc** (if not already):
   ```bash
   sudo apt install pandoc
   ```

2. **Convert to Word:**
   ```bash
   cd /home/dom/src/ac/ac-monorepo2/docs/dpx_wp/
   pandoc -f markdown -t docx \
     --toc \
     --toc-depth=2 \
     -o Whitepaper-ARR-Phase1.docx \
     Whitepaper-ARR-Phase1.md
   ```

3. **Copy/paste sections** into main whitepaper Word document

4. **Apply formatting:**
   - Use Format Painter to match existing heading styles
   - Adjust table styles
   - Code blocks: Use Consolas/Courier New font

### Section Placement in Whitepaper

**Suggested location:** After Section 7 (Technical Design)

**New section:** 7.5 - Architecture Refactoring Roadmap

**Subsections:**
- Overview
- Architectural Transformation
- SwapBox: Trustless Bilateral Settlement
- True ERC-20 FCT Tokens
- Feature Toggle Architecture
- System Components & Changes
- Marketplace v2: Project-Based Trading
- Deployment Strategy
- Economic Model Integration
- Risk Mitigation
- Success Metrics
- Conclusion
- Technical Appendix: SwapBox Interface

---

## Quality Assurance Checklist

### Terminology Consistency

- [ ] Review sample: All "STMv2" (not "ACXv2")
- [ ] Review sample: All "$ACR" (not "ACXRWA")
- [ ] Review sample: All "ACX/CPX" for migration (not just "CPX")
- [ ] Review sample: "Hard cutover" (not "parallel migration")
- [ ] No emojis present (professional tone)

### Technical Accuracy

- [ ] Marketplace v2 described as bilateral (not matching engine)
- [ ] Settlement flows show: List → Request → Negotiate → Accept → Settle
- [ ] SwapBox interface matches actual implementation
- [ ] Gas costs: $0 (ACXNET), ~$0.42 (Avalanche)
- [ ] Timeline: Phase 2 by June 30, 2026

### Completeness

- [ ] SwapBox complete Solidity implementation provided
- [ ] All 8 documents consistent
- [ ] Network addresses specified (Avalanche, ACXNET)
- [ ] $ACR marketplace access utility documented
- [ ] Migration strategy clear (hard cutover in Phase 1C)

---

## Final Pre-Publication Review

**Recommended reviewers:**
1. CTO - Technical architecture validation
2. Co-CEOs - Strategic alignment
3. Legal - Compliance language
4. Ava Labs partnership team - Network deployment details

**Focus areas:**
- SwapBox security claims (audit pending)
- Timeline feasibility (6-month aggressive schedule)
- $ACR token utility claims
- Marketplace v2 vs. CLOB distinction clarity

---

**Document Suite Status:** FINAL - Ready for Publication

**Classification:** Internal / Investor-Shareable

