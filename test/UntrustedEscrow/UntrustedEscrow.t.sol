// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../../src/UntrustedEscrow/UntrustedEscrow.sol";
import {ERC20Mock} from "../../src/UntrustedEscrow/ERC20Mock.sol";

contract UntrustedEscrowTest is Test {
    UntrustedEscrow public untrustedEscrow;
    ERC20Mock public token;

    address public owner = address(this);
    address public beneficiary = address(0x2E13E1);
    address public depositor = address(0x2E13E1);
    address public nonDepositor = address(0x3ABCE2);

    error ErrorTokenIsZeroAddress();
    error ErrorBeneficiaryIsZeroAddress();
    error ErrorZeroDepositAmount();
    error ErrorEscrowNotFound();
    error ErrorWithdrawalByNonBeneficiary();
    error ErrorEscrowIsNotYetReleasable();

    event Deposited(bytes32 escrowId, address indexed token, address indexed depositor, address indexed beneficiary, uint256 amount, uint256 releaseTime);
    event Withdrawn(bytes32 escrowId, address token, address beneficiary, uint256 amount);

    function setUp() public {
        untrustedEscrow = new UntrustedEscrow();
        token = new ERC20Mock("ERC20Mock", "ERCM");
        token.godTransfer(owner, depositor, 10);
    }

    function test_DepositZeroAddressToken() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorTokenIsZeroAddress.selector));
        untrustedEscrow.deposit(address(0), beneficiary, 1);
    }

    function test_DepositZeroAddressBeneficiary() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorBeneficiaryIsZeroAddress.selector));
        untrustedEscrow.deposit(address(token), address(0), 1);
    }

    function test_DepositZeroTokens() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorZeroDepositAmount.selector));
        untrustedEscrow.deposit(address(token), beneficiary, 0);
    }

    function test_DepositSuccess() public {

        uint256 tokensAmountToDeposit = 10;

        vm.prank(depositor);
        token.approve(address(untrustedEscrow), tokensAmountToDeposit);

        uint256 depositorBalanceBefore = token.balanceOf(depositor);
        uint256 untrustedEscrowBalanceBefore = token.balanceOf(address(untrustedEscrow));

        bytes32 escrowId = keccak256(abi.encodePacked(
            address(token),
            depositor,
            beneficiary,
            tokensAmountToDeposit,
            block.timestamp
        ));

        vm.expectEmit();
        emit Deposited(
            escrowId,
            address(token),
            depositor,
            beneficiary,
            tokensAmountToDeposit,
            block.timestamp + 3 days
        );

        vm.prank(depositor);
        untrustedEscrow.deposit(address(token), beneficiary, tokensAmountToDeposit);

        uint256 depositorBalanceAfter = token.balanceOf(depositor);
        uint256 untrustedEscrowBalanceAfter = token.balanceOf(address(untrustedEscrow));
        
        assertEq(depositorBalanceBefore, untrustedEscrowBalanceAfter);
        assertEq(untrustedEscrowBalanceBefore, depositorBalanceAfter);
    }

    function test_WithdrawNoEscrow() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorEscrowNotFound.selector));
        untrustedEscrow.withdraw(keccak256(abi.encodePacked("123")));
    }

    function test_WithdrawByNonBeneficiary() public {
        uint256 tokensAmountToDeposit = 10;

        vm.prank(depositor);
        token.approve(address(untrustedEscrow), tokensAmountToDeposit);

        vm.prank(depositor);
        bytes32 escrowId = untrustedEscrow.deposit(address(token), beneficiary, tokensAmountToDeposit);

        vm.expectRevert(abi.encodeWithSelector(ErrorWithdrawalByNonBeneficiary.selector));
        vm.prank(nonDepositor);
        untrustedEscrow.withdraw(escrowId);
    }

    function test_WithdrawBeforeTime() public {
        uint256 tokensAmountToDeposit = 10;

        vm.prank(depositor);
        token.approve(address(untrustedEscrow), tokensAmountToDeposit);

        vm.prank(depositor);
        bytes32 escrowId = untrustedEscrow.deposit(address(token), beneficiary, tokensAmountToDeposit);

        vm.expectRevert(abi.encodeWithSelector(ErrorEscrowIsNotYetReleasable.selector));
        vm.prank(beneficiary);
        untrustedEscrow.withdraw(escrowId);
    }
}
