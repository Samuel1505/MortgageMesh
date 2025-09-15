// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC6909 {
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);
    function isOperator(address owner, address spender) external view returns (bool status);
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool success);
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 id, uint256 amount) external returns (bool success);
    function setOperator(address spender, bool approved) external returns (bool success);

    event Transfer(address indexed caller, address indexed sender, address indexed receiver, uint256 id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed spender, bool approved);
    event Approval(address indexed owner, address indexed spender, uint256 id, uint256 amount);
}
