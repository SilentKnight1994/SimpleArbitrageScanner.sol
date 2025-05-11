const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// Common token addresses on Ethereum mainnet
const TOKENS = {
  WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
  USDT: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  LINK: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
