const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// Contract addresses
const MAINNET_ADDRESSES = {
  uniswapRouter: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  uniswapFactory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  sushiswapRouter: "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F",
  sushiswapFactory: "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac",
  aaveProvider: "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"
};

// Testnet addresses (Sepolia or Goerli - You'll need to update these with actual testnet addresses)
const TESTNET_ADDRESSES = {
  uniswapRouter: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Example - verify these
  uniswapFactory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", // Example - verify these
  sushiswapRouter: "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506", // Example - verify these
  sushiswapFactory: "0xc35DADB65012eC5796536bD9864eD8773aBc74C4", // Example - verify these
  aaveProvider: "0x0000000000000000000000000000000000000000" // Replace with actual testnet address
};

async function main() {
  // Get network name
  const networkName = hre.network.name;
  console.log(`Deploying to ${networkName}...`);
  
  // Select addresses based on network
  const addresses = networkName === "mainnet" ? MAINNET_ADDRESSES : TESTNET_ADDRESSES;
  
  // Get the contract factory
  const SimpleArbitrageSearcher = await hre.ethers.getContractFactory("SimpleArbitrageSearcher");
  
  // Deploy contract
  console.log("Deploying SimpleArbitrageSearcher...");
  const searcher = await SimpleArbitrageSearcher.deploy(
    addresses.uniswapRouter,
    addresses.uniswapFactory,
    addresses.sushiswapRouter,
    addresses.sushiswapFactory,
    addresses.aaveProvider
  );
  
  await searcher.waitForDeployment();
  const searcherAddress = await searcher.getAddress();
  
  console.log(`SimpleArbitrageSearcher deployed to: ${searcherAddress}`);
  
  // Save deployment info
  const deploymentInfo = {
    network: networkName,
    contractAddress: searcherAddress,
    timestamp: new Date().toISOString(),
    addresses: addresses
  };
  
  // Create deployments directory if it doesn't exist
  const deploymentsDir = path.join(__dirname, '../deployments');
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }
  
  // Write deployment info to file
  fs.writeFileSync(
    path.join(deploymentsDir, `${networkName}-deploy.json`),
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("Deployment information saved to deployments directory");
  
  // Wait for a few block confirmations
  console.log("Waiting for confirmations...");
  await searcher.deploymentTransaction().wait(5);
  
  // Verify contract on Etherscan if we have an API key (not for local network)
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: searcherAddress,
        constructorArguments: [
          addresses.uniswapRouter,
          addresses.uniswapFactory,
          addresses.sushiswapRouter,
          addresses.sushiswapFactory,
          addresses.aaveProvider
        ],
      });
      console.log("Contract verified on Etherscan");
    } catch (error) {
      console.error("Error verifying contract:", error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
