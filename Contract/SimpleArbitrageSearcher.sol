// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

/**
 * @title SimpleArbitrageSearcher
 * @dev A contract that searches for arbitrage opportunities between two DEXes
 */
contract SimpleArbitrageSearcher is Ownable {
    // DEX routers
    address public dex1Router;
    address public dex2Router;
    
    // DEX factories
    address public dex1Factory;
    address public dex2Factory;
    
    // AAVE lending pool addresses provider
    address public aaveLendingPoolAddressesProvider;
    
    // Common token addresses (examples - you'll need to use the correct ones for your network)
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Mainnet USDC
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;  // Mainnet DAI
    
    // Structure to store arbitrage opportunity details
    struct ArbitrageOpportunity {
        address token0;
        address token1;
        address dex1Pair;
        address dex2Pair;
        uint256 profitInToken0;
        address aavePool;
    }
    
    // Event for when an arbitrage opportunity is found
    event ArbitrageOpportunityFound(
        address token0,
        address token1,
        address dex1Pair,
        address dex2Pair,
        uint256 profitInToken0,
        address aavePool
    );
    
    /**
     * @dev Constructor that sets the DEX and AAVE addresses
     */
    constructor(
        address _dex1Router,
        address _dex1Factory,
        address _dex2Router,
        address _dex2Factory,
        address _aaveProvider
    ) Ownable(msg.sender) {
        require(_dex1Router != address(0), "Invalid DEX1 router");
        require(_dex1Factory != address(0), "Invalid DEX1 factory");
        require(_dex2Router != address(0), "Invalid DEX2 router");
        require(_dex2Factory != address(0), "Invalid DEX2 factory");
        require(_aaveProvider != address(0), "Invalid AAVE provider");
        
        dex1Router = _dex1Router;
        dex1Factory = _dex1Factory;
        dex2Router = _dex2Router;
        dex2Factory = _dex2Factory;
        aaveLendingPoolAddressesProvider = _aaveProvider;
    }
    
    /**
     * @dev Helper function to calculate DEX1 to DEX2 profit
     */
    function _calculateDex1ToDex2Profit(
        address token0,
        address token1,
        uint256 amountIn
    ) private view returns (uint256 profit) {
        // Create path arrays
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        
        address[] memory pathReverse = new address[](2);
        pathReverse[0] = token1;
        pathReverse[1] = token0;
        
        // Get price on DEX1 (token0 -> token1)
        uint[] memory amountsOutDex1 = IUniswapV2Router(dex1Router).getAmountsOut(amountIn, path);
        uint256 amountOutDex1 = amountsOutDex1[1];
        
        // Return zero if no output from DEX1
        if (amountOutDex1 == 0) return 0;
        
        // Check DEX1 -> DEX2 arbitrage (buy on DEX1, sell on DEX2)
        uint[] memory amountsBackDex2 = IUniswapV2Router(dex2Router).getAmountsOut(amountOutDex1, pathReverse);
        uint256 amountBackDex2 = amountsBackDex2[1];
        
        if (amountBackDex2 > amountIn) {
            profit = amountBackDex2 - amountIn;
        }
        
        return profit;
    }
    
    /**
     * @dev Helper function to calculate DEX2 to DEX1 profit
     */
    function _calculateDex2ToDex1Profit(
        address token0,
        address token1,
        uint256 amountIn
    ) private view returns (uint256 profit) {
        // Create path arrays
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        
        address[] memory pathReverse = new address[](2);
        pathReverse[0] = token1;
        pathReverse[1] = token0;
        
        // Get price on DEX2 (token0 -> token1)
        uint[] memory amountsOutDex2 = IUniswapV2Router(dex2Router).getAmountsOut(amountIn, path);
        uint256 amountOutDex2 = amountsOutDex2[1];
        
        // Return zero if no output from DEX2
        if (amountOutDex2 == 0) return 0;
        
        // Check DEX2 -> DEX1 arbitrage (buy on DEX2, sell on DEX1)
        uint[] memory amountsBackDex1 = IUniswapV2Router(dex1Router).getAmountsOut(amountOutDex2, pathReverse);
        uint256 amountBackDex1 = amountsBackDex1[1];
        
        if (amountBackDex1 > amountIn) {
            profit = amountBackDex1 - amountIn;
        }
        
        return profit;
    }
    
    /**
     * @dev Checks if there is an arbitrage opportunity between two DEXes for a token pair
     */
    function checkArbitrageOpportunity(
        address token0,
        address token1,
        uint256 amountIn
    ) public view returns (ArbitrageOpportunity memory) {
        // Make sure the input parameters are valid
        require(token0 != address(0) && token1 != address(0), "Invalid token addresses");
        require(token0 != token1, "Tokens must be different");
        require(amountIn > 0, "Amount must be greater than 0");
        
        // Get pair addresses from both DEXes
        address pair1 = IUniswapV2Factory(dex1Factory).getPair(token0, token1);
        address pair2 = IUniswapV2Factory(dex2Factory).getPair(token0, token1);
        
        // Check if pairs exist
        if (pair1 == address(0) || pair2 == address(0)) {
            return ArbitrageOpportunity(address(0), address(0), address(0), address(0), 0, address(0));
        }
        
        // Calculate profits both ways
        uint256 profit1 = _calculateDex1ToDex2Profit(token0, token1, amountIn);
        uint256 profit2 = _calculateDex2ToDex1Profit(token0, token1, amountIn);
        
        // Get AAVE lending pool address
        address aavePool = ILendingPoolAddressesProvider(aaveLendingPoolAddressesProvider).getLendingPool();
        
        // Determine which way is more profitable
        uint256 maxProfit = profit1 > profit2 ? profit1 : profit2;
        
        if (maxProfit > 0) {
            return ArbitrageOpportunity(
                token0,
                token1,
                pair1,
                pair2,
                maxProfit,
                aavePool
            );
        }
        
        return ArbitrageOpportunity(address(0), address(0), address(0), address(0), 0, address(0));
    }
    
    /**
     * @dev Searches for arbitrage opportunities among common token pairs
     */
    function searchArbitrageOpportunities(
        uint256 amountIn,
        uint256 minProfitPercentage
    ) external returns (ArbitrageOpportunity[] memory) {
        // Define common tokens to check
        address[] memory tokens = new address[](3);
        tokens[0] = WETH;
        tokens[1] = USDC;
        tokens[2] = DAI;
        
        // Create temporary array to store opportunities (maximum possible size)
        ArbitrageOpportunity[] memory tempOpportunities = new ArbitrageOpportunity[](tokens.length * (tokens.length - 1) / 2);
        
        // Counter for valid opportunities
        uint256 count = 0;
        
        // Check all token combinations
        for (uint i = 0; i < tokens.length; i++) {
            for (uint j = i + 1; j < tokens.length; j++) {
                ArbitrageOpportunity memory opportunity = checkArbitrageOpportunity(tokens[i], tokens[j], amountIn);
                
                // Calculate profit percentage (scaled by 10000 for precision, so 100 = 1%)
                if (opportunity.profitInToken0 > 0) {
                    uint256 profitPercentage = opportunity.profitInToken0 * 10000 / amountIn;
                    
                    // Add to list if profitable enough
                    if (profitPercentage >= minProfitPercentage) {
                        tempOpportunities[count] = opportunity;
                        count++;
                        
                        // Emit event for logging
                        emit ArbitrageOpportunityFound(
                            opportunity.token0,
                            opportunity.token1,
                            opportunity.dex1Pair,
                            opportunity.dex2Pair,
                            opportunity.profitInToken0,
                            opportunity.aavePool
                        );
                    }
                }
            }
        }
        
        // Create final array of exact size
        ArbitrageOpportunity[] memory opportunities = new ArbitrageOpportunity[](count);
        for (uint i = 0; i < count; i++) {
            opportunities[i] = tempOpportunities[i];
        }
        
        return opportunities;
    }
    
    /**
     * @dev Add custom token pairs to check for arbitrage
     */
    function checkCustomTokenPair(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 minProfitPercentage
    ) external returns (ArbitrageOpportunity memory opportunity) {
        opportunity = checkArbitrageOpportunity(token0, token1, amountIn);
        
        if (opportunity.profitInToken0 > 0) {
            // Calculate profit percentage (scaled by 10000 for precision, so 100 = 1%)
            uint256 profitPercentage = opportunity.profitInToken0 * 10000 / amountIn;
            
            // Emit event if profitable enough
            if (profitPercentage >= minProfitPercentage) {
                emit ArbitrageOpportunityFound(
                    opportunity.token0,
                    opportunity.token1,
                    opportunity.dex1Pair,
                    opportunity.dex2Pair,
                    opportunity.profitInToken0,
                    opportunity.aavePool
                );
            }
        }
        
        return opportunity;
    }
    
    /**
     * @dev Update DEX router addresses
     */
    function updateDexAddresses(
        address _dex1Router,
        address _dex1Factory,
        address _dex2Router,
        address _dex2Factory
    ) external onlyOwner {
        require(_dex1Router != address(0), "Invalid DEX1 router");
        require(_dex1Factory != address(0), "Invalid DEX1 factory");
        require(_dex2Router != address(0), "Invalid DEX2 router");
        require(_dex2Factory != address(0), "Invalid DEX2 factory");
        
        dex1Router = _dex1Router;
        dex1Factory = _dex1Factory;
        dex2Router = _dex2Router;
        dex2Factory = _dex2Factory;
    }
    
    /**
     * @dev Update AAVE lending pool provider address
     */
    function updateAaveProvider(address _aaveProvider) external onlyOwner {
        require(_aaveProvider != address(0), "Invalid AAVE provider");
        aaveLendingPoolAddressesProvider = _aaveProvider;
    }
}
