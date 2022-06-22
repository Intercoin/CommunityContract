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
    uint8 internal constant NONE_ROLE_INDEX = 0;
    uint8 internal rolesCount;
    mapping (bytes32 => uint8) internal _roles;
    //mapping (uint256 => bytes32) internal _rolesByIndex;
    mapping (address => PackedSet.Set) internal _rolesByMember;
    //mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) internal _members;
    //mapping (uint256 => EnumerableSetUpgradeable.UintSet) internal _canManageRoles;
    uint256 addressesCounter;

    address public hook;
    struct GrantSettings {
        uint8 requireRole;   //=0, 
        uint256 maxAddresses;//=0, 
        uint64 duration;    //=0
        uint64 lastIntervalIndex;
        uint256 grantedAddressesCounter;
    }
    struct Role {
        bytes32 name;
        string roleURI;
        mapping(address => string) extraURI;
        //EnumerableSetUpgradeable.UintSet canManageRoles;
        EnumerableSetUpgradeable.UintSet canGrantRoles;
        EnumerableSetUpgradeable.UintSet canRevokeRoles;

        mapping(uint8 => GrantSettings) grantSettings;

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

    /**
    * @custom:shortd role name "alumni" in bytes32
    * @notice constant role name "alumni" in bytes32
    */
    bytes32 public constant DEFAULT_ALUMNI_ROLE = 0x616c756d6e690000000000000000000000000000000000000000000000000000;

    /**
    * @custom:shortd role name "visitors" in bytes32
    * @notice constant role name "visitors" in bytes32
    */
    bytes32 public constant DEFAULT_VISITORS_ROLE = 0x76697369746f7273000000000000000000000000000000000000000000000000;
    

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
    event RoleManaged(
        uint8 indexed sourceRole, 
        uint8 indexed targetRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration,
        address indexed sender
    );
    event RoleAddedErrorMessage(address indexed sender, string msg);
    
    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////

    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    modifier ifTargetInRole(address target, uint8 targetRoleIndex) {
        
        require(
            _isTargetInRole(target, targetRoleIndex),
            string(abi.encodePacked("Target account must be with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(),"'"))
        );
        _;
    }
    
    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    modifier canGrant(address sender, uint8 targetRoleIndex) {
     
        bool isCan = _isCanGrant(sender, targetRoleIndex);
      
        require(
            isCan == true,
            string(abi.encodePacked("Sender can not manage Members with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(), "'"))
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
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE])
        nonReentrant()
    {
        payable(_msgSender()).transfer(address(this).balance);
    } 
    
    /**
     * @notice Added new Roles for members
     * @custom:shortd Added new Roles for members
     * @param members participant's addresses
     * @param rolesIndexes Roles indexes
     */
    function grantRoles(
        address[] memory members, 
        uint8[] memory rolesIndexes
    )
        public 
    {
        uint256 lengthMembers = members.length;
        uint256 lenRoles = rolesIndexes.length;
        uint8[] rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;
        address sender = _msgSender();

        for (uint256 i = 0; i < lenRoles; i++) {
            require(
                _isRoleValid(rolesIndexes[i]), 
                "invalid role"
            ); 

            rolesIndexWhichWillGrant = __isCanGrant(sender, rolesIndexes[i]);
            require(
                rolesIndexWhichWillGrant.length != 0,
                string(abi.encodePacked("Sender can not manage Members with role '",_rolesByIndex[rolesIndexes[i]].name.bytes32ToString(),"'"))
            );

            roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, rolesIndexes[i]);

            for (uint256 j = 0; j < lengthMembers; j++) {
                _grantRole(roleIndexWhichWillGrant, sender, members[j], rolesIndexes[i]);
            }
        }

    }
        
    function validateGrantSettings(
        uint8[] memory rolesWhichCanGrant,
        uint8 targetRoleIndex
    ) internal view returns(uint8) {

        bool isCan = false;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses == 0)
            ) {
                isCan = true;
            } else {
                if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration == 0 ) {
                    if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter.maxAddresses) {
                        isCan = true;
                    }
                } else {
                    // if (lastIntervalIndex = 0) {

                    // } else {
                        // get current interval index
                        uint256 interval = block.timestamp/(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration)*(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration);
                        if (interval == _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].lastIntervalIndex) {
                            if (
                                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 
                                <= 
                                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter.maxAddresses
                            ) {
                                isCan = true;
                            }
                        } else {
                            isCan = true;
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].lastIntervalIndex = interval;
                            _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter = 0;
                            
                        }

                        


                    // }
                    
                    
                }
            }

            if (isCan) {
                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;
                return rolesWhichCanGrant[i];
            }

        }
        require(isCan, "Max amount addresses exceeded");

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
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]) 
    {

        require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        
        // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        
        require(rolesCount < type(uint8).max -1, "Max amount of roles exceeded");

        _createRole(role.stringToBytes32());
       
    }
    
    /**
     * @notice allow account with byRole:
     * (if canGrantRole ==true) grant ofRole to another account if account has requireRole
     *          it can be available `maxAddresses` during `duration` time
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     * (if canRevokeRole ==true) revoke ofRole from account.
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
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]) 
    {
        
        if (ofRole == _roles[DEFAULT_OWNERS_ROLE]) {
            revert(string(abi.encodePacked("targetRole can not be '", _roles[ofRole].bytes32ToString(), "'")));
        }
        
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

    /**
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param roleIndex role index
     * @return array of address 
     */
    function getAddresses(
        uint8 roleIndex
    ) 
        public 
        view
        returns(address[] memory)
    {
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
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param rolesIndexes array of roles indexes
     * @return array of address 
     */
    function getAddresses(
        string[] memory rolesIndexes
    ) 
        public 
        view
        returns(address[] memory)
    {
        address[] memory l;

        if (rolesIndexes.length == 0) {
            l = new address[](0);
        } else {
            uint256 len;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                len += _rolesByIndex[_roles[j]].members.length();
            }

            l = new address[](len);
            
            uint256 ilen;
            uint256 tmplen;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                tmplen = _rolesByIndex[_roles[j]].members.length();
                for (uint256 i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[_roles[j]].members.at(i);
                    ilen += 1;
                }
            }
        }
        return l;
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
        returns(uint8[] memory)
    {
        uint8[] memory l;

        uint256 len;
        uint256 tmplen;

            for (uint256 j = 0; j < members.length; j++) {
                tmplen = _rolesByMember[members[j]].length();
                len += tmplen;
            }

            l = new uint8[](len);
            
            uint256 ilen;
            for (uint256 j = 0; j < members.length; j++) {
                uint256 i;

                tmplen = _rolesByMember[members[j]].length();

                for (i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByMember[members[j]].get(i);
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
        returns(uint8[] memory)
    {
        uint256 len = _rolesByMember[member].length();
        uint8[] memory l = new uint8[](len);

        for (uint256 i = 0; i < len; i++) {
            l[i] = _rolesByMember[member].get(i);
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
        returns(uint8[] memory, string[] memory, string[] memory)
    {
        uint8[] memory indexes = new uint8[](rolesCount-1);
        string[] memory names = new string[](rolesCount-1);
        string[] memory roleURIs = new string[](rolesCount-1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i-1] = i-1;
            names[i-1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i-1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);
    }
    
    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param roleIndex role index
     * @return count of members for that role
     */
    function addressesCount(
        uint8 roleIndex
    )
        public
        view
        returns(uint256)
    {
        return _rolesByIndex[roleIndex].members.length();
    }
        
    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all members count
     * @return count of members
     */
    function addressesCount(
    )
        public
        view
        returns(uint256)
    {
        return addressesCounter;
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
    //function isMemberHasRole(
    function isAccountHasRole(
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
     * @param byRole source role index
     * @param ofRole target role index
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
    
        require(rolesCount > byRole, "byRole invalid");
        require(rolesCount > ofRole, "ofRole invalid");
       
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

        _rolesByIndex[byRole].grantSettings.requireRole = requireRole;
        _rolesByIndex[byRole].grantSettings.maxAddresses = maxAddresses;
        _rolesByIndex[byRole].grantSettings.duration = duration;

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

    // struct GrantSettings {
    //     uint8 requireRole;   //=0, 
    //     uint256 maxAddresses;//=0, 
    //     uint64 duration;    //=0
    //     uint64 lastIntervalIndex;
    //     uint256 grantedAddressesCounter;
    // }
    // struct Role {
    //     bytes32 name;
    //     string roleURI;
    //     mapping(address => string) extraURI;
    //     EnumerableSetUpgradeable.UintSet canGrantRoles;
    //     EnumerableSetUpgradeable.UintSet canRevokeRoles;
    //     mapping(uint8 => GrantSettings) grantSettings;
    //     EnumerableSetUpgradeable.AddressSet members;
    // }
    // mapping (uint8 => Role) internal _rolesByIndex;


    
    /**
     * adding role to member
     * @param sourceRoleIndex sender role index
     * @param sourceAccount sender account's address
     * @param targetRoleIndex target role index
     * @param targetAccount target account's address
     */
    function _grantRole(uint8 sourceRoleIndex, address sourceAccount, uint8 targetRoleIndex, address targetAccount) internal {
       _rolesByMember[targetAccount].add(targetRoleIndex);
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
        emit RoleGranted(_rolesByIndex[targetRoleIndex].name, account, _msgSender());
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
    
    function _isTargetInRole(address target, uint8 targetRoleIndex) internal view returns(bool) {
        return _rolesByMember[target].contains(targetRoleIndex);
    }
    
    function _isCanGrant(address sender, uint8 targetRoleIndex) internal view returns (bool) {
        return __isCanGrant(sender, targetRoleIndex).length == 0 ? false : true;
    }

    function __isCanGrant(address sender, uint8 targetRoleIndex) internal view returns (uint8[] memory) {
        
        //uint256 targetRoleID = uint256(targetRoleIndex);
        
        require(
            targetRoleIndex != 0,
            string(abi.encodePacked("Such role '",_rolesByIndex[targetRoleIndex].name.bytes32ToString(),"' does not exists"))
        );
        uint256 iLen=0;

        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
            .canManageRoles.contains(targetRoleIndex) == true) {
                iLen++;
            }
        }

        uint8[] memory rolesWhichCan = new uint8[](iLen);

        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
            .canManageRoles.contains(targetRoleIndex) == true) {
                rolesWhichCan[rolesWhichCan.length] = _rolesByMember[sender].get(i);
            }
        }
        return rolesWhichCan;
    }

    // function _isCanManage(address sender, uint8 targetRoleIndex) internal view returns (bool) {
     
    //     bool isCan = false;
        
    //     uint256 targetRoleID = uint256(targetRoleIndex);
        
    //     require(
    //         targetRoleID != 0,
    //         string(abi.encodePacked("Such role '",_rolesByIndex[targetRoleIndex].name.bytes32ToString(),"' does not exists"))
    //     );
        
    //     for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
    //         if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
    //         .canManageRoles.contains(targetRoleID) == true) {
    //             isCan = true;
    //             break;
    //         }
    //     }
    //     return isCan;
    // }

    
    function _isRoleValid(uint8 index) internal view returns (bool){
        return (rolesCount > index) ? true : false;
    }

    function __CommunityBase_init(address hook_) internal onlyInitializing {
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        
        rolesCount = 1;
        
        _createRole(DEFAULT_RELAYERS_ROLE);
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);
        
        _grantRole(_msgSender(), DEFAULT_OWNERS_ROLE);
        
        // initial rules. owners can manage any roles. to save storage we will hardcode in any validate
        // admins can manage members, alumni and visitors
        // any other rules can be added later by owners
        
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_MEMBERS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_ALUMNI_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_VISITORS_ROLE);

        // avoiding hook's trigger for built-in roles
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
