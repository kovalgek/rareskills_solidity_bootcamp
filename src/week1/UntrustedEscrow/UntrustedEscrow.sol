// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";

contract UntrustedEscrow {

    using SafeERC20 for IERC20;

    struct Escrow {
        address token;
        address depositor;
        address beneficiary;
        uint256 amount;
        uint256 releaseTime;
    }

    error ErrorTokenIsZeroAddress();
    error ErrorZeroDepositAmount();
    error ErrorBeneficiaryIsZeroAddress();
    error ErrorEscrowNotFound();
    error ErrorWithdrawalByNonBeneficiary();
    error ErrorEscrowIsNotYetReleasable();

    event Deposited(bytes32 escrowId, address indexed token, address indexed depositor, address indexed beneficiary, uint256 amount, uint256 releaseTime);
    event Withdrawn(bytes32 escrowId, address token, address beneficiary, uint256 amount);

    mapping(bytes32 => Escrow) public escrows;
    uint256 public constant WITHDRAW_DELAY = 3 days;

    function deposit(address _token, address _beneficiary, uint256 _amount) external returns (bytes32) {
        if (_token == address(0)) {
            revert ErrorTokenIsZeroAddress();
        }
        if (_beneficiary == address(0)) {
            revert ErrorBeneficiaryIsZeroAddress();
        }
        if (_amount == 0) {
            revert ErrorZeroDepositAmount();
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        bytes32 escrowId = keccak256(abi.encodePacked(
            _token,
            msg.sender,
            _beneficiary,
            _amount,
            block.timestamp
        ));

        escrows[escrowId] = Escrow({
            token: _token,
            depositor: msg.sender,
            beneficiary: _beneficiary,
            amount: _amount,
            releaseTime: block.timestamp + WITHDRAW_DELAY
        });

        emit Deposited(escrowId, _token, msg.sender, _beneficiary, _amount, escrows[escrowId].releaseTime);

        return escrowId;
    }

    function withdraw(bytes32 _escrowId) external {

        Escrow storage escrow = escrows[_escrowId];

        if (escrow.token == address(0)) {
            revert ErrorEscrowNotFound();
        }
        if (msg.sender != escrow.beneficiary) {
            revert ErrorWithdrawalByNonBeneficiary();
        }
        if (block.timestamp < escrow.releaseTime) {
            revert ErrorEscrowIsNotYetReleasable();
        }

        uint256 amount = escrow.amount;
        escrow.amount = 0;
        
        IERC20(escrow.token).safeTransfer(escrow.beneficiary, amount);

        emit Withdrawn(_escrowId, escrow.token, escrow.beneficiary, amount);
    }
}
