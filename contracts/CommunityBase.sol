// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./IntercoinTrait.sol";

import "./lib/PackedSet.sol";
import "./access/TrustedForwarder.sol";

import "./interfaces/ICommunityHook.sol";

//import "hardhat/console.sol";

contract CommunityBase is Initializable/*, OwnableUpgradeable*/, ReentrancyGuardUpgradeable, IntercoinTrait, TrustedForwarder {
    
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using AddressUpgradeable for address;

    struct inviteSignature {
        bytes sSig;
        bytes rSig;
        uint256 gasCost;
        ReimburseStatus reimbursed;
        bool used;
        bool exists;
    }
    
    uint8 internal rolesCount;
    mapping (bytes32 => uint8) internal _roles;
    //mapping (uint256 => bytes32) internal _rolesByIndex;
    mapping (address => PackedSet.Set) internal _rolesByMember;
    //mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) internal _members;
    //mapping (uint256 => EnumerableSetUpgradeable.UintSet) internal _canManageRoles;

    address public hook;

    struct Role {
        bytes32 name;
        string roleURI;
        mapping(address => string) extraURI;
        EnumerableSetUpgradeable.UintSet canManageRoles;
        EnumerableSetUpgradeable.AddressSet members;
    }
    mapping (uint8 => Role) internal _rolesByIndex;



    mapping (bytes => inviteSignature) inviteSignatures;          

    /**
    * @custom:shortd role name "owners" in bytes32
    * @notice constant role name "owners" in bytes32
    */
    bytes32 public constant DEFAULT_OWNERS_ROLE = 0x6f776e6572730000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "admins" in bytes32
    * @notice constant role name "admins" in bytes32
    */
    bytes32 public constant DEFAULT_ADMINS_ROLE = 0x61646d696e730000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "members" in bytes32
    * @notice constant role name "members" in bytes32
    */
    bytes32 public constant DEFAULT_MEMBERS_ROLE = 0x6d656d6265727300000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "relayers" in bytes32
    * @notice constant role name "relayers" in bytes32
    */
    bytes32 public constant DEFAULT_RELAYERS_ROLE = 0x72656c6179657273000000000000000000000000000000000000000000000000;

    enum ReimburseStatus{ NONE, PENDING, CLAIMED }
    /**
    * @notice constant reward that user-relayers will obtain
    * @custom:shortd reward that user-relayers will obtain
    */
    uint256 public constant REWARD_AMOUNT = 1000000000000000; // 0.001 * 1e18
    /**
    * @notice constant reward amount that user-recepient will replenish
    * @custom:shortd reward amount that user-recepient will replenish
    */
    uint256 public constant REPLENISH_AMOUNT = 1000000000000000; // 0.001 * 1e18
   
    //receiver => sender
    mapping(address => address) public invitedBy;
    //sender => receivers
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal invited;
    
    // Please make grantedBy(uint160 recipient => struct ActionInfo) mapping, and save it when user grants role. (Difference with invitedBy is that invitedBy the user has to ACCEPT the invite while grantedBy doesn’t require recipient to accept).
    // And also make revokedBy same way.
    // Please refactor invited and invitedBy and to return struct ActionInfo also. Here is struct ActionInfo, it fits in ONE slot:
    struct ActionInfo {
        address actor;
        uint64 timestamp;
        uint32 extra; // used for any other info, eg up to four role ids can be stored here !!!
    }
    
    /**
    * @notice map users granted by
    * @custom:shortd map users granted by
    */
    mapping(address => ActionInfo[]) public grantedBy;
    /**
    * @notice map users revoked by
    * @custom:shortd map users revoked by
    */
    mapping(address => ActionInfo[]) public revokedBy;
    /**
    * @notice history of users granted
    * @custom:shortd history of users granted
    */
    mapping(address => ActionInfo[]) public granted;
    /**
    * @notice history of users revoked
    * @custom:shortd history of users revoked
    */
    mapping(address => ActionInfo[]) public revoked;

    event RoleCreated(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleManaged(bytes32 indexed sourceRole, bytes32 indexed targetRole, address indexed sender);
    event RoleAddedErrorMessage(address indexed sender, string msg);
    
    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////

    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRole role name
     */
    modifier ifTargetInRole(address target, bytes32 targetRole) {
        
        require(
            _isTargetInRole(target, targetRole),
            string(abi.encodePacked("Target account must be with role '",targetRole.bytes32ToString(),"'"))
        );
        _;
    }
    
    /**
     * @notice is role can be managed by sender's roles?
     * @dev can addMembers/removeMembers/addMemberRole/removeMemberRole
     * @param sender sender
     * @param targetRole role that check to be managed by sender's roles
     */
    modifier canManage(address sender, bytes32 targetRole) {
     
        bool isCan = _isCanManage(sender, targetRole);
      
        require(
            isCan == true,
            string(abi.encodePacked("Sender can not manage Members with role '",targetRole.bytes32ToString(),"'"))
        );
        
        _;
    }
    
    /**
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier accummulateGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();
        uint usedGas = remainingGasStart - remainingGasEnd;
        // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        // usedGas += 21000 + 9700;
        usedGas += 30000;
        // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        uint gasCost = usedGas * tx.gasprice;
        // accummulate refund gas cost
        inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
    }

    /**
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier refundGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;
        
        uint gasCost;
        
        if (inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE) {
            uint remainingGasEnd = gasleft();
            uint usedGas = remainingGasStart - remainingGasEnd;

            // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            usedGas += 21000 + 9700 + 47500;

            // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
            gasCost = usedGas * tx.gasprice;

            inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
        }
        // Refund gas cost
        gasCost = inviteSignatures[sSig].gasCost;

        if (
            (gasCost <= address(this).balance) && 
            (
            inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE ||
            inviteSignatures[sSig].reimbursed == ReimburseStatus.PENDING
            )
        ) {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.CLAIMED;
            //payable (inviteSignatures[sSig].caller).transfer(gasCost);
           
            payable(_msgSender()).transfer(gasCost);

        } else {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.PENDING;
        }
        
        
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
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE)
        nonReentrant()
    {
        payable(_msgSender()).transfer(address(this).balance);
    } 
    /**
     * @notice Added participants to role members
     * @custom:shortd Added participants to role members
     * @custom:calledby owners
     * @param members participant's addresses
     */
    function addMembers(
        address[] memory members
    )
        //canManage(_msgSender(), DEFAULT_MEMBERS_ROLE)
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE)
        public 
    {
        
        uint256 len = members.length;
        uint256 i;
        for (i = 0; i < len; i++) {
            _grantRole(members[i], DEFAULT_MEMBERS_ROLE);
        }
    }
    
    /**
     * @notice Removed participants from  role members
     * @custom:shortd Removed participants from  role members
     * @custom:calledby owners
     * @param members participant's addresses
     */
    function removeMembers(
        address[] memory members
    )
        //canManage(_msgSender(), DEFAULT_MEMBERS_ROLE)
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE)
        public 
    {
        uint256 len = members.length;
        uint256 i;
        for (i = 0; i < len; i++) {
            _revokeRole(members[i], DEFAULT_MEMBERS_ROLE);
            //TODO 0: does need to remove from all exists roles?
        }
    }
    
    /**
     * @notice Added new Roles for members
     * @custom:shortd Added new Roles for members
     * @param members participant's addresses
     * @param roles Roles name
     */
    function grantRoles(
        address[] memory members, 
        string[] memory roles
    )
        public 
    {
        uint256 lengthMembers = members.length;
        uint256 lenRoles = roles.length;
        uint256 i;
        uint256 j;
        
        for (i = 0; i < lengthMembers; i++) {
            if (!_isTargetInRole(members[i], DEFAULT_MEMBERS_ROLE)) {
                revert(string(abi.encodePacked("Target account must be with role '",DEFAULT_MEMBERS_ROLE.bytes32ToString(),"'")));
                //_grantRole(members[i], DEFAULT_MEMBERS_ROLE);
                
            }
            for (j = 0; j < lenRoles; j++) {
                if (!_isCanManage(_msgSender(), roles[j].stringToBytes32())) {
                    revert(string(abi.encodePacked("Sender can not manage Members with role '",roles[j],"'")));
                }
                _grantRole(members[i], roles[j].stringToBytes32());
            }
        }
    }
    
    /**
     * @notice Removed Role for member
     * @custom:shortd Removed Role for member
     * @param members participant's addresses
     * @param roles Roles name
     */
    function revokeRoles(
        address[] memory members, 
        string[] memory roles
    ) 
        public 
    {

        uint256 lengthMembers = members.length;
        uint256 lenRoles = roles.length;
        uint256 i;
        uint256 j;
        bytes32 roleBytes32;

        for (i = 0; i < lengthMembers; i++) {
            if (!_isTargetInRole(members[i], DEFAULT_MEMBERS_ROLE)) {
                revert(string(abi.encodePacked("Target account must be with role '",DEFAULT_MEMBERS_ROLE.bytes32ToString(),"'")));
            }
            for (j = 0; j < lenRoles; j++) {

                roleBytes32 = roles[j].stringToBytes32();
                if (roleBytes32 == DEFAULT_MEMBERS_ROLE) {
                    revert(string(abi.encodePacked("Can not remove role '",roles[j],"'")));
                }

                if (!_isCanManage(_msgSender(), roleBytes32)) {
                    revert(string(abi.encodePacked("Sender can not manage Members with role '",roles[j],"'")));
                }
                _revokeRole(members[i], roles[j].stringToBytes32());

                
            }
        }
    }
    
    /**
     * @notice creating new role. can called owners role only
     * @custom:shortd creating new role. can called owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE) 
    {

        require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        
        // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        
        require(rolesCount < type(uint8).max -1, "Max amount of roles exceeded");

        _createRole(role.stringToBytes32());
        
       // new role must manage DEFAULT_MEMBERS_ROLE to be able to add members
       _manageRole(role.stringToBytes32(), DEFAULT_MEMBERS_ROLE);
       
       _manageRole(DEFAULT_OWNERS_ROLE, role.stringToBytes32());
       _manageRole(DEFAULT_ADMINS_ROLE, role.stringToBytes32());
    }
    
    /**
     * @notice allow account with sourceRole setup targetRole to another account with default role(members)
     * @custom:shortd allow managing another role
     * @param sourceRole role which will manage targetRole
     * @param targetRole role will have been managed by sourceRole
     */
    function manageRole(
        string memory sourceRole, 
        string memory targetRole
    ) 
        public 
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE) 
    {
        
        if (targetRole.stringToBytes32() == DEFAULT_OWNERS_ROLE) {
            revert(string(abi.encodePacked("targetRole can not be '",targetRole, "'")));
        }
        
        _manageRole(sourceRole.stringToBytes32(), targetRole.stringToBytes32());
    }

    /**
     * @notice Returns all members belong to Role
     * @custom:shortd all members belong to Role
     * @param role role name
     * @return array of address 
     */
    function getMembers(
        string memory role
    ) 
        public 
        view
        returns(address[] memory)
    {
        bytes32 roleBytes32= role.stringToBytes32();
        uint8 roleIndex = _roles[roleBytes32];
        uint256 len = _rolesByIndex[roleIndex].members.length();
        address[] memory l = new address[](len);
        uint256 i;
            
        for (i = 0; i < len; i++) {
            l[i] = _rolesByIndex[roleIndex].members.at(i);
        }
        return l;
    }
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all members belong to Role
     * @custom:shortd all members belong to Role
     * @param roles array of roles name
     * @return l array of address 
     */
    function getMembers(
        string[] memory roles
    ) 
        public 
        view
        returns(address[] memory l)
    {
        if (roles.length == 0) {
            l = new address[](0);
        } else {
            
            bytes32 roleBytes32;
            uint8 roleIndex;
            uint256 len;
            uint256 tmplen;

            for (uint256 j = 0; j < roles.length; j++) {
                roleBytes32 = roles[j].stringToBytes32();
                roleIndex = _roles[roleBytes32];

                tmplen = _rolesByIndex[roleIndex].members.length();
                len += tmplen;
            }

            l = new address[](len);
            
            uint256 ilen;
            for (uint256 j = 0; j < roles.length; j++) {
                uint256 i;

                roleBytes32 = roles[j].stringToBytes32();
                roleIndex = _roles[roleBytes32];

                tmplen = _rolesByIndex[roleIndex].members.length();

                for (i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[roleIndex].members.at(i);
                    ilen += 1;
                }
            }

        }

        return l;
       
    }
    
    /**
     * @notice if call without params then returns all members belong to `DEFAULT_MEMBERS_ROLE`
     * @custom:shortd `DEFAULT_MEMBERS_ROLE` members
     * @return array of address 
     */
    function getMembers(
    ) 
        public 
        view
        returns(address[] memory)
    {
        return getMembers(DEFAULT_MEMBERS_ROLE.bytes32ToString());
    }
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param members member's addresses
     * @return l array of roles 
     */
    function getRoles(
        address[] memory members
    ) 
        public 
        view
        returns(string[] memory l)
    {

        uint256 len;
        uint256 tmplen;

            for (uint256 j = 0; j < members.length; j++) {
                tmplen = _rolesByMember[members[j]].length();
                len += tmplen;
            }

            l = new string[](len);
            
            uint256 ilen;
            for (uint256 j = 0; j < members.length; j++) {
                uint256 i;

                tmplen = _rolesByMember[members[j]].length();

                for (i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[uint8(_rolesByMember[members[j]].get(i))].name.bytes32ToString();
                    ilen += 1;
                }
            }

        return l;
    }
    
    /**
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param member member's address
     * @return array of roles 
     */
    function getRoles(
        address member
    ) 
        public 
        view
        returns(string[] memory)
    {
        uint256 len = _rolesByMember[member].length();
        string[] memory l = new string[](len);
        uint256 i;
            
        for (i = 0; i < len; i++) {
            l[i] = _rolesByIndex[uint8(_rolesByMember[member].get(i))].name.bytes32ToString();
        }
        return l;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles 
     * @custom:shortd all roles
     * @return array of roles 
     */
    function getRoles(
    ) 
        public 
        view
        returns(string[] memory, string[] memory)
    {

        string[] memory names = new string[](rolesCount-1);
        string[] memory roleURIs = new string[](rolesCount-1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            names[i-1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i-1] = _rolesByIndex[i].roleURI;
        }
        return (names, roleURIs);
    }
    
    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param role role name
     * @return count of members for that role
     */
    function memberCount(
        string memory role
    )
        public
        view
        returns(uint256)
    {
        return _rolesByIndex[_roles[role.stringToBytes32()]].members.length();
    }
        
    /**
     * @notice if call without params then returns count of all members with default role
     * @custom:shortd all members count
     * @return count of members
     */
    function memberCount(
    )
        public
        view
        returns(uint256)
    {
        return memberCount(DEFAULT_MEMBERS_ROLE.bytes32ToString());
    }
    
    /**
     * @notice viewing invite by admin signature
     * @custom:shortd viewing invite by admin signature
     * @param sSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory sSig
    ) 
        public 
        view
        returns(inviteSignature memory)
    {
        return inviteSignatures[sSig];
    }
    
    /**
     * @notice registering invite,. calling by relayers
     * @custom:shortd registering invite 
     * @param sSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        public 
        ifTargetInRole(_msgSender(), DEFAULT_RELAYERS_ROLE) 
        accummulateGasCost(sSig)
    {
        require(inviteSignatures[sSig].exists == false, "Such signature is already exists");
        inviteSignatures[sSig].sSig= sSig;
        inviteSignatures[sSig].rSig = rSig;
        inviteSignatures[sSig].reimbursed = ReimburseStatus.NONE;
        inviteSignatures[sSig].used = false;
        inviteSignatures[sSig].exists = true;
    }
    
    /**
     * @dev
     * @dev ==P==  
     * @dev format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  
     * @dev ==R==  
     * @dev format is "<address of R wallet>:<name of user>"  
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  
     * @notice accepting invite
     * @custom:shortd accepting invite
     * @param p invite message of admin whom generate messageHash and signed it
     * @param sSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function inviteAccept(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    )
        public 
        ifTargetInRole(_msgSender(), DEFAULT_RELAYERS_ROLE) 
        refundGasCost(sSig)
        nonReentrant()
    {
        require(inviteSignatures[sSig].used == false, "Such signature is already used");

        (address pAddr, address rpAddr) = _recoverAddresses(p, sSig, rp, rSig);
       
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");
        
        if (
            pAddr == address(0) || 
            rpAddr == address(0) || 
            keccak256(abi.encode(inviteSignatures[sSig].rSig)) != keccak256(abi.encode(rSig)) ||
            rpDataArr[0].parseAddr() != rpAddr || 
            dataArr[1].parseAddr() != address(this)
        ) {
            revert("Signature are mismatch");
        }
        
        bool isCanProceed = false;
        
        if (_isCanManage(pAddr, DEFAULT_MEMBERS_ROLE)) {

            if (!_isTargetInRole(rpAddr, DEFAULT_MEMBERS_ROLE)) {
                _grantRole(rpAddr, DEFAULT_MEMBERS_ROLE);
                invitedBy[rpAddr] = pAddr;
            }

            
            for (uint256 i = 0; i < rolesArr.length; i++) {
                if (_isCanManage(pAddr, rolesArr[i].stringToBytes32())) {
                    isCanProceed = true;
                    _grantRole(rpAddr, rolesArr[i].stringToBytes32());
                } else {
                    emit RoleAddedErrorMessage(_msgSender(), string(abi.encodePacked("inviting user did not have permission to add role '",rolesArr[i],"'")));
                }
            }
        
        } else {
            emit RoleAddedErrorMessage(_msgSender(), string(abi.encodePacked("inviting user did not have permission to add role '",DEFAULT_MEMBERS_ROLE.bytes32ToString(),"'")));
        }
        
        if (isCanProceed == true) {
            inviteSignatures[sSig].used = true;
            
            invited[pAddr].add(rpAddr);
            
            _rewardCaller();
            _replenishRecipient(rpAddr);
            
        } else {
            revert("Can not add no one role");
        }
        
    }

    /**
     * @notice is member has role
     * @custom:shortd checking is member belong to role
     * @param account user address
     * @param rolename role name
     * @return bool 
     */
    function isMemberHasRole(
        address account, 
        string memory rolename
    ) 
        public 
        view 
        returns(bool) 
    {

        //require(_roles[rolename.stringToBytes32()] != 0, "Such role does not exists");

        return _rolesByMember[account].contains(_roles[rolename.stringToBytes32()]);

    }
  
    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
   
    fallback() external payable {}
    receive() external payable {}
    
    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////
    
    function setTrustedForwarder(
        address forwarder
    ) 
        ifTargetInRole(_msgSender(), DEFAULT_OWNERS_ROLE) 
        public 
        override 
    {
         require(
            !_isTargetInRole(forwarder, DEFAULT_OWNERS_ROLE),
            "FORWARDER_CAN_NOT_BE_OWNER"
        );
        _setTrustedForwarder(forwarder);
    }
 
   
    /**
     * @param role role name
     */
    function _createRole(bytes32 role) internal {
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
     * Set availability for members with `sourceRole` addMember/removeMember/addMemberRole/removeMemberRole
     * @param sourceRole source role name
     * @param targetRole target role name
     */
    function _manageRole(bytes32 sourceRole, bytes32 targetRole) internal {
        require(_roles[sourceRole] != 0, "Source role does not exists");
        require(_roles[targetRole] != 0, "Source role does not exists");
       
        _rolesByIndex[_roles[sourceRole]].canManageRoles.add(_roles[targetRole]);
       
        emit RoleManaged(sourceRole, targetRole, _msgSender());
    }
    
    /**
     * adding role to member
     * @param account account's address
     * @param targetRole role name
     */
    function _grantRole(address account, bytes32 targetRole) internal {
       _rolesByMember[account].add(_roles[targetRole]);
       _rolesByIndex[_roles[targetRole]].members.add(account);
       
        grantedBy[account].push(ActionInfo({
            actor: _msgSender(),
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
        }));
        granted[_msgSender()].push(ActionInfo({
            actor: account,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
        }));
       
        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleGranted(targetRole, _roles[targetRole], account);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleGranted(targetRole, account, _msgSender());
    }
    
    /**
     * removing role from member
     * @param account account's address
     * @param targetRole role name
     */
    function _revokeRole(address account, bytes32 targetRole) internal {
        _rolesByMember[account].remove(_roles[targetRole]);
        _rolesByIndex[_roles[targetRole]].members.remove(account);
       
        revokedBy[account].push(ActionInfo({
            actor: _msgSender(),
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
        }));
        revoked[_msgSender()].push(ActionInfo({
            actor: account,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
        }));

        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleRevoked(targetRole, _roles[targetRole], account);
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleRevoked(targetRole, account, _msgSender());
    }
    
    function _isTargetInRole(address target, bytes32 targetRole) internal view returns(bool) {
        return _rolesByMember[target].contains(_roles[targetRole]);
    }
    
    function _isCanManage(address sender, bytes32 targetRole) internal view returns (bool) {
     
        bool isCan = false;
        
        uint256 targetRoleID = _roles[targetRole];
        
        require(
            targetRoleID != 0,
            string(abi.encodePacked("Such role '",targetRole.bytes32ToString(),"' does not exists"))
        );
        
        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
            .canManageRoles.contains(targetRoleID) == true) {
                isCan = true;
                break;
            }
        }
        return isCan;
    }

    function __CommunityBase_init(address hook_) internal onlyInitializing {
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        
        rolesCount = 1;
        
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_RELAYERS_ROLE);
        _grantRole(_msgSender(), DEFAULT_OWNERS_ROLE);
        _grantRole(_msgSender(), DEFAULT_ADMINS_ROLE);
        _grantRole(_msgSender(), DEFAULT_RELAYERS_ROLE);
        // initial rules. owners can manage owners, admins, members, relayers
        // while admins can manage members, relayers
        // any other rules can be added later by owners
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_OWNERS_ROLE);                       
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_ADMINS_ROLE);
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_RELAYERS_ROLE);
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_MEMBERS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_MEMBERS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_RELAYERS_ROLE);

        // avoiding hook's trigger for built-in roles(owners/admins/members/relayers)
        // so define hook address in the end
        hook = hook_;
    }

    ///////////////////////////////////////////////////////////
    /// private section
    ///////////////////////////////////////////////////////////
    /**
     * @param p invite message of admin whom generate messageHash and signed it
     * @param sSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function _recoverAddresses(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    ) 
        private 
        pure
        returns(address, address)
    {
        bytes32 pHash = p.recreateMessageHash();
        bytes32 rpHash = rp.recreateMessageHash();
        address pAddr = pHash.recover(sSig);
        address rpAddr = rpHash.recover(rSig);
        return (pAddr, rpAddr);
    }
    
    /**
     * reward caller(relayers)
     */
    function _rewardCaller(
    ) 
        private 
    {
        if (REWARD_AMOUNT <= address(this).balance) {
            payable(_msgSender()).transfer(REWARD_AMOUNT);
        }
    }
    
    /**
     * replenish recipient which added via invite
     * @param rpAddr recipient's address 
     */
    function _replenishRecipient(
        address rpAddr
    ) 
        private 
    {
        if (REPLENISH_AMOUNT <= address(this).balance) {
            payable(rpAddr).transfer(REPLENISH_AMOUNT);
        }
    }
   
}
