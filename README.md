# Stacks Oracle 🔮

A decentralized price feed oracle system for the Stacks blockchain. Provides reliable, tamper-resistant price data for DeFi applications.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Built on Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546FF)](https://stacks.co)

## Overview

Stacks Oracle is a decentralized oracle network that brings off-chain price data on-chain. It uses a multi-reporter consensus mechanism to ensure data accuracy and reliability.

## Features

- 🔒 **Decentralized** - Multiple trusted reporters submit prices
- ⚡ **Fast Updates** - Price updates every ~10 minutes (per block)
- 📊 **Multiple Assets** - STX, BTC, ETH, and more
- 🛡️ **Manipulation Resistant** - Median price calculation
- 🔗 **Easy Integration** - Simple read-only functions for DeFi apps

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Price Source 1 │     │  Price Source 2 │     │  Price Source N │
│   (CoinGecko)   │     │   (Binance)     │     │   (Custom)      │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │     Oracle Reporters    │
                    │   (Trusted Addresses)   │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Stacks Oracle Contract │
                    │   - Aggregates prices   │
                    │   - Calculates median   │
                    │   - Validates freshness │
                    └────────────┬────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌────────▼────────┐     ┌────────▼────────┐     ┌────────▼────────┐
│   DEX Protocol  │     │  Lending Protocol│     │  Prediction Mkt │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Smart Contracts

### oracle-core.clar
Main oracle contract with price aggregation and reporter management.

### oracle-consumer.clar
Example consumer contract showing how to integrate with the oracle.

## Usage

### Reading Price Data

```clarity
;; Get the latest STX/USD price
(contract-call? .oracle-core get-price "STX-USD")
;; Returns: (ok { price: u1250000, decimals: u6, timestamp: u12345678 })

;; Get price with staleness check (max 10 blocks old)
(contract-call? .oracle-core get-price-safe "STX-USD" u10)
```

### For DeFi Integrations

```clarity
;; In your DeFi contract
(define-read-only (get-collateral-value (amount uint))
  (let (
    (price-data (unwrap! (contract-call? .oracle-core get-price "STX-USD") (err u1)))
  )
    (ok (/ (* amount (get price price-data)) (pow u10 (get decimals price-data))))
  )
)
```

## Supported Price Feeds

| Pair | Decimals | Update Frequency |
|------|----------|------------------|
| STX-USD | 6 | Every block |
| BTC-USD | 6 | Every block |
| ETH-USD | 6 | Every block |
| sBTC-USD | 6 | Every block |
| ALEX-USD | 6 | Every 10 blocks |

## Installation

```bash
# Clone the repository
git clone https://github.com/serayd61/stacks-oracle.git
cd stacks-oracle

# Install dependencies
npm install

# Run tests
clarinet test

# Deploy to testnet
clarinet deployments apply -p testnet
```

## Reporter Requirements

To become an oracle reporter:

1. Stake minimum 10,000 STX
2. Run the reporter node software
3. Submit accurate prices consistently
4. Maintain >95% uptime

## Security

- Multi-sig admin controls
- Price deviation limits (max 10% per update)
- Staleness checks built-in
- Reporter slashing for malicious behavior

## Roadmap

- [x] Core oracle contract
- [x] Multi-reporter support
- [x] Price aggregation (median)
- [ ] Reporter staking/slashing
- [ ] Chainlink integration
- [ ] Historical price queries
- [ ] VRF (Verifiable Random Function)

## Contributing

Contributions are welcome! Please read our contributing guidelines.

## License

MIT © [serayd61](https://github.com/serayd61)

## Related Projects

- [Redstone Oracle](https://redstone.finance) - Cross-chain oracle
- [Pyth Network](https://pyth.network) - High-fidelity oracle
- [DIA Data](https://diadata.org) - Open-source oracle

