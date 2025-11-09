// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {BancorBondingCurve} from "./BancorBondingCurve.sol";

/// @author kovalgek
contract TokenWithBondingCurve is ERC20, BancorBondingCurve {

    uint256 public immutable SCALE;
    uint256 public immutable RESERVE_RATIO;
    uint256 public reserveBalance;

    error ErrorZeroReserveTokenProvided();
    error ErrorZeroContinuousTokenProvided();
    error ErrorInsufficientTokensToBurn();
    error ErrorNeedInitialETH();
    error ErrorSlippageToleranceExceeded();

    event ContinuousMint(address indexed account, uint256 amount, uint256 deposit);
    event ContinuousBurn(address indexed account, uint256 amount, uint256 reimburseAmount);

    constructor(
        uint256 _reserveRatio,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) payable {
        if (msg.value == 0) revert ErrorNeedInitialETH();
        RESERVE_RATIO = _reserveRatio;
        SCALE = 10 ** decimals();
        reserveBalance = msg.value;
        _mint(msg.sender, 1*SCALE);
    }

    function mint(uint256 _minAmountContinuousToken) external payable {
        _continuousMint(msg.value, _minAmountContinuousToken);
    }

    function burn(uint256 _amount) external {
        uint256 returnAmount = _continuousBurn(_amount);
        Address.sendValue(payable(msg.sender), returnAmount);
    }

    function calculateContinuousMintReturn(uint256 _amount) public view returns (uint256 mintAmount) {
        return calculatePurchaseReturn(totalSupply(), reserveBalance, uint32(RESERVE_RATIO), _amount);
    }

    function calculateContinuousBurnReturn(uint256 _amount) public view returns (uint256 burnAmount) {
        return calculateSaleReturn(totalSupply(), reserveBalance, uint32(RESERVE_RATIO), _amount);
    }

    function _continuousMint(uint256 _deposit, uint256 _minAmountContinuousToken) private returns (uint256) {
        if (_deposit == 0) {
            revert ErrorZeroReserveTokenProvided();
        }

        uint256 amount = calculateContinuousMintReturn(_deposit);
        if(amount < _minAmountContinuousToken) {
            revert ErrorSlippageToleranceExceeded();
        }
        _mint(msg.sender, amount);
        reserveBalance = reserveBalance + _deposit;
        emit ContinuousMint(msg.sender, amount, _deposit);
        return amount;
    }

    function _continuousBurn(uint256 _amount) private returns (uint256) {
        if (_amount == 0) {
            revert ErrorZeroContinuousTokenProvided();
        }
        if (balanceOf(msg.sender) < _amount) {
            revert ErrorInsufficientTokensToBurn();
        }

        uint256 reimburseAmount = calculateContinuousBurnReturn(_amount);
        reserveBalance = reserveBalance - reimburseAmount;
        _burn(msg.sender, _amount);
        emit ContinuousBurn(msg.sender, _amount, reimburseAmount);
        return reimburseAmount;
    }
}
