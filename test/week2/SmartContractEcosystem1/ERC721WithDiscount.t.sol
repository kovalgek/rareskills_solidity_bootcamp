// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC721WithDiscount} from "../../../src/week2/SmartContractEcosystem1/ERC721WithDiscount.sol";
import {Merkle} from "murky/Merkle.sol";

contract ERC721WithDiscountTest is Test {

    ERC721WithDiscount public erc721;

    Merkle private merkle = new Merkle();
    uint256 private constant numberOfAccounts = 10;

    address public owner = address(this);
    address public sender = address(0x2E13E1);
    address public beneficiary = address(0x2E13E1);

    address[] public airdropAccounts; 
    bytes32[] public leaves;

    error ErrorMaxSupplyReached();
    error ErrorPriceNotMatched(uint256, uint256);
    error ErrorInvalidProof();
    error ErrorAlreadyClaimed();

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        vm.deal(sender, 100 ether);

        for(uint256 i = 0; i < numberOfAccounts; i++) {
            address airdropAccount = address(uint160(1) + uint160(i));
            airdropAccounts.push(airdropAccount);
            leaves.push(keccak256(abi.encodePacked(airdropAccount, i)));
        }
        bytes32 root = merkle.getRoot(leaves);
        erc721 = new ERC721WithDiscount("ERC721WithDiscount","NFTD", owner, root);
    }

    function test_InitialState() public view {
        assertEq(erc721.MAX_TOTAL_SUPPLY(), 1000);
        assertEq(erc721.TOKEN_PRICE(), 0.1 ether);
        assertEq(erc721.TOKEN_PRICE_WITH_DISCOUNT(), 0.01 ether);
        assertEq(erc721.REWARD_RATE(), 250);
    }

    function test_MintWithoutDiscountWrongPrice() public {
        uint256 tokenPrice = erc721.TOKEN_PRICE();
        uint256 providedPrice = tokenPrice - 1;
        vm.expectRevert(abi.encodeWithSelector(ErrorPriceNotMatched.selector, providedPrice, tokenPrice));
        erc721.mint{value: providedPrice}(beneficiary);
    }

    function test_MintMoreThanMaxSupply() public {
        uint256 maxSupply = erc721.MAX_TOTAL_SUPPLY();
        uint256 tokenPrice = erc721.TOKEN_PRICE();
        vm.prank(sender);
        for (uint256 i = 0; i < maxSupply; ++i) {
            erc721.mint{value: tokenPrice}(beneficiary);
        }
        vm.expectRevert(abi.encodeWithSelector(ErrorMaxSupplyReached.selector));
        erc721.mint{value: tokenPrice}(beneficiary);
    }

    function test_MintWithoutDiscountSuccess() public {
        uint256 tokenId = erc721.mint{value: erc721.TOKEN_PRICE()}(beneficiary);
        assertEq(erc721.ownerOf(tokenId), beneficiary);
    }

    function test_MintWithDiscountInvalidProof() public {
        bytes32[] memory proof = merkle.getProof(leaves, 0);
        uint256 tokenPriceWithDiscount = erc721.TOKEN_PRICE_WITH_DISCOUNT();
        vm.expectRevert(abi.encodeWithSelector(ErrorInvalidProof.selector));
        erc721.mintWithDiscount{value: tokenPriceWithDiscount}(beneficiary, 0, proof);

        delete proof[2];
        address airdropAccount = airdropAccounts[0];
        vm.expectRevert(abi.encodeWithSelector(ErrorInvalidProof.selector));
        erc721.mintWithDiscount{value: tokenPriceWithDiscount}(airdropAccount, 0, proof);
    }

    function test_MintWithDiscountAlreadyClaimed() public {
        address airdropAccount = airdropAccounts[0];
        bytes32[] memory proof = merkle.getProof(leaves, 0);
        uint256 tokenPriceWithDiscount = erc721.TOKEN_PRICE_WITH_DISCOUNT();
        erc721.mintWithDiscount{value: tokenPriceWithDiscount}(airdropAccount, 0, proof);
        vm.expectRevert(abi.encodeWithSelector(ErrorAlreadyClaimed.selector));
        erc721.mintWithDiscount{value: tokenPriceWithDiscount}(airdropAccount, 0, proof);
    }

    function test_MintWithDiscountSuccess() public {
        address airdropAccount = airdropAccounts[0];
        bytes32[] memory proof = merkle.getProof(leaves, 0);
        uint256 tokenPriceWithDiscount = erc721.TOKEN_PRICE_WITH_DISCOUNT();
        uint256 tokenId = erc721.mintWithDiscount{value: tokenPriceWithDiscount}(airdropAccount, 0, proof);
        assertEq(erc721.ownerOf(tokenId), airdropAccount);
    }
}
