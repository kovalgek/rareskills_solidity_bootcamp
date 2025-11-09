// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC20TokenWithGodMode} from "../../../src/week1/TokenWithGodMode/ERC20TokenWithGodMode.sol";

contract ERC20TokenWithGodModeTest is Test {

    address public owner = address(this);
    address public sender = address(0x2E13E1);
    address public receiver = address(0x6AB43C);
    address public thirdParty = address(0x5544CC);

    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error OwnableUnauthorizedAccount(address account);

    ERC20TokenWithGodMode public token;

    function setUp() public {
        token = new ERC20TokenWithGodMode("TokenWithGodMode", "TWGM");
        token.mint(sender, 2);
    }

    function test_TransferWithAllowanceMechanism() public {
        uint256 amountToTransfer = 2;

        uint256 balanceOfSenderBefore = token.balanceOf(sender);
        uint256 balanceOfReceiverBefore = token.balanceOf(receiver);

        uint256 allowance = token.allowance(sender, thirdParty);
        assertEq(allowance, 0);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, thirdParty, 0, amountToTransfer));
        vm.prank(thirdParty);
        token.transferFrom(sender, receiver, amountToTransfer);

        uint256 balanceOfSenderAfterUnapprovedTry = token.balanceOf(sender);
        uint256 balanceOfReceiverAfterUnapprovedTry = token.balanceOf(receiver);

        assertEq(balanceOfSenderBefore, balanceOfSenderAfterUnapprovedTry);
        assertEq(balanceOfReceiverBefore, balanceOfReceiverAfterUnapprovedTry);

        vm.prank(sender);
        token.approve(thirdParty, amountToTransfer);

        vm.prank(thirdParty);
        token.transferFrom(sender, receiver, amountToTransfer);

        uint256 balanceOfSenderAfterApprovedTry = token.balanceOf(sender);
        uint256 balanceOfReceiverAfterApprovedTry = token.balanceOf(receiver);

        assertEq(balanceOfSenderAfterApprovedTry, balanceOfReceiverBefore);
        assertEq(balanceOfReceiverAfterApprovedTry, balanceOfSenderBefore);
    }

    function test_TransferWithGodMechanism() public {
        uint256 amountToTransfer = 2;

        uint256 balanceOfSenderBefore = token.balanceOf(sender);
        uint256 balanceOfReceiverBefore = token.balanceOf(receiver);

        uint256 allowance = token.allowance(sender, owner);
        assertEq(allowance, 0);

        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientAllowance.selector, owner, 0, amountToTransfer));
        token.transferFrom(sender, receiver, amountToTransfer);

        uint256 balanceOfSenderAfterUnapprovedTry = token.balanceOf(sender);
        uint256 balanceOfReceiverAfterUnapprovedTry = token.balanceOf(receiver);

        assertEq(balanceOfSenderBefore, balanceOfSenderAfterUnapprovedTry);
        assertEq(balanceOfReceiverBefore, balanceOfReceiverAfterUnapprovedTry);

        token.godTransferFrom(sender, receiver, amountToTransfer);

        uint256 balanceOfSenderAfterApprovedTry = token.balanceOf(sender);
        uint256 balanceOfReceiverAfterApprovedTry = token.balanceOf(receiver);

        assertEq(balanceOfSenderAfterApprovedTry, balanceOfReceiverBefore);
        assertEq(balanceOfReceiverAfterApprovedTry, balanceOfSenderBefore);
    }

    function test_GodMechanismAllowedByOwnerOnly() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, thirdParty));
        vm.prank(thirdParty);
        token.godTransferFrom(sender, receiver, 1);
    }
}
