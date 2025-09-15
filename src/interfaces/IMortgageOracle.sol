// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IMortgageOracle {
    function latestValue() external view returns (uint256);
}
