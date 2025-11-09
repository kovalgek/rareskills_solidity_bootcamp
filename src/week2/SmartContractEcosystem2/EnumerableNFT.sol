// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EnumerableNFT is ERC721Enumerable, Ownable {

    constructor(string memory _name, string memory _symbol, address _owner) ERC721(_name, _symbol) Ownable(_owner) {
        
    }

    function mint(address _to, uint256 _tokenId) external onlyOwner {
        _mint(_to, _tokenId);
    }
}