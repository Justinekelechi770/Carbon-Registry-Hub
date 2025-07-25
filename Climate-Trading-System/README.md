# Carbon Credit Marketplace Smart Contract

A comprehensive decentralized platform for carbon offset project registration, third-party verification, credit tokenization, peer-to-peer trading, and transparent retirement tracking with immutable proof of environmental impact.

## Overview

This Clarity smart contract implements a complete carbon credit marketplace ecosystem on the Stacks blockchain, enabling:

- **Project Registration**: Environmental projects can register and document their carbon offset initiatives
- **Third-Party Verification**: Authorized verifiers can validate and certify carbon credits
- **Credit Tokenization**: Verified credits are tokenized into tradeable batches
- **Peer-to-Peer Trading**: Direct trading of carbon credits between users
- **Retirement Tracking**: Permanent retirement of credits with immutable proof
- **Digital Certificates**: Official certification of retired credits

## Features

### Environmental Project Management
- Register new environmental projects with detailed metadata
- Support for 8 project categories (renewable energy, reforestation, methane capture, etc.)
- Project status tracking from registration through verification
- Comprehensive project documentation and geographical data

### Third-Party Verification System
- Authorization system for accredited verification entities
- Detailed verification records with methodology standards
- Monitoring period tracking and verification sequences
- Immutable verification history

### Credit Trading Infrastructure
- Create tradeable credit batches with vintage year tracking
- Peer-to-peer credit transfers
- Portfolio management for credit holders
- Price discovery through market mechanisms

### Credit Retirement & Certificates
- Permanent retirement of credits for offsetting claims
- Digital certificate generation for retired credits
- Beneficiary designation for retirement transactions
- Comprehensive retirement audit trail

## Supported Project Categories

1. `renewable-energy`
2. `reforestation-afforestation`
3. `methane-capture-destruction`
4. `energy-efficiency-improvement`
5. `carbon-capture-storage`
6. `sustainable-agriculture`
7. `waste-management`
8. `transportation-electrification`

## Core Functions

### Project Registration
```clarity
(register-new-environmental-project 
  project-name 
  detailed-description 
  geographical-location 
  environmental-category 
  implementation-start-date 
  expected-completion-date 
  registry-documentation-url)
```

### Verification Authorization
```clarity
(authorize-third-party-verification-entity 
  verifier-principal 
  organization-name 
  accreditation-credentials)
```

### Project Verification
```clarity
(execute-third-party-project-verification 
  project-identifier 
  verified-credits-quantity 
  verification-report-url 
  applied-methodology-standard 
  monitoring-period-start 
  monitoring-period-end 
  verification-metadata)
```

### Credit Batch Creation
```clarity
(create-tradeable-credit-batch 
  source-project-identifier 
  credit-vintage-year 
  batch-quantity 
  unit-price-in-ustx)
```

### Credit Purchase
```clarity
(execute-carbon-credit-purchase-transaction 
  batch-identifier 
  desired-purchase-quantity)
```

### Credit Retirement
```clarity
(execute-permanent-credit-retirement 
  source-project-identifier 
  credit-vintage-year 
  retirement-quantity 
  retirement-justification 
  retirement-beneficiary-principal)
```

### Peer-to-Peer Transfer
```clarity
(execute-peer-to-peer-credit-transfer 
  source-project-identifier 
  credit-vintage-year 
  recipient-principal 
  transfer-quantity)
```

## Query Functions

### Project Information
- `query-environmental-project-details`: Get detailed project information
- `query-supported-environmental-categories`: List all supported project types
- `query-project-verification-history`: View verification history for a project

### Credit & Trading Information
- `query-tradeable-credit-batch-details`: Get batch information and pricing
- `query-user-credit-portfolio-balance`: Check user's credit holdings
- `query-retirement-transaction-details`: View retirement transaction details

### Platform Statistics
- `query-platform-statistics`: Get overall platform metrics
- `query-verification-entity-authorization-status`: Check verifier authorization

## Data Structures

### Environmental Project Registry
```clarity
{
  project-name: (string-utf8 128),
  detailed-description: (string-utf8 1024),
  geographical-location: (string-utf8 128),
  project-owner-principal: principal,
  environmental-category: (string-ascii 64),
  implementation-start-date: uint,
  expected-completion-date: uint,
  total-verified-credits: uint,
  credits-available-for-sale: uint,
  credits-permanently-retired: uint,
  verification-status-confirmed: bool,
  current-project-status: (string-ascii 32),
  registry-documentation-url: (string-utf8 256)
}
```

### Tradeable Credit Batches
```clarity
{
  source-project-identifier: uint,
  credit-vintage-year: uint,
  total-batch-quantity: uint,
  remaining-available-quantity: uint,
  unit-price-in-ustx: uint,
  batch-creation-timestamp: uint,
  current-batch-status: (string-ascii 32)
}
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 400 | ERR-INVALID-INPUT | Invalid input parameters |
| 402 | ERR-INSUFFICIENT-BALANCE | Insufficient credit balance |
| 403 | ERR-UNAUTHORIZED-ACCESS | Unauthorized access attempt |
| 404 | ERR-NOT-FOUND | Resource not found |
| 410 | ERR-INVALID-PROJECT-TYPE | Unsupported project category |
| 411 | ERR-INVALID-DATE-RANGE | Invalid date range |
| 412 | ERR-EMPTY-FIELD | Required field is empty |
| 413 | ERR-PROJECT-NOT-VERIFIED | Project not yet verified |
| 414 | ERR-PROJECT-INACTIVE | Project is inactive |
| 415 | ERR-INSUFFICIENT-CREDITS | Not enough credits available |
| 416 | ERR-BATCH-UNAVAILABLE | Credit batch unavailable |
| 417 | ERR-PAYMENT-FAILED | STX payment failed |
| 418 | ERR-CERTIFICATE-EXISTS | Certificate already exists |
| 419 | ERR-SELF-AUTHORIZATION | Self-authorization not allowed |
| 420 | ERR-INVALID-VINTAGE-YEAR | Invalid vintage year (minimum 2010) |

## Usage Examples

### 1. Register a Renewable Energy Project
```clarity
(contract-call? .carbon-credit-marketplace register-new-environmental-project
  u"Solar Farm Project Alpha"
  u"1000 MW solar installation reducing grid emissions by 500,000 tCO2e annually"
  u"California, USA"
  "renewable-energy"
  u1640995200  ;; Jan 1, 2022
  u1672531200  ;; Jan 1, 2023
  u"https://docs.example.com/solar-project-alpha")
```

### 2. Purchase Carbon Credits
```clarity
(contract-call? .carbon-credit-marketplace execute-carbon-credit-purchase-transaction
  u1  ;; batch-identifier
  u100)  ;; purchase 100 credits
```

### 3. Retire Credits for Offsetting
```clarity
(contract-call? .carbon-credit-marketplace execute-permanent-credit-retirement
  u1  ;; project-identifier
  u2022  ;; vintage-year
  u50  ;; retire 50 credits
  u"Corporate annual emissions offset - Q4 2024"
  (some 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7))  ;; beneficiary
```

## Security Features

- **Role-based Access Control**: Platform admin and authorized verifier roles
- **Input Validation**: Comprehensive validation of all inputs
- **Ownership Verification**: Ensures only project owners can create batches
- **Balance Checking**: Prevents double-spending of credits
- **Self-transaction Prevention**: Blocks self-authorization and self-beneficiary assignments

## Integration Notes

- **STX Payments**: Uses native STX transfers for credit purchases
- **Block Height Timestamps**: All transactions timestamped with block height
- **Immutable Records**: All verification and retirement records are permanent
- **Portfolio Tracking**: Automatic portfolio updates for all credit movements

## Deployment Requirements

- Stacks blockchain environment
- Clarity smart contract runtime
- Minimum vintage year support from 2010
- Administrative privileges for platform management