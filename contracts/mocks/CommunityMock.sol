// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "../Community.sol";

contract CommunityMock is Community {
   
   function getRewardAmount() public pure returns(uint256) {
       // uint256 public constant REWARD_AMOUNT = 100000000000000; // 0.001 * 1e18
       return REWARD_AMOUNT;
   }
   function getReplenishAmount() public pure returns(uint256) {
       // uint256 public constant REPLENISH_AMOUNT = 100000000000000; // 0.001 * 1e18
       return REPLENISH_AMOUNT;
   }

    
}


