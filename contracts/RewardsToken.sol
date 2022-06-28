// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardsToken is ERC20, Ownable {
    mapping(address => bool) public controllers;

    constructor() ERC20("RewardsToken", "RT") {}

    function mint(address _to, uint256 _amount) public {
        require(
            controllers[msg.sender],
            "RewardsToken:mint::You're not controller"
        );
        _mint(_to, _amount);
    }

    function addController(address _controller) external onlyOwner {
        require(
            _controller != address(0),
            "RewardsToken:mint::Invalid controller address"
        );
        controllers[_controller] = true;
    }

    function removeController(address _controller) external onlyOwner {
        require(
            _controller != address(0),
            "RewardsToken:mint::Invalid controller address"
        );
        delete controllers[_controller];
    }
}
