// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStorage.sol";

//import "hardhat/console.sol";

contract CommunityState is CommunityStorage {
    
    using PackedSet for PackedSet.Set;

    using StringUtils for *;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
    /**
    * @param hook_ address of contract implemented ICommunityHook interface. Can be address(0)
    * @param authorizedInviteManager address of contract implemented invite mechanism
    * @param name_ erc721 name
    * @param symbol_ erc721 symbol
    */
    function initialize(
        address hook_,
        address invitedHook_,
        address authorizedInviteManager,
        string memory name_, 
        string memory symbol_, 
        string memory contractURI_
    ) 
        external 
    {
        name = name_;
        symbol = symbol_;

        __CommunityBase_init(hook_, invitedHook_);

        setContractURI(contractURI_);
        
        defaultAuthorizedInviteManager =  authorizedInviteManager;
    }

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    
    /**
    * @notice the way to withdraw remaining ETH from the contract. called by owners only 
    * @custom:shortd the way to withdraw ETH from the contract.
    * @custom:calledby owners
    */
    function withdrawRemainingBalance(
    ) 
        public 
        //nonReentrant()
    {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        payable(_msgSender()).transfer(address(this).balance);
    } 
    
    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function grantRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    )
        public 
    {
       _grantRoles(_msgSender(), accounts, roleIndexes);
    }
    
    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function revokeRoles(
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        public 
    {
        _revokeRoles(_msgSender(), accounts, roleIndexes);
    }

    function grantRolesExternal(
        address accountWhichWillGrant, 
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        public 
    {
        requireAuthorizedManager();
        _grantRoles(accountWhichWillGrant, accounts, roleIndexes);
    }

    function revokeRolesExternal(
        address accountWhichWillRevoke, 
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        public 
    {
        requireAuthorizedManager();
        _revokeRoles(accountWhichWillRevoke, accounts, roleIndexes);
    }
    
    /**
     * @notice creating new role. can be called by owners role only
     * @custom:shortd creating new role. can be called by owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        
    {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        // require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        // // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        // require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        require(
            (_roles[role.stringToBytes32()] == 0) &&
            (_roles[role._toLower().stringToBytes32()] == 0) 
            , 
            "Such role is already exists"
        );
        
        require(rolesCount < type(uint8).max -1, "Max amount of roles exceeded");

        _createRole(role.stringToBytes32());
       
    }
    
    /**
     * Set rules on how members with `sourceRole` can grant and revoke roles
     * @param byRole source role index
     * @param ofRole target role index
     * @param canGrantRole whether addresses with byRole can grant ofRole to other addresses
     * @param canRevokeRole whether addresses with byRole can revoke ofRole from other addresses
     * @param requireRole whether addresses with byRole can grant ofRole to other addresses
     * @param maxAddresses the maximum number of addresses that users with byRole can grant to ofRole in duration
     * @param duration duration
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     */
    function manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    )
        public 
    {
        
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(ofRole != _roles[DEFAULT_OWNERS_ROLE], string(abi.encodePacked("ofRole can not be '", _rolesByIndex[ofRole].name.bytes32ToString(), "'")));
        
        _manageRole(
            byRole, 
            ofRole, 
            canGrantRole, 
            canRevokeRole, 
            requireRole, 
            maxAddresses, 
            duration
        );
    }
  
    

    
    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        override 
    {

        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            !_isInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),
            "FORWARDER_CAN_NOT_BE_OWNER"
        );
        _setTrustedForwarder(forwarder);
    }
    
    /**
    * @notice setting tokenURI for role
    * @param roleIndex role index
    * @param roleURI token URI
    * @custom:shortd setting tokenURI for role
    * @custom:calledby owners only
    */
    function setRoleURI(
        uint8 roleIndex,
        string memory roleURI
    ) 
        public 
    {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _rolesByIndex[roleIndex].roleURI = roleURI;
    }

    /**
    * @notice setting contractURI for this contract
    * @param uri uri
    * @custom:shortd setting tokenURI for role
    * @custom:calledby owners only
    */
    function setContractURI(
        string memory uri
    ) 
        public 
    {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        contractURI = uri;
    }
    ///////////////////////////////////////////////////////////
    /// public  section that are view
    ///////////////////////////////////////////////////////////
    /**
    * @dev output rolesindexes array only for that account will grant. 
    * for example: 
    roles array is ['role1','role2','role3','role4','some none exist role']. 
    Output can be like this [0,0,55,0,0]
    Means that account can grant only 'role3'
    */
    function getRolesWhichAccountCanGrant(
        address account, 
        //uint8 roleIndex
        string[] memory roleNames
    ) 
        public 
        view 
        returns(uint8[] memory ret)
    {
        uint256 len = roleNames.length;
        ret = new uint8[](len);

        uint8 roleIndex;
        uint8[] memory rolesIndexesWhichWillGrant;
        uint8 roleIndexWhichCanGrant;
        for(uint256 i = 0; i < len; i++) {
            roleIndex = _roles[roleNames[i].stringToBytes32()];
            if (roleIndex != 0) {
                rolesIndexesWhichWillGrant = __rolesWhichCanGrant(account, roleIndex);
                if (rolesIndexesWhichWillGrant.length != 0) {
                    (roleIndexWhichCanGrant,,) = __getRoleWhichCanGrant(rolesIndexesWhichWillGrant, roleIndex);
                    if (roleIndexWhichCanGrant != NONE_ROLE_INDEX) {
                        ret[i] = roleIndex;
                    }
                }

            }
        }
        
    }

    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////

    

    function _grantRoles(
        address accountWhichWillGrant, 
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        internal
    {
 
        // uint256 lengthAccounts = accounts.length;
        // uint256 lenRoles = roleIndexes.length;
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;

        

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]); 

            rolesIndexWhichWillGrant = _rolesWhichCanGrant(accountWhichWillGrant, roleIndexes[i], FlagFork.NONE);

            require(
                rolesIndexWhichWillGrant.length != 0,
                string(abi.encodePacked("Sender can not grant role '",_rolesByIndex[roleIndexes[i]].name.bytes32ToString(),"'"))
            );
                    
            roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, roleIndexes[i], FlagFork.REVERT);

            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(roleIndexWhichWillGrant, accountWhichWillGrant, roleIndexes[i], accounts[j]);
            }
        }
    }

    function _revokeRoles(
        address accountWhichWillRevoke, 
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) 
        internal 
    {
        uint8 roleWhichWillRevoke;
        

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]); 

            roleWhichWillRevoke = NONE_ROLE_INDEX;
            if (_isInRole(accountWhichWillRevoke, _roles[DEFAULT_OWNERS_ROLE])) {
                // owner can do anything. so no need to calculate or loop
                roleWhichWillRevoke = _roles[DEFAULT_OWNERS_ROLE];
            } else {
                for (uint256 j = 0; j<_rolesByAddress[accountWhichWillRevoke].length(); j++) {
                    if (_rolesByIndex[uint8(_rolesByAddress[accountWhichWillRevoke].get(j))].canRevokeRoles.contains(roleIndexes[i]) == true) {
                        roleWhichWillRevoke = _rolesByAddress[accountWhichWillRevoke].get(j);
                        break;
                    }
                }
            }
            require(roleWhichWillRevoke != NONE_ROLE_INDEX, string(abi.encodePacked("Sender can not revoke role '",_rolesByIndex[roleIndexes[i]].name.bytes32ToString(),"'")));
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(/*roleWhichWillRevoke, */accountWhichWillRevoke, roleIndexes[i], accounts[k]);
            }

        }
    }
    
    ///////////////////////////////////
    // ownable implementation with diff semantic
    /**
    * @dev will grantRoles([address], OWNERS_ROLE) and then revokeRoles(msg.caller, OWNERS_ROLE). 
    * There is no need to have transferRole() function because normally no one can transfer their own roles unilaterally, except owners. 
    * Instead they manage roles under them.
    */
    // The function renounceOwnership() will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller. 
    // This function is irreversible. The contract will be ownerless. The trackers should see the appropriate events/logs as from any Ownable interface.
    function _transferOwnership(address newOwner) internal override {
        address sender = _msgSender();
        if (newOwner == address(0)) {
            // if newOwner == address(0) it's just renounceOwnership()    
            // we will simply revokeRoles(getAddresses(OWNERS_ROLE), OWNERS_ROLE) from everyone who has it, including the caller. 
            EnumerableSetUpgradeable.AddressSet storage ownersList = _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]].members;
            uint256 len = ownersList.length();
            // loop through stack, due to reducing members in role, we just get address from zero position `len` times
            for (uint256 i = 0; i < len; i++) {
                _revokeRole(sender, _roles[DEFAULT_OWNERS_ROLE], ownersList.at(0));
            }
            emit RenounceOwnership();
        } else {
            _grantRole(_roles[DEFAULT_OWNERS_ROLE], sender, _roles[DEFAULT_OWNERS_ROLE], newOwner);
            _revokeRole(sender, _roles[DEFAULT_OWNERS_ROLE], sender);
            emit OwnershipTransferred(sender, newOwner);
        }
    }

    ///////////////////////////////////
    /**
    * @dev find which role can grant `roleIndex` to account
    * @param rolesWhichCanGrant array of role indexes which want to grant `roleIndex` to account
    * @param roleIndex target role index
    * @param flag flag which indicated what is need to do when error happens. 
    *   if FlagFork.REVERT - when transaction will reverts, 
    *   if FlagFork.EMIT - emit event `RoleAddedErrorMessage` 
    *   otherwise - do nothing
    * @return uint8 role index which can grant `roleIndex` to account without error
    */
    function validateGrantSettings(
        uint8[] memory rolesWhichCanGrant,
        uint8 roleIndex,
        FlagFork flag
    ) 
        internal 
        returns(uint8) 
    {

        uint8 roleWhichCanGrant;
        bool increaseCounter;
        uint64 newInterval;

        (roleWhichCanGrant, increaseCounter, newInterval) = __getRoleWhichCanGrant(rolesWhichCanGrant, roleIndex);

        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(_msgSender(), "Max amount addresses exceeded");
            }
        } else {        
            if (increaseCounter) {
                _rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].grantedAddressesCounter += 1;
            }
            if (newInterval != 0) {
                _rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].lastIntervalIndex = newInterval;
                _rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].grantedAddressesCounter = 0;
            }
        }

        return roleWhichCanGrant;

    }

    function __getRoleWhichCanGrant(
        uint8[] memory rolesWhichCanGrant,
        uint8 roleIndex
    ) 
        internal 
        view 
        returns(uint8 roleWhichCanGrant, bool increaseCounter, uint64 newInterval) 
    {
        roleWhichCanGrant = NONE_ROLE_INDEX;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].maxAddresses == 0)
            ) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].duration == 0 ) {
                    if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].maxAddresses) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                    }
                } else {

                    // get current interval index
                    uint64 interval = uint64(block.timestamp)/(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].duration)*(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].duration);
                    if (interval == _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].lastIntervalIndex) {
                        if (
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].grantedAddressesCounter+1 
                            <= 
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].maxAddresses
                        ) {
                            roleWhichCanGrant = rolesWhichCanGrant[i];
                        }
                    } else {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                        //_rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].lastIntervalIndex = interval;
                        //_rolesByIndex[roleWhichCanGrant].grantSettings[roleIndex].grantedAddressesCounter = 0;
                        newInterval = interval;
                        

                    }
                    
                }
            }

            if (roleWhichCanGrant != NONE_ROLE_INDEX) {
                //_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[roleIndex].grantedAddressesCounter += 1;
                increaseCounter = true;
                break;
            }
        }

        return (roleWhichCanGrant, increaseCounter, newInterval);
    }
    
    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    function requireCanGrant(
        address sender, 
        uint8 targetRoleIndex
    ) 
        internal 
    {
        
        _rolesWhichCanGrant(sender, targetRoleIndex, FlagFork.REVERT);
      
    }
  
    /**
     * @param role role name
     */
    function _createRole(
        bytes32 role
    ) 
        internal 
    {
        _roles[role] = rolesCount;
        _rolesByIndex[rolesCount].name = role;
        rolesCount += 1;
       
        if (hook != address(0)) {            
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleCreated(role, rolesCount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleCreated(role, _msgSender());
    }
   
    /**
     * Set rules on how members with `sourceRole` can grant and revoke roles
     * @param byRole source role index
     * @param ofRole target role index
     * @param canGrantRole whether addresses with byRole can grant ofRole to other addresses
     * @param canRevokeRole whether addresses with byRole can revoke ofRole from other addresses
     * @param requireRole whether addresses with byRole can grant ofRole to other addresses
     * @param maxAddresses the maximum number of addresses that users with byRole can grant to ofRole in duration
     * @param duration duration
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     */
    function _manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    ) internal {
    
        _isRoleValid(byRole);
        _isRoleValid(ofRole);
        
        if (canGrantRole) {
            _rolesByIndex[byRole].canGrantRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canGrantRoles.remove(ofRole);
        }

        if (canRevokeRole) {
            _rolesByIndex[byRole].canRevokeRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canRevokeRoles.remove(ofRole);
        }

        _rolesByIndex[byRole].grantSettings[ofRole].requireRole = requireRole;
        _rolesByIndex[byRole].grantSettings[ofRole].maxAddresses = maxAddresses;
        _rolesByIndex[byRole].grantSettings[ofRole].duration = duration;

        emit RoleManaged(
            byRole, 
            ofRole, 
            canGrantRole, 
            canRevokeRole, 
            requireRole, 
            maxAddresses, 
            duration,
            _msgSender()
        );
    }
 
    /**
     * adding role to member
     * @param sourceRoleIndex sender role index
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _grantRole(
        uint8 sourceRoleIndex, 
        address sourceAccount, 
        uint8 targetRoleIndex, 
        address targetAccount
    ) 
        internal 
    {

        if (_rolesByAddress[targetAccount].length() == 0) {
            addressesCounter++;
        }

       _rolesByAddress[targetAccount].add(targetRoleIndex);
       _rolesByIndex[targetRoleIndex].members.add(targetAccount);
       
        grantedBy[targetAccount].push(ActionInfo({
            actor: sourceAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
        granted[sourceAccount].push(ActionInfo({
            actor: targetAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
 

        _rolesByIndex[sourceRoleIndex].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;

        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleGranted(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleGranted(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);
    }
    
    /**
     * removing role from member
     * param sourceRoleIndex sender role index *deprecated*
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _revokeRole(
        //uint8 sourceRoleIndex, 
        address sourceAccount, 
        uint8 targetRoleIndex, 
        address targetAccount
        //address account, bytes32 targetRole
    ) 
        internal 
    {
        
        _rolesByAddress[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);
       
        if (
            _rolesByAddress[targetAccount].length() == 0 &&
            addressesCounter != 0
        ) {
            addressesCounter--;
        }


        revokedBy[targetAccount].push(ActionInfo({
            actor: sourceAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));
        revoked[sourceAccount].push(ActionInfo({
            actor: targetAccount,
            timestamp: uint64(block.timestamp),
            extra: uint32(targetRoleIndex)
        }));

        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleRevoked(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleRevoked(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);
    }
 
    function _rolesWhichCanGrant(
        address sender, 
        uint8 targetRoleIndex, 
        FlagFork flag
    ) 
        internal 
        
        returns (uint8[] memory rolesWhichCan) 
    {
        rolesWhichCan = __rolesWhichCanGrant(sender, targetRoleIndex);

        if (rolesWhichCan.length == 0) {
            string memory errMsg = string(abi.encodePacked("Sender can not grant account with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(), "'"));
            if (flag == FlagFork.REVERT) {
                revert(errMsg);
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(sender, errMsg);
            }
        }

    }

    function __rolesWhichCanGrant(
        address sender, 
        uint8 targetRoleIndex
    ) 
        internal 
        view
        returns (uint8[] memory) 
    {

        //uint256 targetRoleID = uint256(targetRoleIndex);
       
        uint256 iLen;
        uint8[] memory rolesWhichCan;

        if (_isInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
            // owner can do anything. so no need to calculate or loop
            rolesWhichCan = new uint8[](1);
            rolesWhichCan[0] = _roles[DEFAULT_OWNERS_ROLE];
        } else {

            iLen = 0;
            for (uint256 i = 0; i<_rolesByAddress[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByAddress[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    iLen++;
                }
            }

            rolesWhichCan = new uint8[](iLen);

            iLen = 0;
            for (uint256 i = 0; i<_rolesByAddress[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByAddress[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    rolesWhichCan[iLen] = _rolesByAddress[sender].get(i);
                    iLen++;
                }
            }
        
        }

        return rolesWhichCan;
    }

    function __CommunityBase_init(address hook_, address invitedHook_) internal onlyInitializing {
        
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        
        rolesCount = 1;
        
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);
        
        //_grantRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _grantRole(_roles[DEFAULT_OWNERS_ROLE], _msgSender(), _roles[DEFAULT_OWNERS_ROLE], _msgSender());
        
        // initial rules. owners can manage any roles. to save storage we will hardcode in any validate
        // admins can manage members, alumni and visitors
        // any other rules can be added later by owners
        
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_MEMBERS_ROLE],  true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_ALUMNI_ROLE],   true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_VISITORS_ROLE], true, true, 0, 0, 0);

        // avoiding hook's trigger for built-in roles
        // so define hook address in the end
        hook = hook_;

        _invitedHook = invitedHook_;

    }

    ///////////////////////////////////////////////////////////
    /// internal section that are view
    ///////////////////////////////////////////////////////////
    
    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    function requireInRole(
        address target, 
        uint8 targetRoleIndex
    ) 
        internal 
        view 
    {
        
        require(
            _isInRole(target, targetRoleIndex),
            string(abi.encodePacked("Missing role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(),"'"))
        );

    }
    
    function _isRoleValid(
        uint8 index
    ) 
        internal 
        view 
    {
        require(
            (rolesCount > index), 
            "invalid role"
        ); 
    }

    function requireAuthorizedManager(
    ) 
        internal 
        view 
    {
        if (_msgSender() != defaultAuthorizedInviteManager) {
            revert AuthorizedInviteManagerOnly();
        }

    }

    ///////////////////////////////////////////////////////////
    /// private section
    ///////////////////////////////////////////////////////////
    
}
    
