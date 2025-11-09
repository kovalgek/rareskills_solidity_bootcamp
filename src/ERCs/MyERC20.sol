// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// data:
// name, symbol
// totalSupply
// balanceOf
// allowance

// methods
// mint, burn
// transfer
// transferFrom
// approve

contract MyERC20 is Ownable {
    string public name;
    string public symbol;

    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply; 
    uint8 public decimals;

    // owner -> spender -> allowance
    mapping (address => mapping (address => uint256)) allowance;

    error ErrorNotEnoughtBalance();
    error ErrorZeroAddress();
    error ErrorNotEnoughAllowance();

    constructor(string memory _name, string memory _symbol) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        if (_to == address(0)) {
            revert ErrorZeroAddress();
        }
        _update(address(0), _to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        if (_from == address(0)) {
            revert ErrorZeroAddress();
        }
        _update(_from, address(0), _amount);
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {

        _spendAllowance(_from, msg.sender, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) private {
        if (_from == address(0)) {
            revert ErrorZeroAddress();
        }
        if (_to == address(0)) {
            revert ErrorZeroAddress();
        }
        _update(_from, _to, _amount);
    }

    function _update(address _from, address _to, uint256 _amount) private {
        if (_from == address(0)) {
            totalSupply += _amount;
        } else {
            if (balanceOf[_from] < _amount) {
                revert ErrorNotEnoughtBalance();
            }
            balanceOf[_from] -= _amount;
        }

        if (_to == address(0)) {
            totalSupply -= _amount;
        } else {
            balanceOf[_to] += _amount;
        }
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        if (_owner == address(0)) {
            revert ErrorZeroAddress();
        }
        if (_spender == address(0)) {
            revert ErrorZeroAddress();
        }
        allowance[_owner][_spender] = _amount;
    }

    function _spendAllowance(address _owner, address _spender, uint256 _amount) private {
        uint256 currentAllowance = allowance[_owner][_spender];
        if (currentAllowance < _amount) {
            revert ErrorNotEnoughAllowance();
        }
        _approve(_owner, _spender, currentAllowance - _amount);
    }
}