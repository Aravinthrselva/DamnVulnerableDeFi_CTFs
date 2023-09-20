// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {SideEntranceLenderPool} from "../src/4. side-entrance/SideEntranceLenderPool.sol";
import {Attack} from "../src/4. side-entrance/Attack.sol";


contract SideEntranceAttackTest is StdCheats, Test {

    SideEntranceLenderPool public pool;
    Attack public attacker;

    uint256 public constant POOL_STARTING_BALANCE = 1000 ether;
    uint256 public constant ATTACKER_STARTING_BALANCE = 1 ether;

    function setUp() public {

        pool = new SideEntranceLenderPool();
        attacker = new Attack();

        pool.deposit{value : POOL_STARTING_BALANCE}();

        vm.deal(address(attacker), ATTACKER_STARTING_BALANCE);

        assertEq(address(pool).balance , POOL_STARTING_BALANCE);
        assertEq(address(attacker).balance , ATTACKER_STARTING_BALANCE);

    }

    function testAttack() public {

        attacker.pwn(address(pool));

        assertEq(address(pool).balance , 0);    
        assertEq(address(attacker).balance , POOL_STARTING_BALANCE + 1 ether);
    }

}