/*
There’s a pool with 1000 ETH in balance, offering flash loans. 
It has a fixed fee of 1 ETH.

A user has deployed a contract with 10 ETH in balance. 
It’s capable of interacting with the pool 
and receiving flash loans of ETH.

Take all ETH out of the user’s contract. 
If possible, in a single transaction.

 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "./FlashLoanReceiver.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard, IERC3156FlashLender {

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error RepayFailed();
    error UnsupportedCurrency();
    error CallbackFailed();

    function maxFlashLoan(address token) external view returns (uint256) {
        if (token == ETH) {
            return address(this).balance;  // ETH balance of this pool address
        }
        return 0;
    }

    function flashFee(address token, uint256) external pure returns (uint256) {
        if (token != ETH)
            revert UnsupportedCurrency();
        return FIXED_FEE;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (token != ETH)
            revert UnsupportedCurrency();
        
        uint256 balanceBefore = address(this).balance;

        // Transfer ETH and handle control to receiver
        SafeTransferLib.safeTransferETH(address(receiver), amount);
        if(receiver.onFlashLoan(
            msg.sender,
            ETH,
            amount,
            FIXED_FEE,
            data
        ) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        if (address(this).balance < balanceBefore + FIXED_FEE)
            revert RepayFailed();

        return true;
    }

    // Allow deposits of ETH
    receive() external payable {}
}
