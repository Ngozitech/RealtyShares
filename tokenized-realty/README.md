# RealtyShares: Fractional Real Estate Investment Platform

RealtyShares is a decentralized platform built on the Stacks blockchain that enables fractional ownership of real estate properties through tokenization. The platform allows property owners to tokenize their real estate assets and investors to purchase shares, earn rental income, and participate in property governance.

## Overview

The platform transforms traditional real estate investment by:
- Converting real estate properties into NFTs
- Enabling property fractionalization into tradeable shares
- Managing property ownership and transfers on-chain
- Distributing rental income automatically
- Facilitating democratic property governance

## Project Structure

```
clarity-realty-shares/
├── contracts/
│   ├── real-estate-token.clar       # Core token contract (NFT & shares)
│   ├── governance.clar              # Voting and proposal management
│   ├── property-manager.clar        # Property operations & maintenance
│   └── income-distributor.clar      # Rental income distribution
├── tests/
│   ├── real-estate-token_test.ts
│   ├── governance_test.ts
│   ├── property-manager_test.ts
│   └── income-distributor_test.ts
├── README.md
└── settings/
    └── Devnet.toml                  # Development network configuration
```

## Core Features

### Real Estate Token Contract (Implemented)
- Property NFT minting and management
- Share token creation and transfers
- Property fractionalization
- Price updates and property valuation

### Governance Contract (Planned)
- Proposal creation and voting
- Democratic decision-making
- Maintenance fund allocation
- Property improvements voting

### Property Manager Contract (Planned)
- Property registration and verification
- Maintenance fund management
- Property valuation updates
- Emergency maintenance handling

### Income Distributor Contract (Planned)
- Rental income collection
- Automated distribution to shareholders
- Distribution history tracking
- Fee management

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain
- Node.js and npm (for testing)

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/clarity-realty-shares.git
cd clarity-realty-shares
```

2. Install dependencies
```bash
npm install
```

3. Run tests
```bash
clarinet test
```

## Contract Deployment

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Register a New Property
```clarity
(contract-call? .real-estate-token register-property 
    "Park View Apartments" 
    "123 Main St, Miami, FL" 
    u10000 
    u1000)
```

### Purchase Shares
```clarity
(contract-call? .real-estate-token purchase-shares 
    u1  ;; property-id 
    u10 ;; number of shares
)
```

### Transfer Shares
```clarity
(contract-call? .real-estate-token transfer-shares 
    u1  ;; property-id
    u5  ;; number of shares
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM ;; recipient
)
```

## Testing

The project includes comprehensive test suites for each contract. Run tests using:

```bash
clarinet test
```

## Security Considerations

The contracts implement several security measures:
- Input validation for all public functions
- Overflow protection for arithmetic operations
- Access control for administrative functions
- Proper error handling and status codes
- Share transfer validations