pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "../CommunityContract.sol";

contract CommunityContractFactory is OwnableUpgradeSafe {

    CommunityContract private implementationContract;
    event Produced(CommunityContract addr);
    
    constructor () public {
        implementationContract = new CommunityContract();
    }
    
    function init() public initializer {
        __Ownable_init();
    }
    
   function produce() public returns (CommunityContract){
        
        CommunityContract proxy = CommunityContract(
            payable(createClone(address(implementationContract)))
        );
        
        proxy.init();
        proxy.transferOwnership(msg.sender);
        emit Produced(proxy);
        return proxy;
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}
