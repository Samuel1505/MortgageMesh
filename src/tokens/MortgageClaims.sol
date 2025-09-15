// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC6909} from "../interfaces/IERC6909.sol";

contract MortgageClaims is IERC6909 {
    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _allowances;
    mapping(address => mapping(address => bool)) private _operators;

    uint256 public totalSupply;
    uint256 public constant MORTGAGE_ID = 1;

    function mint(address to, uint256 amount) external {
        _balances[to][MORTGAGE_ID] += amount;
        totalSupply += amount;
        emit Transfer(msg.sender, address(0), to, MORTGAGE_ID, amount);
    }

    function burn(address from, uint256 amount) external {
        require(_balances[from][MORTGAGE_ID] >= amount, "Insufficient balance");
        _balances[from][MORTGAGE_ID] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, from, address(0), MORTGAGE_ID, amount);
    }

    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        return _balances[owner][id];
    }

    function allowance(address owner, address spender, uint256 id) external view returns (uint256) {
        return _allowances[owner][spender][id];
    }

    function isOperator(address owner, address spender) external view returns (bool) {
        return _operators[owner][spender];
    }

    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool) {
        require(_balances[msg.sender][id] >= amount, "Insufficient balance");
        _balances[msg.sender][id] -= amount;
        _balances[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool) {
        if (_operators[sender][msg.sender]) {
            // unlimited transfers
        } else {
            require(_allowances[sender][msg.sender][id] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender][id] -= amount;
        }
        require(_balances[sender][id] >= amount, "Insufficient balance");
        _balances[sender][id] -= amount;
        _balances[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }

    function approve(address spender, uint256 id, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    function setOperator(address spender, bool approved) external returns (bool) {
        _operators[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }
}
