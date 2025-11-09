// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TokenWithBondingCurve} from "../../../src/week1/TokenWithBondingCurve/TokenWithBondingCurve.sol";

contract TokenWithBondingCurveTest is Test {

    address public owner = address(this);
    address public sender = address(0x2E13E1);
    address public buyer = address(0x2E13E1);

    error ErrorZeroReserveTokenProvided();
    error ErrorZeroContinuousTokenProvided();
    error ErrorInsufficientTokensToBurn();

    event ContinuousMint(address indexed account, uint256 amount, uint256 deposit);
    event ContinuousBurn(address indexed account, uint256 amount, uint256 reimburseAmount);

    TokenWithBondingCurve public token;

    function setUp() public {
        uint256 initialETH = 10 * 10**18;
        token = new TokenWithBondingCurve{value: initialETH}(500_000, "TokenWithBondingCurve", "TBC");
        vm.deal(sender, 10 ether);
    }

    function test_ZeroMint() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorZeroReserveTokenProvided.selector));
        token.mint {value: 0}(0);
    }

    function test_Mint() public {
        assertEq(token.balanceOf(sender), 0);

        vm.expectEmit();
        emit ContinuousMint(sender, 140_175_425_099_137_979, 3 ether);

        uint256 mintAmount = 3 ether;
        uint256 minAmountContinuousToken = token.calculateContinuousMintReturn(mintAmount);
        vm.prank(sender);
        token.mint {value: mintAmount}(minAmountContinuousToken);

        assertEq(token.balanceOf(sender), 140_175_425_099_137_979);
    }

    function test_ZeroBurn() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorZeroContinuousTokenProvided.selector));
        token.burn(0);
    }

    function test_InsufficientTokensToBurn() public {
        vm.expectRevert(abi.encodeWithSelector(ErrorInsufficientTokensToBurn.selector));
        vm.prank(sender);
        token.burn(10000);
    }

    function test_Burn() public {
        assertEq(token.balanceOf(sender), 0);

        uint256 mintAmount = 1000000000;
        uint256 minAmountContinuousToken = token.calculateContinuousMintReturn(mintAmount);
        vm.prank(sender);
        token.mint {value: mintAmount}(minAmountContinuousToken);

        assertEq(token.balanceOf(sender), 49999999);

        vm.expectEmit();
        emit ContinuousBurn(sender, 10000, 200000);

        vm.prank(sender);
        token.burn(10000);

        assertEq(token.balanceOf(sender), 49989999);
    }
}
