// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title ERC721WithDiscount
/// @author kovalgek
/// @notice NFT token with discount option.
contract ERC721WithDiscount is ERC721Royalty, Ownable2Step {
    error ErrorPriceNotMatched(uint256, uint256);
    error ErrorAlreadyClaimed();
    error ErrorInvalidProof();
    error ErrorMaxSupplyReached();

    event TokenMinted(address indexed _to);
    event TokenMintedWithDiscount(address indexed _to);

    /// @notice maximum total supply of tokens.
    uint256 public constant MAX_TOTAL_SUPPLY = 1000;

    /// @notice token price without discount.
    uint256 public constant TOKEN_PRICE = 0.1 ether;

    /// @notice token price with discount.
    uint256 public constant TOKEN_PRICE_WITH_DISCOUNT = 0.01 ether;

    /// @notice reward rate in basic points.
    uint96 public constant REWARD_RATE = 250;

    /// @notice merkle tree root for effective claiming tokens with discount.
    bytes32 public immutable DISCOUNT_ROOT_TREE;
    
    /// @notice token total supply.
    uint256 private totalSupply;

    /// @notice bitmap structure for storing accounts that already minted NFT with discount. 
    BitMaps.BitMap private discountList;

    /// @param _name the name of the token.
    /// @param _symbol the symbol of the token.
    /// @param _owner the address of the token owner.
    /// @param _discountRootTree merkle tree root for effective storing of accounts with discount.
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        bytes32 _discountRootTree
    ) ERC721(_name, _symbol) Ownable(_owner) {
        DISCOUNT_ROOT_TREE = _discountRootTree;
        _setDefaultRoyalty(_owner, REWARD_RATE);
    }

    /// @notice mints token with price without discount.
    /// @notice avg gas price 60_631
    /// @param _to an address token is minted for.
    function mint(address _to) external payable returns (uint256 tokenId) {
        tokenId = _mintForPrice(_to, TOKEN_PRICE);
        emit TokenMinted(_to);
    }

    /// @notice mints token with discount price.
    /// @notice avg gas price 64_992
    /// @param _to account to mint token for.
    /// @param _index off-chain account index.
    /// @param _proof a path of nodes from index to the root.
    function mintWithDiscount(
        address _to,
        uint256 _index,
        bytes32[] calldata _proof
    ) external payable returns (uint256 tokenId) {
        _claimAirdropDiscount(_to, _index, _proof);
        tokenId = _mintForPrice(_to, TOKEN_PRICE_WITH_DISCOUNT);
        emit TokenMintedWithDiscount(_to);
    }

    function _mintForPrice(address _to, uint256 _tokenPrice) private returns (uint256 tokenId) {
        if (msg.value != _tokenPrice) {
            revert ErrorPriceNotMatched(msg.value, _tokenPrice);
        }

        tokenId = totalSupply;
        if (tokenId >= MAX_TOTAL_SUPPLY) {
            revert ErrorMaxSupplyReached();
        }

        unchecked {
            totalSupply = tokenId + 1;
        }
        if (_to.code.length == 0) {
            _mint(_to, tokenId);
        } else {
            _safeMint(_to, tokenId);
        }
    }

    function _claimAirdropDiscount(address _to, uint256 _index, bytes32[] calldata _proof) private {
        if (BitMaps.get(discountList, _index)) {
            revert ErrorAlreadyClaimed();
        }

        bytes32 leaf = keccak256(abi.encodePacked(_to, _index));
        if (!MerkleProof.verifyCalldata(_proof, DISCOUNT_ROOT_TREE, leaf)) {
            revert ErrorInvalidProof();
        }

        BitMaps.set(discountList, _index);
    }
}
