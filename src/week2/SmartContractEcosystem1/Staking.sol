// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Rewardable} from "./ERC20Rewardable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking
/// @author kovalgek
/// @notice Allows to stake NFT and receive ERC20 rewards.
contract Staking is IERC721Receiver, Ownable2Step {
    struct StakedToken {
        address originalOwner;
        uint96 lastClaimedAt;
    }

    /// @notice Amount of token user can claim per `REWARD_TIME`.
    uint96 public constant REWARD_AMOUNT = 10;

    /// @notice Time interval for rewards increase.
    uint96 public constant REWARD_TIME = 1 days;

    /// @notice token that user can stake.
    IERC721 public immutable STAKING_TOKEN;

    /// @notice token that user receive as rewards for staking.
    ERC20Rewardable public immutable REWARD_TOKEN;

    /// @notice staked tokens map.
    mapping (uint256 => StakedToken) private stakedTokens;

    error ErrorZeroParameter(string);
    error ErrorWrongCaller();
    error ErrorTokenAlreadyStaked();
    error ErrorNotTokenOwner();
    error ErrorTokenIsNotStaked(uint256);

    /// @param _stakingToken staking token.
    /// @param _rewardToken rewards token.
    /// @param _owner owner of staking.
    constructor(address _stakingToken, address _rewardToken, address _owner) Ownable(_owner) {
        if(_stakingToken == address(0)) {
            revert ErrorZeroParameter("_stakingToken");
        }
        if(_rewardToken == address(0)) {
            revert ErrorZeroParameter("_rewardToken");
        }
        STAKING_TOKEN = IERC721(_stakingToken);
        REWARD_TOKEN = ERC20Rewardable(_rewardToken);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender != address(STAKING_TOKEN)) {
            revert ErrorWrongCaller();
        }

        if (stakedTokens[tokenId].originalOwner != address(0)) {
            revert ErrorTokenAlreadyStaked();
        }

        stakedTokens[tokenId] = StakedToken({
            originalOwner: from,
            lastClaimedAt: uint96(block.timestamp)
        });

        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Withdraw staked token and claims any available rewards.
    /// @param _tokenId The Id of the token to be withdrawn.
    function withdraw(uint256 _tokenId) external {
        _claimRewards(_tokenId, stakedTokens[_tokenId]);
        delete stakedTokens[_tokenId];
        STAKING_TOKEN.transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice Claim rewards for staked NFT if any.
    /// @param _tokenId The Id of the token to claim rewards for.
    function claimRewards(uint256 _tokenId) external {
        _claimRewards(_tokenId, stakedTokens[_tokenId]);
    }

    function recoverNFT(uint256 _tokenId, address _to) external onlyOwner {
       if (stakedTokens[_tokenId].originalOwner == address(0)) {
            revert ErrorTokenIsNotStaked(_tokenId);
        }
        STAKING_TOKEN.transferFrom(address(this), _to, _tokenId);
    }

    /// @notice Check if token is staked.
    /// @param _tokenId The Id of the token check stake for.
    function isStaked(uint256 _tokenId) external view returns (bool) {
        return stakedTokens[_tokenId].originalOwner != address(0);
    }

    /// @notice Get the original owner of token.
    /// @param _tokenId The Id of the token check owning for.
    function ownerOf(uint256 _tokenId) external view returns (address) {
       address originalOwner = stakedTokens[_tokenId].originalOwner;
       if (originalOwner == address(0)) {
            revert ErrorTokenIsNotStaked(_tokenId);
        }
        return originalOwner;
    }

    /// @notice Get rewards available for token.
    /// @param _tokenId The Id of the token get rewards for.
    function claimableRewards(uint256 _tokenId) external view returns (uint256) {
        StakedToken memory stakedToken = stakedTokens[_tokenId];
        if (stakedToken.originalOwner == address(0)) {
            revert ErrorTokenIsNotStaked(_tokenId);
        }
        return _claimableRewards(stakedToken.lastClaimedAt);
    }

    function _claimRewards(uint256 _tokenId, StakedToken memory stakedToken) private {
        if (stakedToken.originalOwner != msg.sender) {
            revert ErrorNotTokenOwner();
        }

        uint256 rewardAmount = _claimableRewards(stakedToken.lastClaimedAt);
        if (rewardAmount == 0) {
            return;
        }
        stakedTokens[_tokenId].lastClaimedAt = uint96(block.timestamp);
        REWARD_TOKEN.mint(msg.sender, rewardAmount);
    }

    function _claimableRewards(uint96 lastClaimedAt) private view returns (uint256) {
        if (block.timestamp < REWARD_TIME + lastClaimedAt) {
            return 0;
        }
        return (block.timestamp - lastClaimedAt) * REWARD_AMOUNT / REWARD_TIME;
    }
}
