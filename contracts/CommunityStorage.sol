// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "trustedforwarder/contracts/TrustedForwarder.sol";
import "releasemanager/contracts/CostManagerHelperERC2771Support.sol";
import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./lib/PackedSet.sol";
import "./interfaces/ICommunityHook.sol";

abstract contract CommunityStorage is Initializable, ReentrancyGuardUpgradeable, TrustedForwarder, CostManagerHelperERC2771Support, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    struct inviteSignature {bytes sSig;bytes rSig;uint256 gasCost;ReimburseStatus reimbursed;bool used;bool exists;}
    struct GrantSettings {uint8 requireRole;uint256 maxAddresses;uint64 duration;uint64 lastIntervalIndex;uint256 grantedAddressesCounter;}
    struct Role {bytes32 name;string roleURI;mapping(address => string) extraURI;EnumerableSetUpgradeable.UintSet canGrantRoles;EnumerableSetUpgradeable.UintSet canRevokeRoles;mapping(uint8 => GrantSettings) grantSettings;EnumerableSetUpgradeable.AddressSet members;}
    struct ActionInfo {address actor;uint64 timestamp;uint32 extra;}
    string public name;
    string public symbol;
    uint8 internal rolesCount;
    address public hook;
    uint256 addressesCounter;
    uint8 internal constant NONE_ROLE_INDEX = 0;
    bytes32 public constant DEFAULT_OWNERS_ROLE = 0x6f776e6572730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_ADMINS_ROLE = 0x61646d696e730000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_MEMBERS_ROLE = 0x6d656d6265727300000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_RELAYERS_ROLE = 0x72656c6179657273000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_ALUMNI_ROLE = 0x616c756d6e690000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_VISITORS_ROLE = 0x76697369746f7273000000000000000000000000000000000000000000000000;
    uint256 public constant REWARD_AMOUNT = 1000000000000000; // 0.001 * 1e18
    uint256 public constant REPLENISH_AMOUNT = 1000000000000000; // 0.001 * 1e18
    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_GRANT_ROLES = 0x1;
    uint8 internal constant OPERATION_REVOKE_ROLES = 0x2;
    uint8 internal constant OPERATION_CREATE_ROLE = 0x3;
    uint8 internal constant OPERATION_MANAGE_ROLE = 0x4;
    uint8 internal constant OPERATION_SET_TRUSTED_FORWARDER = 0x5;
    uint8 internal constant OPERATION_INVITE_PREPARE = 0x6;
    uint8 internal constant OPERATION_INVITE_ACCEPT = 0x7;
    uint8 internal constant OPERATION_SET_ROLE_URI = 0x8;
    uint8 internal constant OPERATION_SET_EXTRA_URI = 0x9;
    enum ReimburseStatus{ NONE, PENDING, CLAIMED }
    enum FlagFork{ NONE, EMIT, REVERT }
    mapping(address => address) public invitedBy;
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal invited;
    mapping (bytes32 => uint8) internal _roles;
    mapping (address => PackedSet.Set) internal _rolesByMember;
    mapping (uint8 => Role) internal _rolesByIndex;
    mapping (bytes => inviteSignature) inviteSignatures;          
    mapping(address => ActionInfo[]) public grantedBy;
    mapping(address => ActionInfo[]) public revokedBy;
    mapping(address => ActionInfo[]) public granted;
    mapping(address => ActionInfo[]) public revoked;
    event RoleCreated(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleManaged(uint8 indexed sourceRole, uint8 indexed targetRole, bool canGrantRole, bool canRevokeRole, uint8 requireRole, uint256 maxAddresses, uint64 duration,address indexed sender);
    event RoleAddedErrorMessage(address indexed sender, string msg);
    modifier accummulateGasCost(bytes memory sSig){
        uint remainingGasStart = gasleft();
        _;
        uint remainingGasEnd = gasleft();
        inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;}
    modifier refundGasCost(bytes memory sSig){
        uint remainingGasStart = gasleft();
        _;
        uint gasCost;
        if (inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE) {
            uint remainingGasEnd = gasleft();
            inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + ((remainingGasStart - remainingGasEnd + 78200) * tx.gasprice);}
        gasCost = inviteSignatures[sSig].gasCost;
        if ((gasCost <= address(this).balance) && (inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE || inviteSignatures[sSig].reimbursed == ReimburseStatus.PENDING)) {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.CLAIMED;
            payable(_msgSender()).transfer(gasCost);
        } else {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.PENDING;}}
    function _isTargetInRole(address target, uint8 targetRoleIndex) internal view returns(bool) {return _rolesByMember[target].contains(targetRoleIndex);}
    function setTrustedForwarder(address forwarder) public virtual override {}
    function balanceOf(address account) external view virtual returns (uint256 balance) {}
    function ownerOf(uint256 tokenId) external view virtual returns (address owner) {}
    function tokenURI(uint256 tokenId) external view virtual returns (string memory){}
    function operationReverted() internal pure {revert("CommunityContract: NOT_AUTHORIZED");}
    function safeTransferFrom(address,address,uint256) external pure override {operationReverted();}
    function transferFrom(address,address,uint256) external pure override {operationReverted();}
    function approve(address, uint256) external pure override {operationReverted();}
    function getApproved(uint256) external pure override returns (address) {operationReverted();}
    function setApprovalForAll(address, bool) external pure override {operationReverted();}
    function isApprovedForAll(address, address) external pure override returns (bool) {operationReverted();}
    function safeTransferFrom(address,address,uint256,bytes calldata) external pure override {operationReverted();}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;}
}