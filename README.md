# MortgageMesh

A Uniswap v4 Hook implementation for tokenizing mortgage-backed securities (MBS) and creating liquid markets with oracle-based price feeds.

## Overview

MortgageMesh is a custom Uniswap v4 hook that bridges traditional mortgage finance with DeFi. It enables the creation of liquidity pools backed by real-world mortgage data, with automatic reward distribution to participants.

The protocol integrates with mortgage market oracles to provide real-time valuation and creates a tokenized claims system that represents participation in mortgage-backed security pools.

## Features

### Mortgage Claims Token

- **ERC-20 Compatible**: Standard token interface for maximum compatibility
- **Automatic Minting**: Tokens minted directly to users through hook callbacks
- **Dual Reward System**:
  - Liquidity providers receive 10% of their liquidity amount
  - Traders receive 1% of their swap volume

### Oracle-Based Valuation

- Real-time integration with `IMortgageOracle` for MBS pricing
- Records baseline pool valuation at initialization
- Per-pool MBS index tracking via `poolMBSIndex` mapping
- Prepared for dynamic slippage protection (50 basis points tolerance)

### Uniswap v4 Hook Lifecycle

- **beforeInitialize**: Captures initial MBS index value for the pool
- **beforeSwap**: Validates oracle prices (infrastructure for future features)
- **afterSwap**: Distributes claim tokens proportional to swap volume
- **afterAddLiquidity**: Rewards liquidity providers with claim tokens

### Key Benefits

- **Liquidity Incentivization**: Automatic rewards for market participants
- **Real-World Asset Integration**: Connect mortgage markets to DeFi
- **Transparent Pricing**: Oracle-based valuation visible on-chain
- **Composability**: Built on Uniswap v4's modular hook system

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Uniswap v4 Ecosystem                    │
│                                                             │
│  ┌──────────────────┐         ┌──────────────────┐        │
│  │  Pool Manager    │◄────────┤   Pool Key       │        │
│  │  (v4-core)       │         │   (Pool Config)  │        │
│  └────────┬─────────┘         └──────────────────┘        │
│           │                                                 │
│           │ Hook Callbacks                                  │
│           ▼                                                 │
│  ┌──────────────────┐                                      │
│  │  MortgageMesh    │                                      │
│  │  (BaseHook)      │◄─────────┐                          │
│  └────────┬─────────┘           │                          │
└───────────┼─────────────────────┼──────────────────────────┘
            │                     │
            │ Mint Claims         │ Price Feed
            ▼                     │
   ┌─────────────────┐    ┌──────┴───────────┐
   │ MortgageClaims  │    │ IMortgageOracle  │
   │  (ERC-20)       │    │  (External)      │
   └─────────────────┘    └──────────────────┘
```

### Data Flow

1. **Pool Creation**: MortgageMesh records initial MBS index from oracle
2. **Liquidity Addition**: Hook mints claim tokens to LP (10% of liquidity)
3. **Swap Execution**: Hook validates oracle, mints claim tokens to trader (1% of volume)
4. **Oracle Updates**: External oracle provides continuous MBS market data

## Contract Components

### MortgageMesh.sol (Main Hook Contract)

```solidity
contract MortgageMesh is BaseHook
```

**Key State Variables:**

- `claimsToken`: Instance of MortgageClaims ERC-20 token
- `oracle`: Interface to mortgage market price oracle
- `SLIPPAGE_TOLERANCE`: Fixed at 50 basis points (0.5%)
- `poolMBSIndex`: Mapping of pool IDs to their initial MBS index values

**Core Functions:**

- `getHookPermissions()`: Defines which hooks are enabled
- `beforeInitialize()`: Captures baseline MBS index
- `beforeSwap()`: Pre-swap validation hook
- `afterSwap()`: Post-swap reward distribution
- `afterAddLiquidity()`: LP reward distribution

### MortgageClaims.sol (Reward Token)

Expected to be an ERC-20 token with:
- Standard transfer/approve/transferFrom functions
- `mint()` function callable by MortgageMesh contract
- Represents user participation in mortgage pool ecosystem

### IMortgageOracle.sol (Price Feed Interface)

```solidity
interface IMortgageOracle {
    function latestValue() external view returns (uint256);
}
```

Provides real-time mortgage-backed security index values.

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (Forge, Cast, Anvil)
- Git
- Solidity ^0.8.24

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd mortgage-mesh

# Install Foundry dependencies
forge install

# Install Uniswap v4 dependencies
forge install Uniswap/v4-core
forge install Uniswap/v4-periphery

# Build the project
forge build

# Run tests
forge test
```

### Dependencies

```toml
[dependencies]
v4-core = "Uniswap/v4-core"
v4-periphery = "Uniswap/v4-periphery"
```

## Deployment

### 1. Deploy Oracle Contract

First, deploy your mortgage oracle or connect to an existing one:

```solidity
// Example oracle deployment
MortgageOracle oracle = new MortgageOracle(
    initialValue,
    updateFrequency,
    dataSource
);
```

### 2. Deploy MortgageMesh Hook

```solidity
// Deploy with Pool Manager and Oracle addresses
IPoolManager poolManager = IPoolManager(POOL_MANAGER_ADDRESS);
address oracleAddress = address(oracle);

MortgageMesh hook = new MortgageMesh(
    poolManager,
    oracleAddress
);
```

### 3. Create Pool with Hook

```solidity
// Create pool key with hook address
PoolKey memory poolKey = PoolKey({
    currency0: Currency.wrap(address(token0)),
    currency1: Currency.wrap(address(token1)),
    fee: 3000, // 0.3%
    tickSpacing: 60,
    hooks: IHooks(address(hook))
});

// Initialize pool
poolManager.initialize(poolKey, SQRT_PRICE_1_1, "");
```

### Deployment Script Example

```bash
# Set environment variables
export PRIVATE_KEY=<your-private-key>
export RPC_URL=<network-rpc-url>
export POOL_MANAGER=<pool-manager-address>
export ORACLE=<oracle-address>

# Deploy
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

## Usage Examples

### For Liquidity Providers

```solidity
// Add liquidity to MortgageMesh pool
IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
    tickLower: -60,
    tickUpper: 60,
    liquidityDelta: 1000000, // 1M liquidity units
    salt: 0
});

poolManager.modifyLiquidity(poolKey, params, "");

// Automatically receive: 100,000 MortgageClaims tokens (10% of 1M)
```

### For Traders

```solidity
// Execute swap through pool
IPoolManager.SwapParams memory swapParams = IPoolManager.SwapParams({
    zeroForOne: true,
    amountSpecified: 10000, // Swap 10,000 tokens
    sqrtPriceLimitX96: MIN_PRICE_LIMIT
});

poolManager.swap(poolKey, swapParams, "");

// Automatically receive: 100 MortgageClaims tokens (1% of 10,000)
```

### Checking Pool MBS Index

```solidity
// Get pool ID
PoolId poolId = poolKey.toId();

// Check recorded MBS index
uint256 mbsIndex = hook.poolMBSIndex(poolId);

// Compare with current oracle value
uint256 currentValue = hook.oracle().latestValue();
```

## Hook Permissions

MortgageMesh implements the following hook permissions:

```solidity
{
    beforeInitialize: true,              
    afterInitialize: false,             
    beforeAddLiquidity: false,           
    afterAddLiquidity: true,            
    beforeRemoveLiquidity: false,       
    afterRemoveLiquidity: false,         
    beforeSwap: true,                    
    afterSwap: true,                    
    beforeDonate: false,                
    afterDonate: false,                 
    beforeSwapReturnDelta: true,         
    afterSwapReturnDelta: false,         
    afterAddLiquidityReturnDelta: false, 
    afterRemoveLiquidityReturnDelta: false 
}
```

## Reward Distribution

### Liquidity Provider Rewards

- **Rate**: 10% of liquidity added
- **Trigger**: After successful `addLiquidity` operation
- **Formula**: `claimAmount = liquidityDelta / 10`
- **Example**: Add 1,000,000 liquidity → Receive 100,000 MortgageClaims

### Trader Rewards

- **Rate**: 1% of swap volume (based on amount0)
- **Trigger**: After successful swap completion
- **Formula**: `claimAmount = |amount0| / 100`
- **Example**: Swap 50,000 tokens → Receive 500 MortgageClaims

### Claim Token Utility

MortgageClaims tokens can be used for:

- **Governance**: Vote on protocol parameters
- **Fee Sharing**: Earn portion of protocol fees
- **Staking**: Provide additional liquidity incentives
- **Collateral**: Use in other DeFi protocols
- **Trading**: Exchange on secondary markets

## Oracle Integration

### Oracle Requirements

The `IMortgageOracle` interface requires:

```solidity
interface IMortgageOracle {
    /// @notice Returns the latest MBS index value
    /// @return value The current mortgage-backed security index
    function latestValue() external view returns (uint256);
}
```

### Oracle Data Sources

Potential oracle implementations could use:

- **Chainlink**: Decentralized price feeds
- **Band Protocol**: Cross-chain data oracle
- **Custom Oracle**: Proprietary mortgage market data
- **Hybrid**: Multiple source aggregation with median calculation

### Slippage Protection (Future Enhancement)

```solidity
uint256 public constant SLIPPAGE_TOLERANCE = 50; // 0.5%
```

The contract includes infrastructure for slippage protection based on oracle prices. Future versions may implement:

- Maximum allowed deviation from oracle price
- Dynamic fee adjustment based on market conditions
- Circuit breakers for extreme market moves

