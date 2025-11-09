// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {console} from "forge-std/console.sol";

contract PrimeNFTChecker {
    error ErrorZeroAddress(string);

    IERC721Enumerable public immutable NFT;

    constructor(address _nft) {
        if (_nft == address(0)) {
            revert ErrorZeroAddress("_nft");
        }
        NFT = IERC721Enumerable(_nft);
    }

    function getPrimeNumberNFTs(address _account) external view returns (uint256 numberOfPrimes) {
        uint256 balance = NFT.balanceOf(_account);
        for (uint256 idx = 0; idx < balance; idx++) {
            uint256 tokenId = NFT.tokenOfOwnerByIndex(_account, idx);
            if (_isPrime(tokenId)) {
                numberOfPrimes += 1;
            }
        }
    }

    function _isPrime(uint256 number) private pure returns (bool) {
        if (number <= 1) {
            return false;
        }

        for (uint256 i = 2; i < number; i++) {
            if (number % i == 0) return false;
        }

        return true;
    }
}