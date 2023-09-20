// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
There’s a pool offering rewards in tokens every 5 days 
for those who deposit their DVT tokens into it.

Alice, Bob, Charlie and David have already deposited some DVT tokens, 
and have won their rewards!

You don’t have any DVT tokens. 
But in the upcoming round, you must claim most rewards for yourself.

By the way, rumours say a new pool has just launched. 
Isn’t it offering flash loans of DVT tokens?

 */

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {AccountingToken} from "../src/5. the-rewarder/AccountingToken.sol";
import {RewardToken} from "../src/5. the-rewarder/RewardToken.sol";
import {FlashLoanerPool} from "../src/5. the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool} from "../src/5. the-rewarder/TheRewarderPool.sol";

import {Attack} from "../src/5. the-rewarder/Attack.sol";

contract RewarderAttackTest is StdCheats, Test {

    DamnValuableToken public DVToken;
    
    FlashLoanerPool public flashPool;
    TheRewarderPool public rewardPool;
    
    AccountingToken public AToken;
    RewardToken public RToken; 

    Attack public attacker;

    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;    
    uint256 public constant REWARDS = 100 ether;
    
    uint256 public constant FLASHPOOL_START_BALANCE = 1000000 ether;
    uint256 public constant USERS_DEPOSIT = 100 ether;

    address public alice = address(1);
    address public bob = address(2);
    address public charlie = address(3);
    address public david = address(4);


    address[4] public users = [alice, bob, charlie, david]; 


    function setUp() public {

        DVToken = new DamnValuableToken();

        flashPool = new FlashLoanerPool(address(DVToken));
        rewardPool = new TheRewarderPool(address(DVToken));

        AToken = rewardPool.accountingToken();
        RToken = rewardPool.rewardToken();

        DVToken.transfer(address(flashPool), FLASHPOOL_START_BALANCE);

        for(uint i=0; i<users.length; i++) {
            
            DVToken.transfer(users[i], USERS_DEPOSIT);
           
            vm.startPrank(users[i]);
            DVToken.approve(address(rewardPool) , USERS_DEPOSIT);
            rewardPool.deposit(USERS_DEPOSIT);
            vm.stopPrank();

            assertEq(AToken.balanceOf(users[i]), USERS_DEPOSIT);
        }

        console.log("Round Number :", rewardPool.roundNumber());            // 1

        assertEq(AToken.totalSupply(), USERS_DEPOSIT * users.length);
        assertEq(RToken.totalSupply(), 0);


    }   


    function testOwner() public {
        assertEq(AToken.owner() , address(rewardPool));
        assertEq(RToken.owner() , address(rewardPool));
    }



    function testAttack() public {      

        attacker = new Attack();        
        
        skip(REWARDS_ROUND_MIN_DURATION);     // skipping 5 days

        attacker.pwn(address(flashPool), address(rewardPool), address(DVToken), address(RToken));

        console.log("Round Number :", rewardPool.roundNumber());            // 2
        assertEq(rewardPool.roundNumber(), 2);

        for (uint i=0; i < users.length; i++) {

            vm.startPrank(users[i]);
            rewardPool.distributeRewards();
            vm.stopPrank();
            console.log(users[i], "RToken Balance :", RToken.balanceOf(users[i]) / 10**15 );     // diving by this factor 10**15 for clarity in console
            
        }
        
        console.log("Attacker RToken Balance :", RToken.balanceOf(address(attacker)) / 10**15);  // diving by this factor 10**15 for clarity in console

    }
  
}

