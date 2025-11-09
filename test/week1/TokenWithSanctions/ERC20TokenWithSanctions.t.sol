// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC20TokenWithSanctions} from "../../../src/week1/TokenWithSanctions/ERC20TokenWithSanctions.sol";

contract ERC20TokenWithSanctionsTest is Test {

    address public owner = address(this);
    address public sender = address(0x2E13E1);
    address public receiver = address(0x6AB43C);
    address public thirdParty = address(0x5544CC);

    error ErrorSenderBanned(address);
    error ErrorRecipientBanned(address);

    event AddressBanned(address indexed account);
    event AddressUnbanned(address indexed account);

    ERC20TokenWithSanctions public token;

    function setUp() public {
        token = new ERC20TokenWithSanctions("TokenWithSanctions", "TWS");
        token.mint(sender, 2);
    }

    function test_Ban() public {
        assertFalse(token.isBanned(sender));

	    vm.expectEmit();
        emit AddressBanned(sender);

        token.banAddress(sender);
        assertTrue(token.isBanned(sender));

	    vm.expectEmit();
        emit AddressUnbanned(sender);

        token.unbanAddress(sender);
        assertFalse(token.isBanned(sender));
    }

    function test_TransferBannedSender() public {
        token.banAddress(sender);

        vm.expectRevert(abi.encodeWithSelector(ErrorSenderBanned.selector, sender));
        vm.prank(sender);
        token.transfer(receiver, 1);
    }

    function test_TransferBannedReceiver() public {
        token.banAddress(receiver);

        vm.expectRevert(abi.encodeWithSelector(ErrorRecipientBanned.selector, receiver));
        token.transfer(receiver, 1);
    }

    function test_Transfer() public {

        uint256 tokensToTransfer = 1;

        uint256 senderBalanceBefore = token.balanceOf(sender);
        uint256 receiverBalanceBefore = token.balanceOf(receiver);

        vm.prank(sender);
        token.transfer(receiver, tokensToTransfer);

        uint256 senderBalanceAfter = token.balanceOf(sender);
        uint256 receiverBalanceAfter = token.balanceOf(receiver);

        assertEq(senderBalanceBefore - senderBalanceAfter, tokensToTransfer, "expect spending tokens");
        assertEq(receiverBalanceAfter - receiverBalanceBefore, tokensToTransfer, "expect receiving tokens");
    }

    function test_TransferFromBannedSender() public {
        token.banAddress(sender);

        vm.prank(sender);
        token.approve(thirdParty, 1);

        vm.expectRevert(abi.encodeWithSelector(ErrorSenderBanned.selector, sender));
        vm.prank(thirdParty);
        token.transferFrom(sender, receiver, 1);
    }

    function test_TransferFromBannedReceiver() public {
        token.banAddress(receiver);

        vm.prank(sender);
        token.approve(thirdParty, 1);

        vm.expectRevert(abi.encodeWithSelector(ErrorRecipientBanned.selector, receiver));
        vm.prank(thirdParty);
        token.transferFrom(sender, receiver, 1);
    }

    function test_TransferFrom() public {

        uint256 tokensToTransfer = 1;

        uint256 senderBalanceBefore = token.balanceOf(sender);
        uint256 receiverBalanceBefore = token.balanceOf(receiver);

        vm.prank(sender);
        token.approve(thirdParty, tokensToTransfer);
        vm.prank(thirdParty);
        token.transferFrom(sender, receiver, tokensToTransfer);

        uint256 senderBalanceAfter = token.balanceOf(sender);
        uint256 receiverBalanceAfter = token.balanceOf(receiver);

        assertEq(senderBalanceBefore - senderBalanceAfter, tokensToTransfer, "expect spending tokens");
        assertEq(receiverBalanceAfter - receiverBalanceBefore, tokensToTransfer, "expect receiving tokens");
    }
}
