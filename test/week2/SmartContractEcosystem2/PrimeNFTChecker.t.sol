// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {EnumerableNFT} from "../../../src/week2/SmartContractEcosystem2/EnumerableNFT.sol";
import {PrimeNFTChecker} from "../../../src/week2/SmartContractEcosystem2/PrimeNFTChecker.sol";

contract PrimeNFTCheckerTest is Test {
    EnumerableNFT public enumerableNFT;
    PrimeNFTChecker public primeNFTChecker;

    address public owner = address(this);
    address public beneficiary = address(0x2E13E1);

    function setUp() public {
        enumerableNFT = new EnumerableNFT("EnumerableNFT", "ENFT", owner);
        primeNFTChecker = new PrimeNFTChecker(address(enumerableNFT));

        for (uint256 idx = 0; idx <= 100; idx++) {
            enumerableNFT.mint(beneficiary, idx);
        }
    }

    function test_InitialState() public view {
        uint256 numberOfPrimes = primeNFTChecker.getPrimeNumberNFTs(beneficiary);
        assertEq(numberOfPrimes, 25);
    }
}