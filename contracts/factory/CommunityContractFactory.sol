pragma solidity >=0.6.0 <0.7.0;
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../CommunityContract.sol";

contract CommunityContractFactory is Ownable {
    CommunityContract[] public communityContractAddresses;

    event CommunityContractCreated(CommunityContract communityContract);
    
    function createCommunityContract () public {
        CommunityContract communityContract = new CommunityContract();
        
        communityContractAddresses.push(communityContract);
        emit CommunityContractCreated(communityContract);
        communityContract.transferOwnership(_msgSender());  
    }
    
}