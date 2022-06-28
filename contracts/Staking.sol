// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NFTCollection.sol";
import "./RewardsToken.sol";

contract Staking is IERC721Receiver {
    event Staked(address _staker, address _collection, uint256 _tokenId);
    event Unstaked(address _staker, address _collection, uint256 _tokenId);
    event Claimed(address _staker, uint256 _amount);
    event Liquidated(address _staker, address _collection, uint256 _tokenId);

    struct Stake {
        address staker;
        address collection;
        uint256 blockNumber;
        uint256 tokenId;
    }

    /*
     * Collection Address -> TokenID -> Stake Struct
     */

    mapping(address => mapping(uint256 => Stake)) public stakes;

    uint256 public totalStakes;

    RewardsToken token;

    constructor(RewardsToken _token) {
        token = _token;
    }

    function stake(address _collection, uint256[] calldata _tokenIds) public {
        _stake(msg.sender, _collection, _tokenIds);
    }

    function unstake(
        address _collection,
        uint256[] calldata _tokenIds,
        bool[] calldata _shouldLiquidate
    ) public {
        require(
            _shouldLiquidate.length == _tokenIds.length,
            "Staking::stake: Invalid params length"
        );

        totalStakes -= _tokenIds.length;
        uint256 tokenId;

        claim(_collection, _tokenIds);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];

            Stake memory staked = stakes[_collection][tokenId];

            require(
                staked.staker == msg.sender,
                "Staking::unstake:You can't unstake token"
            );

            delete stakes[_collection][tokenId];

            if (_shouldLiquidate[i]) {
                emit Liquidated(msg.sender, _collection, tokenId);
            } else {
                IERC721(_collection).transferFrom(
                    address(this),
                    msg.sender,
                    tokenId
                );

                emit Unstaked(msg.sender, _collection, tokenId);
            }
        }
    }

    function claim(address _collection, uint256[] calldata _tokenIds) public {
        uint256 tokenId;
        uint256 totalEarned = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];

            Stake storage staked = stakes[_collection][tokenId];
            require(staked.staker == msg.sender, "not an owner");

            totalEarned +=
                (1000000 ether * (block.number - staked.blockNumber)) /
                (1 days / 15);

            staked.blockNumber = uint256(block.number);
        }

        if (totalEarned > 0) {
            totalEarned /= 1000;
            token.mint(msg.sender, totalEarned);
        }

        emit Claimed(msg.sender, totalEarned);
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        uint32 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }

        if (size > 0) {
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = _tokenId;
            _stake(_from, msg.sender, tokenIds);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function _stake(
        address _sender,
        address _collection,
        uint256[] memory _tokenIds
    ) internal {
        uint256 tokenId;
        totalStakes += _tokenIds.length;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];

            require(
                IERC721(_collection).ownerOf(tokenId) == _sender,
                "Staking::stake:You're not the owner"
            );
            require(
                stakes[_collection][tokenId].tokenId == 0,
                "Staking::stake:Already Staked"
            );

            IERC721(_collection).transferFrom(_sender, address(this), tokenId);

            stakes[_collection][tokenId] = Stake({
                collection: _collection,
                tokenId: tokenId,
                staker: _sender,
                blockNumber: uint256(block.number)
            });

            emit Staked(_sender, _collection, tokenId);
        }
    }
}
