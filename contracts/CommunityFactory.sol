// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICommunityTransfer.sol";
import "./interfaces/ICommunity.sol";


contract CommunityFactory {
    using Clones for address;

    /**
    * @custom:shortd Community implementation address
    * @notice Community implementation address
    */
    address public immutable implementation;

    address public immutable implementationState;
    address public immutable implementationView;
    

    address[] public instances;
    
    event InstanceCreated(address instance, uint instancesCount);

    /**
    */
    constructor(
        address _implementation,
        address _implementationState,
        address _implementationView
    ) {
        implementation      = _implementation;
        implementationState = _implementationState;
        implementationView  = _implementationView;
        
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

        uint8[] memory r = new uint8[](1);
        r[0] = 2;//"owners";

        //ICommunityTransfer(instance).addMembers(s);
        ICommunityTransfer(instance).grantRoles(s, r);

    }
}