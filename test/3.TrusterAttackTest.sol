// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {TrusterLenderPool} from "../src/3. truster/TrusterLenderPool.sol";
import {Attack} from "../src/3. truster/Attack.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";


contract TrusterAttackTest is StdCheats, Test {

    DamnValuableToken public token;
    TrusterLenderPool public pool;
    Attack public attacker;
    

    address public user = address(1);
    uint256 public constant STARTING_POOL_BALANCE = 1000000 ether;


    function setUp() external {
        
        token = new DamnValuableToken();
        pool = new TrusterLenderPool(token);

        token.transfer(address(pool), STARTING_POOL_BALANCE);       

        assertEq(token.balanceOf(user) ,  0);

        address _tokenAddr = address(pool.token());
        assertEq(_tokenAddr, address(token));
        assertEq(token.balanceOf(address(pool)), STARTING_POOL_BALANCE);
    }

    function testAttack() public {

        console.log("USER BALANCE (before attack) :", token.balanceOf(address(user)));
        assertEq(token.balanceOf(address(user)), 0);

        vm.startPrank(user);
        attacker = new Attack();
        attacker.attack(address(pool), address(token));
        vm.stopPrank();

        console.log("USER BALANCE (after attack) :", token.balanceOf(address(user)));
        assertEq(token.balanceOf(address(user)), STARTING_POOL_BALANCE);


    }
}