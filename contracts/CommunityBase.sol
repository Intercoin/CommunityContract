// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./IntercoinTrait.sol";

import "./lib/PackedSet.sol";
import "./access/TrustedForwarder.sol";

import "./interfaces/ICommunityHook.sol";

//import "hardhat/console.sol";

contract CommunityBase is Initializable, ReentrancyGuardUpgradeable, IntercoinTrait, TrustedForwarder {
    
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;


    ////////////////////////////////
    ///////// structs //////////////
    ////////////////////////////////

    struct inviteSignature {
        bytes sSig;
        bytes rSig;
        uint256 gasCost;
        ReimburseStatus reimbursed;
        bool used;
        bool exists;
    }

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

    // Please make grantedBy(uint160 recipient => struct ActionInfo) mapping, and save it when user grants role. (Difference with invitedBy is that invitedBy the user has to ACCEPT the invite while grantedBy doesn’t require recipient to accept).
    // And also make revokedBy same way.
    // Please refactor invited and invitedBy and to return struct ActionInfo also. Here is struct ActionInfo, it fits in ONE slot:
    struct ActionInfo {
        address actor;
        uint64 timestamp;
        uint32 extra; // used for any other info, eg up to four role ids can be stored here !!!
    }

    /////////////////////////////
    ///////// vars //////////////
    /////////////////////////////

    uint8 internal rolesCount;
    address public hook;
    uint256 addressesCounter;

    uint8 internal constant NONE_ROLE_INDEX = 0;
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

    enum ReimburseStatus{ NONE, PENDING, CLAIMED }

    // enum used in method when need to mark what need to do when error happens
    enum FlagFork{ NONE, EMIT, REVERT }
   
    ////////////////////////////////
    ///////// mapping //////////////
    ////////////////////////////////

    //receiver => sender
    mapping(address => address) public invitedBy;
    //sender => receivers
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal invited;
    
    mapping (bytes32 => uint8) internal _roles;
    mapping (address => PackedSet.Set) internal _rolesByMember;
    mapping (uint8 => Role) internal _rolesByIndex;
    mapping (bytes => inviteSignature) inviteSignatures;          
    
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

    ////////////////////////////////
    ///////// events ///////////////
    ////////////////////////////////
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
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier accummulateGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();
        // uint usedGas = remainingGasStart - remainingGasEnd;
        // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        // // usedGas += 21000 + 9700;
        // usedGas += 30700;
        // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        // uint gasCost = usedGas * tx.gasprice;
        // // accummulate refund gas cost
        // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
        inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;
        //----
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
            // uint usedGas = remainingGasStart - remainingGasEnd;
            // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            // usedGas += 21000 + 9700 + 47500;
            // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
            // gasCost = usedGas * tx.gasprice;

            // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
            inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + ((remainingGasStart - remainingGasEnd + 78200) * tx.gasprice);
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
        nonReentrant()
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        payable(_msgSender()).transfer(address(this).balance);
    } 

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param rolesIndexes Roles indexes
     */
    function grantRoles(
        address[] memory accounts, 
        uint8[] memory rolesIndexes
    )
        public 
    {
        // uint256 lengthAccounts = accounts.length;
        // uint256 lenRoles = rolesIndexes.length;
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;

        //address sender = _msgSender();


        for (uint256 i = 0; i < rolesIndexes.length; i++) {
            _isRoleValid(rolesIndexes[i]); 

            rolesIndexWhichWillGrant = _isCanGrant(_msgSender(), rolesIndexes[i], FlagFork.NONE);
            require(
                rolesIndexWhichWillGrant.length != 0,
                string(abi.encodePacked("Sender can not grant role '",_rolesByIndex[rolesIndexes[i]].name.bytes32ToString(),"'"))
            );

            roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, rolesIndexes[i], FlagFork.REVERT);

            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(roleIndexWhichWillGrant, _msgSender(), rolesIndexes[i], accounts[j]);
            }
        }

    }
    
    /**
    * @dev find which role can grant `targetRoleIndex` to account
    * @param rolesWhichCanGrant array of role indexes which want to grant `targetRoleIndex` to account
    * @param targetRoleIndex target role index
    * @param flag flag which indicated what is need to do when error happens. 
    *   if FlagFork.REVERT - when transaction will reverts, 
    *   if FlagFork.EMIT - emit event `RoleAddedErrorMessage` 
    *   otherwise - do nothing
    * @return uint8 role index which can grant `targetRoleIndex` to account without error
    */
    function validateGrantSettings(
        uint8[] memory rolesWhichCanGrant,
        uint8 targetRoleIndex,
        FlagFork flag

    ) 
        internal 
        returns(uint8) 
    {

        uint8 roleWhichCanGrant = NONE_ROLE_INDEX;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses == 0)
            ) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration == 0 ) {
                    if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                    }
                } else {
                    // if (lastIntervalIndex = 0) {

                    // } else {
                        // get current interval index
                        uint64 interval = uint64(block.timestamp)/(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration)*(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration);
                        if (interval == _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].lastIntervalIndex) {
                            if (
                                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 
                                <= 
                                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses
                            ) {
                                roleWhichCanGrant = rolesWhichCanGrant[i];
                            }
                        } else {
                            roleWhichCanGrant = rolesWhichCanGrant[i];
                            _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].lastIntervalIndex = interval;
                            _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].grantedAddressesCounter = 0;

                        }

                        


                    // }
                    
                    
                }
            }

            if (roleWhichCanGrant != NONE_ROLE_INDEX) {
                _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;
                break;
            }

        }

        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(_msgSender(), "Max amount addresses exceeded");
            }
        }

        return roleWhichCanGrant;

    }
    
    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param rolesIndexes Roles indexes
     */
    function revokeRoles(
        address[] memory accounts, 
        uint8[] memory rolesIndexes
    ) 
        public 
    {


        //uint256 lengthMembers = accounts.length;
        //uint256 lenRoles = rolesIndexes.length;
        uint8 roleWhichWillRevoke;
        //address sender = _msgSender();

        for (uint256 i = 0; i < rolesIndexes.length; i++) {
            _isRoleValid(rolesIndexes[i]); 

            roleWhichWillRevoke = NONE_ROLE_INDEX;
            for (uint256 j = 0; j<_rolesByMember[_msgSender()].length(); j++) {
                
                if (_rolesByIndex[uint8(_rolesByMember[_msgSender()].get(j))].canRevokeRoles.contains(rolesIndexes[i]) == true) {
                    roleWhichWillRevoke = _rolesByMember[_msgSender()].get(j);
                    
                    break;
                }

            
            }
            require(roleWhichWillRevoke != NONE_ROLE_INDEX, string(abi.encodePacked("Sender can not manage Members with role '",_rolesByIndex[rolesIndexes[i]].name.bytes32ToString(),"'")));
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(/*roleWhichWillRevoke, */_msgSender(), rolesIndexes[i], accounts[k]);
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
        
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

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
    {
        
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(ofRole != _roles[DEFAULT_OWNERS_ROLE], string(abi.encodePacked("targetRole can not be '", _rolesByIndex[ofRole].name.bytes32ToString(), "'")));
        
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
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param rolesIndexes array of roles indexes
     * @return array of address 
     */
    function getAddresses(
        uint8[] memory rolesIndexes
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
                len += _rolesByIndex[rolesIndexes[j]].members.length();
            }

            l = new address[](len);
            
            uint256 ilen;
            uint256 tmplen;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                tmplen = _rolesByIndex[rolesIndexes[j]].members.length();
                for (uint256 i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[rolesIndexes[j]].members.at(i);
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
        
        accummulateGasCost(sSig)
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);
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
        refundGasCost(sSig)
        nonReentrant()
    {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);

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
        
        for (uint256 i = 0; i < rolesArr.length; i++) {
            uint8 roleIndex = _roles[rolesArr[i].stringToBytes32()];
            if (roleIndex == 0) {
                emit RoleAddedErrorMessage(_msgSender(), "invalid role");
            }

            uint8[] memory rolesIndexWhichWillGrant = _isCanGrant(pAddr, roleIndex, FlagFork.EMIT);

            uint8 roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, roleIndex, FlagFork.EMIT);

            if (roleIndexWhichWillGrant == NONE_ROLE_INDEX) {
                emit RoleAddedErrorMessage(_msgSender(), string(abi.encodePacked("inviting user did not have permission to add role '",_rolesByIndex[roleIndex].name.bytes32ToString(),"'")));
            } else {
                isCanProceed = true;
                _grantRole(roleIndexWhichWillGrant, pAddr, roleIndex, rpAddr);
            }
        }

        if (isCanProceed == false) {
            revert("Can not add no one role");
        }

        inviteSignatures[sSig].used = true;
            
        invited[pAddr].add(rpAddr);
        
        _rewardCaller();
        _replenishRecipient(rpAddr);
            
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
    
    
    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    function ifTargetInRole(address target, uint8 targetRoleIndex) internal view {
        
        require(
            _isTargetInRole(target, targetRoleIndex),
            string(abi.encodePacked("Missing role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(),"'"))
        );

    }
    
    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    function ifCanGrant(address sender, uint8 targetRoleIndex) internal {
     
        _isCanGrant(sender, targetRoleIndex,FlagFork.REVERT);
      
    }
    

    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        override 
    {
      
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            !_isTargetInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),
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
        address sourceAccount, uint8 targetRoleIndex, address targetAccount
        //address account, bytes32 targetRole
    ) 
        internal 
    {
        _rolesByMember[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);
       
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
    
    function _isTargetInRole(address target, uint8 targetRoleIndex) internal view returns(bool) {
        return _rolesByMember[target].contains(targetRoleIndex);
    }
    

    function _isCanGrant(address sender, uint8 targetRoleIndex, FlagFork flag) internal returns (uint8[] memory) {
        
        //uint256 targetRoleID = uint256(targetRoleIndex);
       
        uint256 iLen=0;

        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
            .canGrantRoles.contains(targetRoleIndex) == true) {
                iLen++;
            }
        }

        uint8[] memory rolesWhichCan = new uint8[](iLen);

        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))]
            .canGrantRoles.contains(targetRoleIndex) == true) {
                rolesWhichCan[rolesWhichCan.length] = _rolesByMember[sender].get(i);
            }
        }

        if (rolesWhichCan.length == 0) {
            string memory errMsg = string(abi.encodePacked("Sender can not grant account with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(), "'"));
            if (flag == FlagFork.REVERT) {
                revert(errMsg);
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(sender, errMsg);
            }
        }
        
        return rolesWhichCan;
    }

    
    function _isRoleValid(uint8 index) internal view {
        require(
            (rolesCount > index), 
            "invalid role"
        ); 
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
