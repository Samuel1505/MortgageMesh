// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "lib/v4-periphery/src/base/hooks/BaseTokenWrapperHook.sol";
import {Hooks} from "lib/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "lib/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "lib/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "lib/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "lib/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "lib/v4-core/src/types/BeforeSwapDelta.sol";

import {MortgageClaims} from "./tokens/MortgageClaims.sol";
import {IMortgageOracle} from "./interfaces/IMortgageOracle.sol";

contract MortgageMesh is BaseHook {
    using PoolIdLibrary for PoolKey;

    MortgageClaims public claimsToken;
    IMortgageOracle public oracle;
    uint256 public constant SLIPPAGE_TOLERANCE = 50;

    mapping(PoolId => uint256) public poolMBSIndex;

    constructor(IPoolManager _poolManager, address _oracle) BaseHook(_poolManager) {
        claimsToken = new MortgageClaims();
        oracle = IMortgageOracle(_oracle);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
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
        });
    }

    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata hookData)
        external
        override
        returns (bytes4)
    {
        PoolId poolId = key.toId();
        uint256 currentValue = oracle.latestValue();
        poolMBSIndex[poolId] = currentValue;
        return this.beforeInitialize.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 oracleValue = oracle.latestValue();
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4, int128) {
        int128 amount0 = delta.amount0();
        uint256 claimAmount = uint256(int256(amount0 > 0 ? amount0 : -amount0));
        claimsToken.mint(sender, claimAmount / 100);
        return (this.afterSwap.selector, 0);
    }

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) external override returns (bytes4, BalanceDelta) {
        uint256 liquidityAmount = uint256(params.liquidityDelta);
        claimsToken.mint(sender, liquidityAmount / 10);
        return (this.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }
}