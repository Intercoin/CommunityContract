// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/ICommunityERC721.sol";
interface Im {
    function addMembers(address[] memory members) external;
    function grantRoles(address[] memory members, string[] memory roles) external;
}
contract CommunityFactory {
    using Clones for address;

    /**
    * @custom:shortd Community implementation address
    * @notice Community implementation address
    */
    address public immutable communityImplementation;

    /**
    * @custom:shortd CommunityERC721 implementation address
    * @notice CommunityERC721 implementation address
    */
    address public immutable communityerc721Implementation;

    address[] public instances;
    
    event InstanceCreated(address instance, uint instancesCount);

    /**
    * @param communityImpl address of Community implementation
    * @param communityerc721Impl address of CommunityERC721 implementation
    */
    constructor(
        address communityImpl,
        address communityerc721Impl
    ) 
    {
        communityImplementation = communityImpl;
        communityerc721Implementation = communityerc721Impl;
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @dev view amount of created instances
    * @return amount amount instances
    * @custom:shortd view amount of created instances
    */
    function instancesCount()
        external 
        view 
        returns (uint256 amount) 
    {
        amount = instances.length;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @return instance address of created instance `Community`
    * @custom:shortd creation Community instance
    */
    function produce(
    ) 
        public 
        returns (address instance) 
    {
        
        instance = communityImplementation.clone();

        _produce(instance);

        ICommunity(instance).init();
        
        _postProduce(instance);
    }


    /**
    * @param name erc721 name
    * @param symbol erc721 symbol
    * @return instance address of created instance `CommunityERC721`
    * @custom:shortd creation CommunityERC721 instance
    */
    function produce(
        string memory name,
        string memory symbol
    ) 
        public 
        returns (address instance) 
    {
        
        instance = communityerc721Implementation.clone();

        _produce(instance);

        ICommunityERC721(instance).init(name, symbol);
        
        _postProduce(instance);
        
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function _produce(
        address instance
    ) 
        internal
    {
        require(instance != address(0), "CommunityCoinFactory: INSTANCE_CREATION_FAILED");

        instances.push(instance);
        
        emit InstanceCreated(instance, instances.length);
    }

     function _postProduce(
        address instance
    ) 
        internal
    {
        address[] memory s = new address[](1);
        s[0] = msg.sender;

        string[] memory r = new string[](3);
        r[0] = "owners";
        r[1] = "admins";
        r[2] = "relayers";

        Im(instance).addMembers(s);
        Im(instance).grantRoles(s, r);

    }
}