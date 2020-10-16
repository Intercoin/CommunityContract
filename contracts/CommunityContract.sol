pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;


import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/utils/EnumerableSet.sol";
import "./openzeppelin-contracts/contracts/access/Ownable.sol";
//import "./openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./openzeppelin-contracts/contracts/utils/Address.sol";


/*
0x5a0b54d5dc17e0aadc383d2db43b0a0d3e029c4c
*/
contract CommunityContract is Ownable {
    using SafeMath for uint256;
    
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }
    
    uint256 private rolesIndex = 1;
    mapping (bytes32 => uint256) internal _roles;
    mapping (uint256 => bytes32) internal _rolesIndices;
    
    
    mapping (address => EnumerableSet.UintSet) internal _rolesByMember;
    mapping (bytes32 => EnumerableSet.AddressSet) internal _membersByRoles;
    
    mapping (uint256 => EnumerableSet.UintSet) internal _canManageRoles;
    
    // _rolesByMember = {address: array}
    // _membersByRoles = {role: array}

    bytes32 public constant DEFAULT_OWNERS_ROLE = 0x6f776e6572730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_ADMINS_ROLE = 0x61646d696e730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_MEMBERS_ROLE = 0x6d656d6265727300000000000000000000000000000000000000000000000000;

    event RoleCreated(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleManaged(bytes32 indexed sourceRole, bytes32 indexed targetRole, address indexed sender);

// 0xdba76e955e3660da446b348c972b44d911a1cf32

    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////
    
    /**
     * is role can be managed by sender's roles?
     * @dev can addMember/removeMember/addMemberRole/removeMemberRole
     * @param sender sender
     * @param targetRole role that check to be managed by sender's roles
     */
    modifier canManage(address sender, bytes32 targetRole) {
     
        bool isCan = false;
        
        uint256 targetRoleID = _roles[targetRole];
        
        require(
            targetRoleID != 0,
            string(abi.encodePacked("Such role '",bytes32ToString(targetRole),"' does not exists"))
        );
        
        for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
            
            if (_canManageRoles[_rolesByMember[sender].at(i)].contains(targetRoleID) == true) {
                isCan = true;
                break;
            }
        }
    
        require(
            isCan == true,
            string(abi.encodePacked("Sender can not manage Members with role '",bytes32ToString(targetRole),"'"))
        );
        _;
    }
    
    /**
     * does address belong to rolename
     * @param target address
     * @param targetRole rolename
     */
    modifier ifTargetInRole(address target, bytes32 targetRole) {
        
        require(
            _rolesByMember[target].contains(_roles[targetRole]) == true,
            string(abi.encodePacked("Target account must be with role '",bytes32ToString(targetRole),"'"))
        );
        _;
    }
    
    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    /**
     * @dev creates three default roles and manage relations between it
     */
    constructor() public {
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _addMemberRole(_msgSender(), DEFAULT_OWNERS_ROLE);
        _addMemberRole(_msgSender(), DEFAULT_ADMINS_ROLE);
        _manageRole(DEFAULT_OWNERS_ROLE, DEFAULT_ADMINS_ROLE);
        _manageRole(DEFAULT_ADMINS_ROLE, DEFAULT_MEMBERS_ROLE);
        //_manageRole(DEFAULT_MEMBERS_ROLE, DEFAULT_MEMBERS_ROLE);
        
    }
    
    /**
     * Added participant to role members
     * @param member address
     */
    function addMember(
        address member
    )
        canManage(_msgSender(), DEFAULT_MEMBERS_ROLE)
        public 
    {
        _addMemberRole(member, DEFAULT_MEMBERS_ROLE);
    }
    
    /**
     * Removed participant from  role members
     * @param member address
     */
    function removeMember(
        address member
    )
        canManage(_msgSender(), DEFAULT_MEMBERS_ROLE)
        public 
    {
        _removeMemberRole(member, DEFAULT_MEMBERS_ROLE);
        //TODO 0: does need to remove from all exists roles?
        
    }
    
    /**
     * Added new Role for member
     * @param member address
     * @param roleName Role name
     */
    function addMemberRole(
        address member, 
        string memory roleName
    )
        ifTargetInRole(member, DEFAULT_MEMBERS_ROLE)
        canManage(_msgSender(), stringToBytes32(roleName))
        public 
    {
        _addMemberRole(member, stringToBytes32(roleName));
    }
    
    /**
     * Removed Role for member
     * @param member address
     * @param roleName Role name
     */
    function removeMemberRole(
        address member, 
        string memory roleName
    ) 
        ifTargetInRole(member, DEFAULT_MEMBERS_ROLE)
        canManage(_msgSender(), stringToBytes32(roleName))
        public 
    {
        if (stringToBytes32(roleName) == DEFAULT_MEMBERS_ROLE) {
            revert(string(abi.encodePacked("Can not remove role '",roleName,"'")));
        }
        _removeMemberRole(member, stringToBytes32(roleName));
    }
    
    /**
     * overrode transferOwnership. new owner will get DEFAULT_OWNERS_ROLE
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        
        Ownable.transferOwnership(newOwner);
        _removeMemberRole(owner(), DEFAULT_OWNERS_ROLE);
        _addMemberRole(newOwner, DEFAULT_OWNERS_ROLE);
    }
    
    /**
     * creating new role. can called onlyOwner
     * @param roleName role name
     */
    function createRole(
        string memory roleName
    ) 
        public 
        onlyOwner 
    {
        require(_roles[stringToBytes32(roleName)] == 0, 'Such role is already exists');
        
        // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        require(_roles[stringToBytes32(_toLower(roleName))] == 0, 'Such role is already exists');
        
        _createRole(stringToBytes32(roleName));
        
       // new role must manage DEFAULT_MEMBERS_ROLE to be able to add members
       _manageRole(stringToBytes32(roleName), DEFAULT_MEMBERS_ROLE);
       
       _manageRole(DEFAULT_OWNERS_ROLE, stringToBytes32(roleName));
       _manageRole(DEFAULT_ADMINS_ROLE, stringToBytes32(roleName));
       
    }
    
    /**
     * allow account with sourceRole setup targetRole to another account with default role(members)
     */
    function manageRole(
        string memory sourceRole, 
        string memory targetRole
    ) 
        public 
        onlyOwner
    {
        
        if (stringToBytes32(targetRole) == DEFAULT_OWNERS_ROLE) {
            revert(string(abi.encodePacked("targetRole сan not be '",targetRole,"'")));
        }
        
        _manageRole(stringToBytes32(sourceRole), stringToBytes32(targetRole));
    }
    
    /**
     * Returns all members belong to Role
     * @param roleName role name
     * @return array of address 
     */
    function getMembers(
        string memory roleName
    ) 
        public 
        view
        returns(address[] memory)
    {
        bytes32 roleNameB= stringToBytes32(roleName);
        uint256 len = _membersByRoles[roleNameB].length();
        address[] memory l = new address[](len);
        uint256 i;
            
        for (i = 0; i < len; i++) {
            l[i] = _membersByRoles[roleNameB].at(i);
        }
        return l;
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
            l[i] = bytes32ToString(_rolesIndices[_rolesByMember[member].at(i)]);
        }
        return l;
    }
    
    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////
    
    ///////////////////////////////////////////////////////////
    /// private section
    ///////////////////////////////////////////////////////////
    /**
     * @param roleName role name
     */
    function _createRole(bytes32 roleName) private {
       _roles[roleName] = rolesIndex;
       _rolesIndices[rolesIndex] = roleName;
       rolesIndex = rolesIndex.add(1);
       
       emit RoleCreated(roleName, _msgSender());
    }
   
    /**
     * Set availability for members with `sourceRole` addMember/removeMember/addMemberRole/removeMemberRole
     * @param sourceRole source role name
     * @param targetRole target role name
     */
    function _manageRole(bytes32 sourceRole, bytes32 targetRole) private {
       require(_roles[sourceRole] != 0, "Source role does not exists");
       require(_roles[targetRole] != 0, "Source role does not exists");
       
       _canManageRoles[_roles[sourceRole]].add(_roles[targetRole]);
       
       emit RoleManaged(sourceRole, targetRole, _msgSender());
    }
    
    /**
     * adding role to member
     * @param account account's address
     * @param targetRole role name
     */
    function _addMemberRole(address account, bytes32 targetRole) private {
       _rolesByMember[account].add(_roles[targetRole]);
       _membersByRoles[targetRole].add(account);
       
       emit RoleGranted(targetRole, account, _msgSender());
    }
    
    /**
     * removing role from member
     * @param account account's address
     * @param targetRole role name
     */
    function _removeMemberRole(address account, bytes32 targetRole) private {
       _rolesByMember[account].remove(_roles[targetRole]);
       _membersByRoles[targetRole].remove(account);
       
       emit RoleRevoked(targetRole, account, _msgSender());
    }
    
    /**
     * convert string to bytes32
     * @param source string variable
     */
    function stringToBytes32(string memory source) internal view returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * convert bytes32 to string
     * @param _bytes32 bytes32 variable
     */
    function bytes32ToString(bytes32 _bytes32) internal view returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    /**
     * convert string to lowercase
     */
    function _toLower(string memory str) internal view returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
   
}
