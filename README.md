# SimpleArbitrageSearcher

A Solidity contract for detecting arbitrage opportunities between decentralized exchanges (Uniswap V2 and SushiSwap).

## Overview

This project implements a contract that scans for price differences between Uniswap V2 and SushiSwap to identify potential arbitrage opportunities. It calculates potential profits for token swaps across these exchanges and provides functionality to search both predefined and custom token pairs.

## Features

- Searches for arbitrage opportunities between Uniswap V2 and SushiSwap
- Supports common token pairs (WETH, USDC, DAI)
- Allows checking custom token pairs
- Calculates potential profit margins
- Integration with AAVE (for potential flash loan implementation)
- Events for logging arbitrage opportunities

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/arbitrage-searcher.git
cd arbitrage-searcher
```

Install dependencies:

```bash
npm install
```

## Configuration

Edit the `hardhat.config.js` file to configure your network settings:

```javascript
// Update with your network details and API keys
```

## Deployment

Deploy to a local network for testing:

```bash
npx hardhat run scripts/deploy.js --network hardhat
```

Deploy to a testnet (e.g. Sepolia):

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## Testing

Run tests:

```bash
npx hardhat test
```

## Contract Addresses (Mainnet)

The contract requires these addresses for deployment:

- Uniswap V2 Router: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- Uniswap V2 Factory: `0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f`
- SushiSwap Router: `0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F`
- SushiSwap Factory: `0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac`
- AAVE Lending Pool Provider V2: `0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5`

## Usage

Once deployed, you can:

1. Search for arbitrage opportunities among common token pairs:
```solidity
searchArbitrageOpportunities(amountIn, minProfitPercentage)
```

2. Check custom token pairs:
```solidity
checkCustomTokenPair(token0, token1, amountIn, minProfitPercentage)
```

## Important Note

This contract only searches for arbitrage opportunities but does not execute trades. Additional code would be required to execute the actual arbitrage.

## License

This project is licensed under the MIT License - see the LICENSE file for details. Although this contract is created by DIGITAL INK.

## Query

This contract is created by DIGITAL INK. For any query contact: virtualtrader1994@gmail.com

## Disclaimer

This software is for educational purposes only. Use at your own risk. Always test thoroughly on testnets before using on mainnet. Trading cryptocurrency involves significant risk.
