//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {DamnValuableTokenSnapshot} from "../src/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../src/6. selfie/SimpleGovernance.sol";
import {SelfiePool} from "../src/6. selfie/SelfiePool.sol";
import {Attack} from "../src/6. selfie/Attack.sol";

contract SelfieAttackTest is StdCheats, Test {


DamnValuableTokenSnapshot public dvToken;
SimpleGovernance public sGovern;
SelfiePool public fPool;
Attack public attacker;

uint256 public constant TOTAL_SUPPLY = 2000000 ether;
uint256 public constant POOL_INITIAL_BALANCE = 1500000 ether;

uint256 constant WAITING_PERIOD_2_DAYS = 2 days;


function setUp() public {

    dvToken = new DamnValuableTokenSnapshot(TOTAL_SUPPLY);
    sGovern = new SimpleGovernance(address(dvToken));
    fPool = new SelfiePool(address(dvToken), address(sGovern));

    dvToken.transfer(address(fPool) , POOL_INITIAL_BALANCE);

    attacker = new Attack(address(fPool), address(sGovern), address(dvToken));

    
}

function testSetUp() public {

    assertEq(address(fPool.token()), address(dvToken));
    assertEq(address(fPool.governance()), address(sGovern));

    assertEq(dvToken.balanceOf(address(fPool)) , POOL_INITIAL_BALANCE);
    assertEq(fPool.maxFlashLoan(address(dvToken)), POOL_INITIAL_BALANCE);

}


function testAttack1() public {

    console.log("MSG SENDER", msg.sender);
    attacker.attack1();
    console.log("attack1 executed successfully, snapshot taken");
    console.log("snapshotId :", attacker.snapshotId());

    uint256 attackerBalance = dvToken.getBalanceAtLastSnapshot(address(attacker));
    console.log("attacker balance on snapshot:", attackerBalance);
    console.log("actionId : ", attacker.actionId());
    
    assertEq(attackerBalance, POOL_INITIAL_BALANCE);
    
}


function testAttack2After2Days() public {

    attacker.attack1();

    console.log("MSG SENDER", msg.sender);
    console.log("before 2 days", block.timestamp);
    console.log("Attacker balance:", dvToken.balanceOf(address(attacker)));
    skip(WAITING_PERIOD_2_DAYS);
    console.log("After 2 days", block.timestamp);
    attacker.attack2After2Days();


    console.log("Attacker balance:", dvToken.balanceOf(address(attacker)));

    assertEq(dvToken.balanceOf(address(attacker)), POOL_INITIAL_BALANCE);
    assertEq(dvToken.balanceOf(address(fPool)), 0);

}

}