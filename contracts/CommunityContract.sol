// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./IntercoinTrait.sol";

import "./lib/PackedSet.sol";


contract CommunityContract is Initializable/*, OwnableUpgradeable*/, ReentrancyGuardUpgradeable, IntercoinTrait, IERC721Upgradeable, IERC721MetadataUpgradeable {
    
    using PackedSet for PackedSet.Set;

    //PackedSet.Set x;

    using StringUtils for *;

    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
    using SafeMathUpgradeable for uint256;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using AddressUpgradeable for address;

    struct inviteSignature {
        bytes pSig;
        bytes rpSig;
        uint256 gasCost;
        ReimburseStatus reimbursed;
        bool used;
        bool exists;
    }
    
    uint8 private rolesIndex;
    mapping (bytes32 => uint8) internal _roles;
    //mapping (uint256 => bytes32) internal _rolesIndices;
    mapping (address => PackedSet.Set) internal _rolesByMember;
    //mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) internal _membersByRoles;
    //mapping (uint256 => EnumerableSetUpgradeable.UintSet) internal _canManageRoles;

    struct Role {
        bytes32 name;
        string roleURI;
        string extraURI;
        EnumerableSetUpgradeable.UintSet canManageRoles;
        EnumerableSetUpgradeable.AddressSet membersByRoles;
    }
    mapping (uint8 => Role) internal _rolesIndices;



    mapping (bytes => inviteSignature) inviteSignatures;          
    
    bytes32 public constant DEFAULT_OWNERS_ROLE = 0x6f776e6572730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_ADMINS_ROLE = 0x61646d696e730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_MEMBERS_ROLE = 0x6d656d6265727300000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_WEBX_ROLE = 0x7765627800000000000000000000000000000000000000000000000000000000;
    
    enum ReimburseStatus{ NONE, PENDING, DONE }
    uint256 public constant REWARD_AMOUNT = 1000000000000000; // 0.001 * 1e18
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
//      sourceAddr 
mapping(address => ActionInfo[]) public grantedBy;
mapping(address => ActionInfo[]) public revokedBy;
mapping(address => ActionInfo[]) public granted;
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
     * does address belong to role
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
     * is role can be managed by sender's roles?
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
     * @param pSig signature of admin whom generate invite and signed it
     */
    modifier accummulateGasCost(bytes memory pSig)
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
        inviteSignatures[pSig].gasCost = inviteSignatures[pSig].gasCost.add(gasCost);
    }

    /**
     * @param pSig signature of admin whom generate invite and signed it
     */
    modifier refundGasCost(bytes memory pSig)
    {
        uint remainingGasStart = gasleft();

        _;
        
        uint gasCost;
        
        if (inviteSignatures[pSig].reimbursed == ReimburseStatus.NONE) {
            uint remainingGasEnd = gasleft();
            uint usedGas = remainingGasStart - remainingGasEnd;

            // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            usedGas += 21000 + 9700 + 47500;

            // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
            gasCost = usedGas * tx.gasprice;

            inviteSignatures[pSig].gasCost = inviteSignatures[pSig].gasCost.add(gasCost);
        } else {
            
        }
        // Refund gas cost
        gasCost = inviteSignatures[pSig].gasCost;

        if (
            (gasCost <= address(this).balance) && 
            (
            inviteSignatures[pSig].reimbursed == ReimburseStatus.NONE ||
            inviteSignatures[pSig].reimbursed == ReimburseStatus.PENDING
            )
        ) {
            inviteSignatures[pSig].reimbursed = ReimburseStatus.DONE;
            //payable (inviteSignatures[pSig].caller).transfer(gasCost);
           
            payable(msg.sender).transfer(gasCost);

        } else {
            inviteSignatures[pSig].reimbursed = ReimburseStatus.PENDING;
        }
        
        
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function donateETH() public payable {} 
    

///////////////////////////////////////////////////////////
//// virtual erc721 ////

    function balanceOf(
        address owner
    ) 
        external 
        view 
        override
        returns (uint256 balance) 
    {
        for (uint8 i= 0; i < rolesIndex; i++) {
            if (_isTargetInRole(owner, _rolesIndices[i].name)) {
                balance += 1;
            }
        }
    }

    function ownerOf(
        uint256 tokenId
    ) 
        external 
        view 
        override
        returns (address owner) 
    {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));
        
        owner = (_isTargetInRole(w, _rolesIndices[roleId].name)) ? w : address(0);

    }

    function operationReverted(
    ) 
        internal 
        pure
    {
        revert("CommunityContract: NOT_AUTHORIZED");
    }

    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }
    
    function approve(
        address /*to*/, 
        uint256 /*tokenId*/
    )
        external 
        pure
        override
    {
        operationReverted();
    }

    function getApproved(
        uint256 tokenId
    ) 
        external
        view 
        override 
        returns (address operator) 
    {

    }

    function setApprovalForAll(
        address /*operator*/, 
        bool /*_approved*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    function isApprovedForAll(
        address owner, 
        address operator
    ) 
        external 
        view 
        override
        returns (bool) 
    {

    }

    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }
        
    function name(
    ) 
        external 
        pure 
        override 
        returns (string memory) 
    {
        return "Community";
    }

    
    function symbol(
    ) 
        external 
        pure 
        override 
        returns (string memory)
    {
        return "Community";
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory)
    {
        return _rolesIndices[uint8(tokenId >> 160)].roleURI;
    }
///////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    
    
    /**
     * @dev creates three default roles and manage relations between it
     */
    function init() public initializer {
        
        //__Ownable_init();
        __ReentrancyGuard_init();
        
        rolesIndex = 1;
        
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_WEBX_ROLE);
        _grantRole(msg.sender, DEFAULT_OWNERS_ROLE);
        _grantRole(msg.sender, DEFAULT_ADMINS_ROLE);
        _grantRole(msg.sender, DEFAULT_WEBX_ROLE);
        //an exception from the rules. owners can manage owners role. 
        //means that can grant member to owner role and revoke it.
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_OWNERS_ROLE); 
        //---                                                                
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_ADMINS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_MEMBERS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_WEBX_ROLE);
        //_manageRole(DEFAULT_MEMBERS_ROLE, DEFAULT_MEMBERS_ROLE);
    }
    
    /**
     * Added participants to role members
     * @param members participant's addresses
     */
    function addMembers(
        address[] memory members
    )
        canManage(msg.sender, DEFAULT_MEMBERS_ROLE)
        public 
    {
        
        uint256 len = members.length;
        uint256 i;
        for (i = 0; i < len; i++) {
            _grantRole(members[i], DEFAULT_MEMBERS_ROLE);
        }
    }
    
    /**
     * Removed participants from  role members
     * @param members participant's addresses
     */
    function removeMembers(
        address[] memory members
    )
        canManage(msg.sender, DEFAULT_MEMBERS_ROLE)
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
     * Added new Roles for members
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
                if (!_isCanManage(msg.sender, roles[j].stringToBytes32())) {
                    revert(string(abi.encodePacked("Sender can not manage Members with role '",roles[j],"'")));
                }
                _grantRole(members[i], roles[j].stringToBytes32());
            }
        }
    }
    
    /**
     * Removed Role for member
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
                
                if (!_isCanManage(msg.sender, roleBytes32)) {
                    revert(string(abi.encodePacked("Sender can not manage Members with role '",roles[j],"'")));
                }
                _revokeRole(members[i], roles[j].stringToBytes32());

                
            }
        }
    }
    
    /**
     * creating new role. can called owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        //onlyOwner 
        ifTargetInRole(msg.sender, DEFAULT_OWNERS_ROLE) 
    {
        require(_roles[role.stringToBytes32()] == 0, 'Such role is already exists');
        
        // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        require(_roles[role._toLower().stringToBytes32()] == 0, 'Such role is already exists');
        
        require(rolesIndex < type(uint8).max -1, "Max amount of roles exceeded");

        _createRole(role.stringToBytes32());
        
       // new role must manage DEFAULT_MEMBERS_ROLE to be able to add members
       _manageRole(role.stringToBytes32(), DEFAULT_MEMBERS_ROLE);
       
       _manageRole(DEFAULT_OWNERS_ROLE, role.stringToBytes32());
       _manageRole(DEFAULT_ADMINS_ROLE, role.stringToBytes32());
    }
    
    /**
     * allow account with sourceRole setup targetRole to another account with default role(members)
     */
    function manageRole(
        string memory sourceRole, 
        string memory targetRole
    ) 
        public 
        //onlyOwner
        ifTargetInRole(msg.sender, DEFAULT_OWNERS_ROLE) 
    {
        
        if (targetRole.stringToBytes32() == DEFAULT_OWNERS_ROLE) {
            revert(string(abi.encodePacked("targetRole can not be '",targetRole, "'")));
        }
        
        _manageRole(sourceRole.stringToBytes32(), targetRole.stringToBytes32());
    }
    
    /**
     * Returns all members belong to Role
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
        uint256 len = _rolesIndices[roleIndex].membersByRoles.length();
        address[] memory l = new address[](len);
        uint256 i;
            
        for (i = 0; i < len; i++) {
            l[i] = _rolesIndices[roleIndex].membersByRoles.at(i);
        }
        return l;
    }
    
    /**
     * if call without params then returns all members belong to `DEFAULT_MEMBERS_ROLE`
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
     * Returns all roles which member belong to
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
            l[i] = _rolesIndices[uint8(_rolesByMember[member].get(i))].name.bytes32ToString();
        }
        return l;
    }
    
    /**
     * if call without params then returns all existing roles 
     * @return array of roles 
     */
    function getRoles(
    ) 
        public 
        view
        returns(string[] memory)
    {

        string[] memory l = new string[](rolesIndex);
        for (uint8 i = 0; i < rolesIndex; i++) {
            l[i] = _rolesIndices[i].name.bytes32ToString();
        }
        return l;
    }
    
    /**
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
        return _rolesIndices[_roles[role.stringToBytes32()]].membersByRoles.length();
    }
        
    /**
     * if call without params then returns count of all members with default role
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
     * @param pSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory pSig
    ) 
        public 
        view
        returns(inviteSignature memory)
    {
        return inviteSignatures[pSig];
    }
    
    /**
     * @param pSig signature of admin whom generate invite and signed it
     * @param rpSig signature of recipient
     */
    function invitePrepare(
        bytes memory pSig, 
        bytes memory rpSig
    ) 
        public 
        ifTargetInRole(msg.sender, DEFAULT_WEBX_ROLE) 
        accummulateGasCost(pSig)
    {
        require(inviteSignatures[pSig].exists == false, "Such signature is already exists");
        inviteSignatures[pSig].pSig = pSig;
        inviteSignatures[pSig].rpSig = rpSig;
        inviteSignatures[pSig].reimbursed = ReimburseStatus.NONE;
        inviteSignatures[pSig].used = false;
        inviteSignatures[pSig].exists = true;
    }
    
    /**
     * @dev
     * // ==P==
     * // format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"        
     * // invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak
     * // ==R==
     * // format is "<address of R wallet>:<name of user>"
     * // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe
     * 
     * @param p invite message of admin whom generate messageHash and signed it
     * @param pSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rpSig signature of recipient
     */
    function inviteAccept(
        string memory p, 
        bytes memory pSig, 
        string memory rp, 
        bytes memory rpSig
    )
        public 
        ifTargetInRole(msg.sender, DEFAULT_WEBX_ROLE) 
        refundGasCost(pSig)
        nonReentrant()
    {
        require(inviteSignatures[pSig].used == false, "Such signature is already used");

        (address pAddr, address rpAddr) = _recoverAddresses(p, pSig, rp, rpSig);
       
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");
        
        if (
            pAddr == address(0) || 
            rpAddr == address(0) || 
            keccak256(abi.encode(inviteSignatures[pSig].rpSig)) != keccak256(abi.encode(rpSig)) ||
            rpDataArr[0].parseAddr() != rpAddr || 
            dataArr[1].parseAddr() != address(this)
        ) {
            revert('Signature are mismatch');
        }
        
        bool isCanProceed = false;
        
        if (_isCanManage(pAddr, DEFAULT_MEMBERS_ROLE)) {
            _grantRole(rpAddr, DEFAULT_MEMBERS_ROLE);
            
            for (uint256 i = 0; i < rolesArr.length; i++) {
                if (_isCanManage(pAddr, rolesArr[i].stringToBytes32())) {
                    isCanProceed = true;
                    _grantRole(rpAddr, rolesArr[i].stringToBytes32());
                } else {
                    emit RoleAddedErrorMessage(msg.sender, string(abi.encodePacked("inviting user did not have permission to add role '",rolesArr[i],"'")));
                }
            }
        
        } else {
            emit RoleAddedErrorMessage(msg.sender, string(abi.encodePacked("inviting user did not have permission to add role '",DEFAULT_MEMBERS_ROLE.bytes32ToString(),"'")));
        }
        
        if (isCanProceed == true) {
            inviteSignatures[pSig].used = true;
            
            invitedBy[rpAddr] = pAddr;
            invited[pAddr].add(rpAddr);
            
            _rewardCaller();
            _replenishRecipient(rpAddr);
            
        } else {
            revert("Can not add no one role");
        }
        
    }
    
    function setRoleURI(
        string memory role,
        string memory roleURI
    ) 
        public 
        canManage(msg.sender, role.stringToBytes32())
    {
        _rolesIndices[_roles[role.stringToBytes32()]].roleURI = roleURI;
    }

    function setExtraURI(
        string memory role,
        string memory extraURI
    )
        public
        ifTargetInRole(msg.sender, role.stringToBytes32())
    {
        _rolesIndices[_roles[role.stringToBytes32()]].extraURI = extraURI;
    }
    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
   
    fallback() external payable {}
    receive() external payable {}
    
    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////
   
   
    ///////////////////////////////////////////////////////////
    /// private section
    ///////////////////////////////////////////////////////////
    /**
     * @param role role name
     */
    function _createRole(bytes32 role) private {
       _roles[role] = rolesIndex;
       _rolesIndices[rolesIndex].name = role;
       rolesIndex += 1;
       
       emit RoleCreated(role, msg.sender);
    }
   
    /**
     * Set availability for members with `sourceRole` addMember/removeMember/addMemberRole/removeMemberRole
     * @param sourceRole source role name
     * @param targetRole target role name
     */
    function _manageRole(bytes32 sourceRole, bytes32 targetRole) private {
       require(_roles[sourceRole] != 0, "Source role does not exists");
       require(_roles[targetRole] != 0, "Source role does not exists");
       
       _rolesIndices[_roles[sourceRole]].canManageRoles.add(_roles[targetRole]);
       
       emit RoleManaged(sourceRole, targetRole, msg.sender);
    }
    
    /**
     * adding role to member
     * @param account account's address
     * @param targetRole role name
     */
    function _grantRole(address account, bytes32 targetRole) private {
       _rolesByMember[account].add(_roles[targetRole]);
       _rolesIndices[_roles[targetRole]].membersByRoles.add(account);
       
       grantedBy[account].push(ActionInfo({
            actor: msg.sender,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
       }));
       grantedBy[msg.sender].push(ActionInfo({
            actor: account,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
       }));
       
       emit RoleGranted(targetRole, account, msg.sender);
    }
    
    /**
     * removing role from member
     * @param account account's address
     * @param targetRole role name
     */
    function _revokeRole(address account, bytes32 targetRole) private {
       _rolesByMember[account].remove(_roles[targetRole]);
       _rolesIndices[_roles[targetRole]].membersByRoles.remove(account);
       
       revokedBy[account].push(ActionInfo({
            actor: msg.sender,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
       }));
       revoked[msg.sender].push(ActionInfo({
            actor: account,
            timestamp: uint64(block.timestamp),
            extra: uint32(_roles[targetRole])
       }));

       emit RoleRevoked(targetRole, account, msg.sender);
    }
    
    function _isTargetInRole(address target, bytes32 targetRole) private view returns(bool) {
        return _rolesByMember[target].contains(_roles[targetRole]);
    }
    
    function _isCanManage(address sender, bytes32 targetRole) private view returns (bool) {
     
        bool isCan = false;
        
        uint256 targetRoleID = _roles[targetRole];
        
        require(
            targetRoleID != 0,
            string(abi.encodePacked("Such role '",targetRole.bytes32ToString(),"' does not exists"))
        );
        
        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_rolesIndices[uint8(_rolesByMember[sender].get(i))].canManageRoles.contains(targetRoleID) == true) {
                isCan = true;
                break;
            }
        }
        return isCan;
    }
    
    /**
     * @param p invite message of admin whom generate messageHash and signed it
     * @param pSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rpSig signature of recipient
     */
    function _recoverAddresses(
        string memory p, 
        bytes memory pSig, 
        string memory rp, 
        bytes memory rpSig
    ) 
        private 
        pure
        returns(address, address)
    {
        bytes32 pHash = p.recreateMessageHash();
        bytes32 rpHash = rp.recreateMessageHash();
        address pAddr = pHash.recover(pSig);
        address rpAddr = rpHash.recover(rpSig);
        return (pAddr, rpAddr);
    }
    
    /**
     * reward caller(webx)
     */
    function _rewardCaller(
    ) 
        private 
    {
        if (REWARD_AMOUNT <= address(this).balance) {
            payable(msg.sender).transfer(REWARD_AMOUNT);
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
