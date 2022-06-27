// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICommunityTransfer.sol";
import "./interfaces/ICommunity.sol";

import "./Community.sol";
import "./CommunityState.sol";
import "./CommunityView.sol";

contract CommunityFactory {
    using Clones for address;

    /**
    * @custom:shortd Community implementation address
    * @notice Community implementation address
    */
    Community public immutable implementation;

    CommunityView public immutable implementationView;
    CommunityState public immutable implementationState;

    address[] public instances;
    
    event InstanceCreated(address instance, uint instancesCount);

    /**
    * @param communityImpl address of Community implementation
    */
    constructor(
        address communityImpl
    ) 
    {
        implementation = new Community();
                
        implementationState = new CommunityState();
        implementationView = new CommunityView();
        
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
    * @param hook address of contract implemented ICommunityHook interface. Can be address(0)
    * @param name erc721 name
    * @param symbol erc721 symbol
    * @return instance address of created instance `CommunityERC721`
    * @custom:shortd creation CommunityERC721 instance
    */
    function produce(
        address hook,
        string memory name,
        string memory symbol
    ) 
        public 
        returns (address instance) 
    {
        
        instance = address(implementation).clone();

        _produce(instance);

        ICommunity(instance).initialize(address(implementationState), address(implementationView), hook, name, symbol);
        
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

        ICommunityTransfer(instance).addMembers(s);
        ICommunityTransfer(instance).grantRoles(s, r);

    }
}