# DPX Architecture & Implementation Guide

**Version:** 1.2
**Date:** November 2025
**Status:** Active Development

---

## Introduction

### What is DPX?

DPX (Decentralized Project Exchange) is a non-custodial, DeFi-native marketplace for trading tokenized Real-World Assets (RWAs) in the form of carbon credits, built as an extension of the ACX (AirCarbon Exchange) platform. DPX transforms how carbon markets operate by enabling permissionless global access to USDC-convertible Future Carbon Tons (FCTs)—tokenized RWA representations of forward carbon contracts derived from Emission Reduction Purchase Agreements (ERPAs).

While ACX's existing Carbon Project Exchange (CPX) serves institutional and regulated markets through a custodial model, DPX expands access to DeFi-native participants, DAO treasuries, crypto investors, and anyone seeking non-custodial exposure to carbon RWAs. Together, CPX and DPX create a dual-mode platform that serves the entire spectrum of carbon market participants—from traditional institutions to decentralized protocols.

### The Problem

Climate finance faces two interconnected challenges:

**1. The Climate Finance Bottleneck**
Achieving net-zero by 2050 requires approximately $9-10 trillion in annual investment, yet only $1-1.5 trillion is currently deployed. Traditional financing structures—concessional loans and blended finance—are too slow, opaque, and inflexible to meet the scale and urgency required.

**2. Carbon Market Infrastructure Gaps**
The Voluntary Carbon Market (VCM) is expected to reach 2.8 billion tons annually by 2030, but current infrastructure cannot support this growth. Key barriers include:
- **Illiquidity:** ERPAs are complex, bilateral contracts that are difficult to trade
- **Fragmented Access:** High barriers exclude smaller participants and DeFi ecosystems
- **Custody Concerns:** Centralized models limit composability and create counterparty risk
- **Lack of Transparency:** Off-chain settlement obscures price discovery and provenance

### The Solution

DPX addresses these challenges through RWA tokenization:

- **Tokenizing ERPAs as ERC-20 RWAs** — Converting illiquid carbon contracts into tradeable, composable digital assets (FCTs)
- **Enabling Non-Custodial RWA Trading** — Users control their own assets via wallet-based authentication
- **Integrating RWAs with DeFi Ecosystems** — FCTs can be used in lending protocols, liquidity pools, and yield strategies
- **Expanding Global Access to RWAs** — Permissionless participation dramatically broadens the carbon credit buyer base

By operating alongside CPX within the ACX platform, DPX creates a unified liquidity ecosystem where institutional and DeFi participants can trade carbon RWAs seamlessly.

### Current Status

DPX is currently in active development with smart contracts deployed on testnet. The platform architecture has been finalized, and core components are being built and tested in preparation for mainnet deployment on Avalanche C-Chain.

### Document Structure

This documentation provides a comprehensive technical overview of DPX for technical investors, due diligence teams, advisors, and auditors. It is organized as follows:

| Section | Description |
|---------|-------------|
| **02 - ACX Platform** | Overview of ACX Group and its existing exchange infrastructure |
| **03 - CPX Overview** | The centralized Carbon Project Exchange and its architecture |
| **04 - DPX Architecture** | Technical design, components, and technology choices |
| **05 - Integration Strategy** | How DPX integrates with ACX and the dual-mode approach |
| **06 - Roadmap** | Development phases and rollout strategy |
| **07 - $ACR Token** | Tokenomics, utility, and distribution |
| **08 - Compliance** | KYC/AML framework and regulatory approach |
| **09 - Risk Mitigation** | Security measures and risk management |
| **10 - Testing & QA** | Quality assurance and audit strategy |
| **11 - Progress Checklist** | Public milestone tracker |
| **12 - Appendices** | Glossary and references |

For investment-focused information, token distribution details, and market opportunity analysis, refer to the **ACXRWA Whitepaper**.

---

*Next: [02 - ACX Platform Overview](./02-acx-platform.md)*
