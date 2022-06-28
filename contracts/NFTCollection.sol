// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTCollection is ERC721 {
    uint256 public tokens;

    constructor() ERC721("NFT Collection", "NC") {}

    function mint() public payable {
        tokens++;
        _mint(msg.sender, tokens);
    }
}
