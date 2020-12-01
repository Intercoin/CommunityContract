pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../CommunityContract.sol";

contract CommunityContractMock is CommunityContract {
   
   function getRewardAmount() public view returns(uint256) {
       // uint256 public constant REWARD_AMOUNT = 100000000000000; // 0.001 * 1e18
       return REWARD_AMOUNT;
   }
   function getReplenishAmount() public view returns(uint256) {
       // uint256 public constant REPLENISH_AMOUNT = 100000000000000; // 0.001 * 1e18
       return REPLENISH_AMOUNT;
   }

    
}


