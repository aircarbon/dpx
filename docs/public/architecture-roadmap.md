---
sidebar_position: 2
---

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

The ACXRWA platform will evolve from the current **Carbon Project Exchange (CPX)** centralized architecture to support a parallel **Decentralized Project Exchange (DPX)** operating mode. This transformation represents a fundamental shift enabling the platform to serve two distinct market segments—**institutional custodial** and **DeFi-native non-custodial**—from a single unified codebase.

**Core Innovation:**  
Single platform, dual custody models, unified liquidity across centralized and decentralized carbon markets.

### Network Strategy

**DPX (Decentralized Project Exchange):**
- Deploys on **Avalanche C-Chain** (Chain ID: 43114)
- Sub-second finality (`<2 seconds`)
- Low gas costs (~$0.42 per swap)
- Robust DeFi ecosystem (Trader Joe, Aave, Benqi)
- Ideal for crypto-native projects and buyers

**CPX (Centralized Project Exchange):**
- Migrates to **ACXNET** (AvaLabs Custom Layer 1)
- Zero gas fees for users (ACX-subsidized)
- Instant finality (`<1 second`)
- Private mempool (MEV protection)
- Ideal for regulated markets and institutions

**CPX Context:** CPX is a subsystem of the wider ACX centralized exchange platform, which encompasses spot/CLOB markets, custody services, and fiat on/off-ramps.
