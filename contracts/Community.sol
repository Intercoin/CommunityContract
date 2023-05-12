// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

//import "./lib/ECDSAExt.sol";
import "./lib/StringUtils.sol";
import "./lib/PackedSet.sol";

import "./interfaces/ICommunityHook.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/ICommunityInvite.sol";

/**
*****************
TEMPLATE CONTRACT
*****************

Although this code is available for viewing on GitHub and here, the general public is NOT given a license to freely deploy smart contracts based on this code, on any blockchains.

To prevent confusion and increase trust in the audited code bases of smart contracts we produce, we intend for there to be only ONE official Factory address on the blockchain producing the corresponding smart contracts, and we are going to point a blockchain domain name at it.

Copyright (c) Intercoin Inc. All rights reserved.

ALLOWED USAGE.

Provided they agree to all the conditions of this Agreement listed below, anyone is welcome to interact with the official Factory Contract at the this address to produce smart contract instances, or to interact with instances produced in this manner by others.

Any user of software powered by this code MUST agree to the following, in order to use it. If you do not agree, refrain from using the software:

DISCLAIMERS AND DISCLOSURES.

Customer expressly recognizes that nearly any software may contain unforeseen bugs or other defects, due to the nature of software development. Moreover, because of the immutable nature of smart contracts, any such defects will persist in the software once it is deployed onto the blockchain. Customer therefore expressly acknowledges that any responsibility to obtain outside audits and analysis of any software produced by Developer rests solely with Customer.

Customer understands and acknowledges that the Software is being delivered as-is, and may contain potential defects. While Developer and its staff and partners have exercised care and best efforts in an attempt to produce solid, working software products, Developer EXPRESSLY DISCLAIMS MAKING ANY GUARANTEES, REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, ABOUT THE FITNESS OF THE SOFTWARE, INCLUDING LACK OF DEFECTS, MERCHANTABILITY OR SUITABILITY FOR A PARTICULAR PURPOSE.

Customer agrees that neither Developer nor any other party has made any representations or warranties, nor has the Customer relied on any representations or warranties, express or implied, including any implied warranty of merchantability or fitness for any particular purpose with respect to the Software. Customer acknowledges that no affirmation of fact or statement (whether written or oral) made by Developer, its representatives, or any other party outside of this Agreement with respect to the Software shall be deemed to create any express or implied warranty on the part of Developer or its representatives.

INDEMNIFICATION.

Customer agrees to indemnify, defend and hold Developer and its officers, directors, employees, agents and contractors harmless from any loss, cost, expense (including attorney’s fees and expenses), associated with or related to any demand, claim, liability, damages or cause of action of any kind or character (collectively referred to as “claim”), in any manner arising out of or relating to any third party demand, dispute, mediation, arbitration, litigation, or any violation or breach of any provision of this Agreement by Customer.

NO WARRANTY.

THE SOFTWARE IS PROVIDED “AS IS” WITHOUT WARRANTY. DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES FOR BREACH OF THE LIMITED WARRANTY. TO THE MAXIMUM EXTENT PERMITTED BY LAW, DEVELOPER EXPRESSLY DISCLAIMS, AND CUSTOMER EXPRESSLY WAIVES, ALL OTHER WARRANTIES, WHETHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT LIMITATION ALL IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR USE, OR ANY WARRANTY ARISING OUT OF ANY PROPOSAL, SPECIFICATION, OR SAMPLE, AS WELL AS ANY WARRANTIES THAT THE SOFTWARE (OR ANY ELEMENTS THEREOF) WILL ACHIEVE A PARTICULAR RESULT, OR WILL BE UNINTERRUPTED OR ERROR-FREE. THE TERM OF ANY IMPLIED WARRANTIES THAT CANNOT BE DISCLAIMED UNDER APPLICABLE LAW SHALL BE LIMITED TO THE DURATION OF THE FOREGOING EXPRESS WARRANTY PERIOD. SOME STATES DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES AND/OR DO NOT ALLOW LIMITATIONS ON THE AMOUNT OF TIME AN IMPLIED WARRANTY LASTS, SO THE ABOVE LIMITATIONS MAY NOT APPLY TO CUSTOMER. THIS LIMITED WARRANTY GIVES CUSTOMER SPECIFIC LEGAL RIGHTS. CUSTOMER MAY HAVE OTHER RIGHTS WHICH VARY FROM STATE TO STATE. 

LIMITATION OF LIABILITY. 

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL DEVELOPER BE LIABLE UNDER ANY THEORY OF LIABILITY FOR ANY CONSEQUENTIAL, INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE OR EXEMPLARY DAMAGES OF ANY KIND, INCLUDING, WITHOUT LIMITATION, DAMAGES ARISING FROM LOSS OF PROFITS, REVENUE, DATA OR USE, OR FROM INTERRUPTED COMMUNICATIONS OR DAMAGED DATA, OR FROM ANY DEFECT OR ERROR OR IN CONNECTION WITH CUSTOMER'S ACQUISITION OF SUBSTITUTE GOODS OR SERVICES OR MALFUNCTION OF THE SOFTWARE, OR ANY SUCH DAMAGES ARISING FROM BREACH OF CONTRACT OR WARRANTY OR FROM NEGLIGENCE OR STRICT LIABILITY, EVEN IF DEVELOPER OR ANY OTHER PERSON HAS BEEN ADVISED OR SHOULD KNOW OF THE POSSIBILITY OF SUCH DAMAGES, AND NOTWITHSTANDING THE FAILURE OF ANY REMEDY TO ACHIEVE ITS INTENDED PURPOSE. WITHOUT LIMITING THE FOREGOING OR ANY OTHER LIMITATION OF LIABILITY HEREIN, REGARDLESS OF THE FORM OF ACTION, WHETHER FOR BREACH OF CONTRACT, WARRANTY, NEGLIGENCE, STRICT LIABILITY IN TORT OR OTHERWISE, CUSTOMER'S EXCLUSIVE REMEDY AND THE TOTAL LIABILITY OF DEVELOPER OR ANY SUPPLIER OF SERVICES TO DEVELOPER FOR ANY CLAIMS ARISING IN ANY WAY IN CONNECTION WITH OR RELATED TO THIS AGREEMENT, THE SOFTWARE, FOR ANY CAUSE WHATSOEVER, SHALL NOT EXCEED 1,000 USD.

TRADEMARKS.

This Agreement does not grant you any right in any trademark or logo of Developer or its affiliates.

LINK REQUIREMENTS.

Operators of any Websites and Apps which make use of smart contracts based on this code must conspicuously include the following phrase in their website, featuring a clickable link that takes users to intercoin.app:

"Visit https://intercoin.app to launch your own NFTs, DAOs and other Web3 solutions."

STAKING OR SPENDING REQUIREMENTS.

In the future, Developer may begin requiring staking or spending of Intercoin tokens in order to take further actions (such as producing series and minting tokens). Any staking or spending requirements will first be announced on Developer's website (intercoin.org) four weeks in advance. Staking requirements will not apply to any actions already taken before they are put in place.

CUSTOM ARRANGEMENTS.

Reach out to us at intercoin.org if you are looking to obtain Intercoin tokens in bulk, remove link requirements forever, remove staking requirements forever, or get custom work done with your Web3 projects.

ENTIRE AGREEMENT

This Agreement contains the entire agreement and understanding among the parties hereto with respect to the subject matter hereof, and supersedes all prior and contemporaneous agreements, understandings, inducements and conditions, express or implied, oral or written, of any nature whatsoever with respect to the subject matter hereof. The express terms hereof control and supersede any course of performance and/or usage of the trade inconsistent with any of the terms hereof. Provisions from previous Agreements executed between Customer and Developer., which are not expressly dealt with in this Agreement, will remain in effect.

SUCCESSORS AND ASSIGNS

This Agreement shall continue to apply to any successors or assigns of either party, or any corporation or other entity acquiring all or substantially all the assets and business of either party whether by operation of law or otherwise.

ARBITRATION

All disputes related to this agreement shall be governed by and interpreted in accordance with the laws of New York, without regard to principles of conflict of laws. The parties to this agreement will submit all disputes arising under this agreement to arbitration in New York City, New York before a single arbitrator of the American Arbitration Association (“AAA”). The arbitrator shall be selected by application of the rules of the AAA, or by mutual agreement of the parties, except that such arbitrator shall be an attorney admitted to practice law New York. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section. No party to this agreement will challenge the jurisdiction or venue provisions as provided in this section.
**/
contract Community is
    Initializable,
    ReentrancyGuardUpgradeable,
    TrustedForwarder,
    CostManagerHelperERC2771Support,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    OwnableUpgradeable,
    ICommunity
{
    using PackedSet for PackedSet.Set;

    using StringUtils for *;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    ////////////////////////////////
    ///////// structs //////////////
    ////////////////////////////////

    struct GrantSettings {
        uint8 requireRole; //=0,
        uint256 maxAddresses; //=0,
        uint64 duration; //=0
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

    /**
     * @notice getting name
     * @custom:shortd ERC721'name
     * @return name
     */
    string public name;

    /**
     * @notice getting symbol
     * @custom:shortd ERC721's symbol
     * @return symbol
     */
    string public symbol;
    /**
     * @notice uri that represent more information about thic community
     * @custom:shortd contract URI
     * @return URI
     */
    string public contractURI;

    uint8 internal rolesCount;
    address public hook;
    address internal _invitedHook;

    uint256 addressesCounter;

    /**
     * @custom:shortd role name "owners" in bytes32
     * @notice constant role name "owners" in bytes32
     */
    bytes32 public constant DEFAULT_OWNERS_ROLE =
        0x6f776e6572730000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "admins" in bytes32
     * @notice constant role name "admins" in bytes32
     */
    bytes32 public constant DEFAULT_ADMINS_ROLE =
        0x61646d696e730000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "members" in bytes32
     * @notice constant role name "members" in bytes32
     */
    bytes32 public constant DEFAULT_MEMBERS_ROLE =
        0x6d656d6265727300000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "alumni" in bytes32
     * @notice constant role name "alumni" in bytes32
     */
    bytes32 public constant DEFAULT_ALUMNI_ROLE =
        0x616c756d6e690000000000000000000000000000000000000000000000000000;

    /**
     * @custom:shortd role name "visitors" in bytes32
     * @notice constant role name "visitors" in bytes32
     */
    bytes32 public constant DEFAULT_VISITORS_ROLE =
        0x76697369746f7273000000000000000000000000000000000000000000000000;

    uint8 internal constant OPERATION_SHIFT_BITS = 240; // 256 - 16
    // Constants representing operations
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
    uint8 internal constant OPERATION_TRANSFEROWNERSHIP = 0xa;
    uint8 internal constant OPERATION_RENOUNCEOWNERSHIP = 0xb;
    uint8 internal constant OPERATION_SET_CONTRACT_URI = 0xc;

    uint8 internal constant NONE_ROLE_INDEX = 0;

    address public defaultAuthorizedInviteManager;

    // enum used in method when need to mark what need to do when error happens
    enum FlagFork {
        NONE,
        EMIT,
        REVERT
    }

    ////////////////////////////////
    ///////// mapping //////////////
    ////////////////////////////////

    mapping(bytes32 => uint8) internal _roles;
    mapping(address => PackedSet.Set) internal _rolesByAddress;
    mapping(uint8 => Role) internal _rolesByIndex;
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
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
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
    event RenounceOwnership();

    ////////////////////////////////
    ///////// errors ///////////////
    ////////////////////////////////
    error AuthorizedInviteManagerOnly();
    error NOT_SUPPORTED();

    ///////////////////////////////////////////////////////////
    /// modifiers  section
    ///////////////////////////////////////////////////////////

    receive() external payable {
        revert NOT_SUPPORTED();
    }

    ///////////////////////////////////////////////////
    // common to use
    //////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////
    /// external
    ///////////////////////////////////////////////////////////
    /**
     * @param hook_ address of contract implemented ICommunityHook interface. Can be address(0)
     * @param authorizedInviteManager_ address of contract implemented invite mechanism
     * @param name_ erc721 name
     * @param symbol_ erc721 symbol
     */
    function initialize(
        address hook_,
        address invitedHook_,
        address costManager_,
        address authorizedInviteManager_,
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) external override initializer {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        _setContractURI(contractURI_);

        _invitedHook = invitedHook_;
        name = name_;
        symbol = symbol_;

        rolesCount = 1;

        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);

        //_grantRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _grantRole(
            _roles[DEFAULT_OWNERS_ROLE],
            _msgSender(),
            _roles[DEFAULT_OWNERS_ROLE],
            _msgSender()
        );

        // initial rules. owners can manage any roles. to save storage we will hardcode in any validate
        // admins can manage members, alumni and visitors
        // any other rules can be added later by owners

        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_MEMBERS_ROLE],
            true,
            true,
            0,
            0,
            0
        );
        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_ALUMNI_ROLE],
            true,
            true,
            0,
            0,
            0
        );
        _manageRole(
            _roles[DEFAULT_ADMINS_ROLE],
            _roles[DEFAULT_VISITORS_ROLE],
            true,
            true,
            0,
            0,
            0
        );

        // avoiding hook's trigger for built-in roles
        // so define hook address in the end
        hook = hook_;

        defaultAuthorizedInviteManager = authorizedInviteManager_;

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(hook_)),
            uint256(uint160(costManager_))
        );
    }

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param roleIndexes Role indexes
     */
    function grantRoles(
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        _grantRoles(_msgSender(), accounts, roleIndexes);

        _accountForOperation(
            OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
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
    ) public {
        _revokeRoles(_msgSender(), accounts, roleIndexes);

        _accountForOperation(
            OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function grantRolesExternal(
        address accountWhichWillGrant,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        requireAuthorizedManager();
        _grantRoles(accountWhichWillGrant, accounts, roleIndexes);

        _accountForOperation(
            OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function revokeRolesExternal(
        address accountWhichWillRevoke,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) public {
        requireAuthorizedManager();
        _revokeRoles(accountWhichWillRevoke, accounts, roleIndexes);

        _accountForOperation(
            OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice creating new role. Can be called by owners role only
     * @custom:shortd creating new role. Can be called by owners role only
     * @param role role name
     */
    function createRole(string memory role) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        // require(_roles[role.stringToBytes32()] == 0, "Such role is already exists");
        // // prevent creating role in CamelCases with admins and owners (Admins,ADMINS,ADminS)
        // require(_roles[role._toLower().stringToBytes32()] == 0, "Such role is already exists");
        require(
            (_roles[role.stringToBytes32()] == 0) &&
                (_roles[role._toLower().stringToBytes32()] == 0),
            "Such role is already exists"
        );

        require(
            rolesCount < type(uint8).max - 1,
            "Max amount of roles exceeded"
        );

        _createRole(role.stringToBytes32());

        _accountForOperation(
            OPERATION_CREATE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );
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
    ) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            ofRole != _roles[DEFAULT_OWNERS_ROLE],
            string(
                abi.encodePacked(
                    "ofRole can not be '",
                    _rolesByIndex[ofRole].name.bytes32ToString(),
                    "'"
                )
            )
        );

        _manageRole(
            byRole,
            ofRole,
            canGrantRole,
            canRevokeRole,
            requireRole,
            maxAddresses,
            duration
        );

        _accountForOperation(
            OPERATION_MANAGE_ROLE << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function setTrustedForwarder(address forwarder) public override {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        require(
            !_isInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),
            "FORWARDER_CAN_NOT_BE_OWNER"
        );
        _setTrustedForwarder(forwarder);

        _accountForOperation(
            OPERATION_SET_TRUSTED_FORWARDER << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice setting tokenURI for role
     * @param roleIndex role index
     * @param roleURI token URI
     * @custom:shortd setting tokenURI for role
     * @custom:calledby any who can manage this role
     */
    function setRoleURI(uint8 roleIndex, string memory roleURI) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        _rolesByIndex[roleIndex].roleURI = roleURI;

        _accountForOperation(
            OPERATION_SET_ROLE_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    /**
     * @notice setting contract URI
     * @param uri contract URI
     * @custom:shortd setting contract URI.
     * @custom:calledby owners
     */
    function setContractURI(string memory uri) public {
        requireInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);

        _setContractURI(uri);

        _accountForOperation(
            OPERATION_SET_CONTRACT_URI << OPERATION_SHIFT_BITS,
            0,
            0
        );
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);

        _accountForOperation(
            OPERATION_TRANSFEROWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            uint160(newOwner)
        );
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
        // _functionDelegateCall(
        //     address(implCommunityState),
        //     msg.data
        // );

        _accountForOperation(
            OPERATION_RENOUNCEOWNERSHIP << OPERATION_SHIFT_BITS,
            uint160(_msgSender()),
            0
        );
    }

    ///////////////////////////////////////////////////////////
    /// public (view)section
    ///////////////////////////////////////////////////////////

    function invitedHook() public view returns (address) {
        return _invitedHook;
    }

    /**
     * @dev Returns the first address in getAddresses(OWNERS_ROLE). usually(if not transferownership/renounceownership) it's always will be deployer.
     * @return address first address on owners role list.
     */
    function owner() public view override returns (address) {
        return _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]].members.at(0);
    }

    /**
     * @dev Returns true if account is belong to DEFAULT_OWNERS_ROLE
     * @param account account address
     * @return bool
     */
    function isOwner(address account) public view returns (bool) {
        //hasRole(address, OWNERS_ROLE)
        return _isInRole(account, _roles[DEFAULT_OWNERS_ROLE]);
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses across all roles
     * @custom:shortd all addresses across all roles
     * @return two-dimensional array of addresses
     */
    function getAddresses() public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](rolesCount - 1);

        uint256 tmplen;
        for (uint8 j = 0; j < rolesCount - 1; j++) {
            tmplen = _rolesByIndex[j].members.length();
            l[j] = new address[](tmplen);
            for (uint256 i = 0; i < tmplen; i++) {
                l[j][i] = address(_rolesByIndex[j].members.at(i));
            }
        }
        return l;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param roleIndexes array of role's indexes
     * @return two-dimensional array of addresses
     */
    function getAddresses(
        uint8[] calldata roleIndexes
    ) public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](roleIndexes.length);
        if (roleIndexes.length != 0) {
            uint256 tmplen;
            for (uint256 j = 0; j < roleIndexes.length; j++) {
                tmplen = _rolesByIndex[roleIndexes[j]].members.length();
                l[j] = new address[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = address(
                        _rolesByIndex[roleIndexes[j]].members.at(i)
                    );
                }
            }
        }
        return l;
    }

    function getAddressesByRole(
        uint8 roleIndex,
        uint256 offset,
        uint256 limit
    ) public view returns (address[][] memory) {
        address[][] memory l;

        l = new address[][](1);
        uint256 j = 0;
        uint256 tmplen = _rolesByIndex[roleIndex].members.length();

        uint256 count = offset > tmplen
            ? 0
            : (limit > (tmplen - offset) ? (tmplen - offset) : limit);

        l[j] = new address[](count);
        uint256 k = 0;
        for (uint256 i = offset; i < offset + count; i++) {
            l[j][k] = address(_rolesByIndex[roleIndex].members.at(i));
            k++;
        }

        return l;

        /*
        if (page == 0 || count == 0) {
            revert IncorrectInputParameters();
        }

        uint256 len = specialPurchasesList.length();
        uint256 ifrom = page*count-count;

        if (
            len == 0 || 
            ifrom >= len
        ) {
            ret = new address[](0);
        } else {

            count = ifrom+count > len ? len-ifrom : count ;
            ret = new address[](count);

            for (uint256 i = ifrom; i<ifrom+count; i++) {
                ret[i-ifrom] = specialPurchasesList.at(i);
                
            }
        }
        */
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param accounts member's addresses
     * @return l two-dimensional array of roles
     */
    function getRoles(
        address[] memory accounts
    ) public view returns (uint8[][] memory) {
        uint8[][] memory l;

        l = new uint8[][](accounts.length);
        if (accounts.length != 0) {
            uint256 tmplen;
            for (uint256 j = 0; j < accounts.length; j++) {
                tmplen = _rolesByAddress[accounts[j]].length();
                l[j] = new uint8[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = _rolesByAddress[accounts[j]].get(i);
                }
            }
        }
        return l;
    }

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles
     * @custom:shortd all roles
     * @return arrays of (indexes, names, roleURIs)
     */
    function getRoles()
        public
        view
        returns (uint8[] memory, string[] memory, string[] memory)
    {
        uint8[] memory indexes = new uint8[](rolesCount - 1);
        string[] memory names = new string[](rolesCount - 1);
        string[] memory roleURIs = new string[](rolesCount - 1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i - 1] = i;
            names[i - 1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i - 1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);
    }

    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param roleIndex role index
     * @return count of members for that role
     */
    function addressesCount(uint8 roleIndex) public view returns (uint256) {
        return _rolesByIndex[roleIndex].members.length();
    }

    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all members count
     * @return count of members
     */
    function addressesCount() public view returns (uint256) {
        return addressesCounter;
    }

    /**
     * @notice is member has role
     * @custom:shortd checking is member belong to role
     * @param account user address
     * @param roleIndex role index
     * @return bool
     */
    function hasRole(
        address account,
        uint8 roleIndex
    ) public view returns (bool) {
        //require(_roles[rolename.stringToBytes32()] != 0, "Such role does not exists");
        return _rolesByAddress[account].contains(roleIndex);
    }

    /**
     * @notice return role index by name
     * @custom:shortd return role index by name
     * @param rolename role name in string
     * @return role index
     */
    function getRoleIndex(string memory rolename) public view returns (uint8) {
        return _roles[rolename.stringToBytes32()];
    }

    /**
     * @notice getting balance of owner address
     * @param account user's address
     * @custom:shortd part of ERC721
     */
    function balanceOf(
        address account
    ) public view override returns (uint256 balance) {
        for (uint8 i = 1; i < rolesCount; i++) {
            if (_isInRole(account, i)) {
                balance += 1;
            }
        }
    }

    /**
     * @notice getting owner of tokenId
     * @param tokenId tokenId
     * @custom:shortd part of ERC721
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        return (_isInRole(w, roleId)) ? w : address(0);
    }

    /**
     * @notice getting tokenURI(part of ERC721)
     * @custom:shortd getting tokenURI
     * @param tokenId token ID
     * @return tokenuri
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        //_rolesByIndex[_roles[role.stringToBytes32()]].roleURI = roleURI;
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        bytes memory bytesExtraURI = bytes(_rolesByIndex[roleId].extraURI[w]);

        if (bytesExtraURI.length != 0) {
            return _rolesByIndex[roleId].extraURI[w];
        } else {
            return _rolesByIndex[roleId].roleURI;
        }
    }

    /**
    * @dev output rolesindexes array only for that account will grant. 
    * for example: 
    roles array is ['role1','role2','role3','role4','some none exist role']. 
    Output can be like this [0,0,55,0,0]
    Means that account can grant only 'role3'
    */
    function getRolesWhichAccountCanGrant(
        address accountWhichWillGrant,
        //uint8 roleIndex
        string[] memory roleNames
    ) public view returns (uint8[] memory ret) {
        uint256 len = roleNames.length;
        ret = new uint8[](len);

        uint8 roleIndex;
        uint8[] memory rolesIndexesWhichWillGrant;
        uint8 roleIndexWhichCanGrant;
        for (uint256 i = 0; i < len; i++) {
            roleIndex = _roles[roleNames[i].stringToBytes32()];
            if (roleIndex != 0) {
                rolesIndexesWhichWillGrant = __rolesWhichCanGrant(
                    accountWhichWillGrant,
                    roleIndex
                );
                if (rolesIndexesWhichWillGrant.length != 0) {
                    (roleIndexWhichCanGrant, , ) = _getRoleWhichCanGrant(
                        rolesIndexesWhichWillGrant,
                        roleIndex
                    );
                    if (roleIndexWhichCanGrant != NONE_ROLE_INDEX) {
                        ret[i] = roleIndex;
                    }
                }
            }
        }
    }

    function getAuthorizedInviteManager() public view returns (address) {
        return defaultAuthorizedInviteManager;
    }

    ///////////////////////////////////////////////////////////
    /// internal section
    ///////////////////////////////////////////////////////////

    /**
     * @notice setting contractURI for this contract
     * @param uri uri
     * @custom:shortd setting tokenURI for role
     * @custom:calledby owners only
     */
    function _setContractURI(string memory uri) internal {
        contractURI = uri;
    }

    function _grantRoles(
        address accountWhichWillGrant,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) internal {
        // uint256 lengthAccounts = accounts.length;
        // uint256 lenRoles = roleIndexes.length;
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]);

            rolesIndexWhichWillGrant = _rolesWhichCanGrant(
                accountWhichWillGrant,
                roleIndexes[i],
                FlagFork.NONE
            );

            require(
                rolesIndexWhichWillGrant.length != 0,
                string(
                    abi.encodePacked(
                        "Sender can not grant role '",
                        _rolesByIndex[roleIndexes[i]].name.bytes32ToString(),
                        "'"
                    )
                )
            );

            roleIndexWhichWillGrant = validateGrantSettings(
                rolesIndexWhichWillGrant,
                roleIndexes[i],
                FlagFork.REVERT
            );

            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(
                    roleIndexWhichWillGrant,
                    accountWhichWillGrant,
                    roleIndexes[i],
                    accounts[j]
                );
            }
        }
    }

    function _revokeRoles(
        address accountWhichWillRevoke,
        address[] memory accounts,
        uint8[] memory roleIndexes
    ) internal {
        uint8 roleWhichWillRevoke;

        for (uint256 i = 0; i < roleIndexes.length; i++) {
            _isRoleValid(roleIndexes[i]);

            roleWhichWillRevoke = NONE_ROLE_INDEX;
            if (
                _isInRole(accountWhichWillRevoke, _roles[DEFAULT_OWNERS_ROLE])
            ) {
                // owner can do anything. so no need to calculate or loop
                roleWhichWillRevoke = _roles[DEFAULT_OWNERS_ROLE];
            } else {
                for (
                    uint256 j = 0;
                    j < _rolesByAddress[accountWhichWillRevoke].length();
                    j++
                ) {
                    if (
                        _rolesByIndex[
                            uint8(
                                _rolesByAddress[accountWhichWillRevoke].get(j)
                            )
                        ].canRevokeRoles.contains(roleIndexes[i]) == true
                    ) {
                        roleWhichWillRevoke = _rolesByAddress[
                            accountWhichWillRevoke
                        ].get(j);
                        break;
                    }
                }
            }
            require(
                roleWhichWillRevoke != NONE_ROLE_INDEX,
                string(
                    abi.encodePacked(
                        "Sender can not revoke role '",
                        _rolesByIndex[roleIndexes[i]].name.bytes32ToString(),
                        "'"
                    )
                )
            );
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(
                    /*roleWhichWillRevoke, */ accountWhichWillRevoke,
                    roleIndexes[i],
                    accounts[k]
                );
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
            EnumerableSetUpgradeable.AddressSet
                storage ownersList = _rolesByIndex[_roles[DEFAULT_OWNERS_ROLE]]
                    .members;
            uint256 len = ownersList.length();
            // loop through stack, due to reducing members in role, we just get address from zero position `len` times
            for (uint256 i = 0; i < len; i++) {
                _revokeRole(
                    sender,
                    _roles[DEFAULT_OWNERS_ROLE],
                    ownersList.at(0)
                );
            }
            emit RenounceOwnership();
        } else {
            _grantRole(
                _roles[DEFAULT_OWNERS_ROLE],
                sender,
                _roles[DEFAULT_OWNERS_ROLE],
                newOwner
            );
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
    ) internal returns (uint8) {
        uint8 roleWhichCanGrant;
        bool increaseCounter;
        uint64 newInterval;

        (
            roleWhichCanGrant,
            increaseCounter,
            newInterval
        ) = _getRoleWhichCanGrant(rolesWhichCanGrant, roleIndex);

        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(
                    _msgSender(),
                    "Max amount addresses exceeded"
                );
            }
        } else {
            if (increaseCounter) {
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .grantedAddressesCounter += 1;
            }
            if (newInterval != 0) {
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .lastIntervalIndex = newInterval;
                _rolesByIndex[roleWhichCanGrant]
                    .grantSettings[roleIndex]
                    .grantedAddressesCounter = 0;
            }
        }

        return roleWhichCanGrant;
    }

    /**
     * @notice is role can be granted by sender's roles?
     * @param sender sender
     * @param targetRoleIndex role index
     */
    function requireCanGrant(address sender, uint8 targetRoleIndex) internal {
        _rolesWhichCanGrant(sender, targetRoleIndex, FlagFork.REVERT);
    }

    /**
     * @param role role name
     */
    function _createRole(bytes32 role) internal {
        _roles[role] = rolesCount;
        _rolesByIndex[rolesCount].name = role;
        rolesCount += 1;

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
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
    ) internal {
        if (_rolesByAddress[targetAccount].length() == 0) {
            addressesCounter++;
        }

        _rolesByAddress[targetAccount].add(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.add(targetAccount);

        grantedBy[targetAccount].push(
            ActionInfo({
                actor: sourceAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );
        granted[sourceAccount].push(
            ActionInfo({
                actor: targetAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );

        _rolesByIndex[sourceRoleIndex]
            .grantSettings[targetRoleIndex]
            .grantedAddressesCounter += 1;

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
                ICommunityHook(hook).roleGranted(
                    _rolesByIndex[targetRoleIndex].name,
                    targetRoleIndex,
                    targetAccount
                );
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleGranted(
            _rolesByIndex[targetRoleIndex].name,
            targetAccount,
            sourceAccount
        );
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
        address targetAccount //address account, bytes32 targetRole
    ) internal {
        _rolesByAddress[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);

        if (
            _rolesByAddress[targetAccount].length() == 0 &&
            addressesCounter != 0
        ) {
            addressesCounter--;
        }

        revokedBy[targetAccount].push(
            ActionInfo({
                actor: sourceAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );
        revoked[sourceAccount].push(
            ActionInfo({
                actor: targetAccount,
                timestamp: uint64(block.timestamp),
                extra: uint32(targetRoleIndex)
            })
        );

        if (hook != address(0)) {
            try
                ICommunityHook(hook).supportsInterface(
                    type(ICommunityHook).interfaceId
                )
            returns (bool) {
                ICommunityHook(hook).roleRevoked(
                    _rolesByIndex[targetRoleIndex].name,
                    targetRoleIndex,
                    targetAccount
                );
            } catch {
                revert("wrong interface");
            }
        }
        emit RoleRevoked(
            _rolesByIndex[targetRoleIndex].name,
            targetAccount,
            sourceAccount
        );
    }

    function _rolesWhichCanGrant(
        address sender,
        uint8 targetRoleIndex,
        FlagFork flag
    ) internal returns (uint8[] memory rolesWhichCan) {
        rolesWhichCan = __rolesWhichCanGrant(sender, targetRoleIndex);

        if (rolesWhichCan.length == 0) {
            string memory errMsg = string(
                abi.encodePacked(
                    "Sender can not grant account with role '",
                    _rolesByIndex[targetRoleIndex].name.bytes32ToString(),
                    "'"
                )
            );
            if (flag == FlagFork.REVERT) {
                revert(errMsg);
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(sender, errMsg);
            }
        }
    }

    ///////////////////////////////////////////////////////////
    /// internal section that are view
    ///////////////////////////////////////////////////////////

    function _isInRole(
        address target,
        uint8 targetRoleIndex
    ) internal view returns (bool) {
        return _rolesByAddress[target].contains(targetRoleIndex);
    }

    /**
     * @dev Throws if the sender is not in the DEFAULT_OWNERS_ROLE.
     */
    function _checkOwner() internal view override {
        require(
            _isInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]),
            "Ownable: caller is not the owner"
        );
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, TrustedForwarder)
        returns (address)
    {
        return TrustedForwarder._msgSender();
    }

    function _getRoleWhichCanGrant(
        uint8[] memory rolesWhichCanGrant,
        uint8 roleIndex
    )
        internal
        view
        returns (
            uint8 roleWhichCanGrant,
            bool increaseCounter,
            uint64 newInterval
        )
    {
        roleWhichCanGrant = NONE_ROLE_INDEX;

        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if (
                (_rolesByIndex[rolesWhichCanGrant[i]]
                    .grantSettings[roleIndex]
                    .maxAddresses == 0)
            ) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (
                    _rolesByIndex[rolesWhichCanGrant[i]]
                        .grantSettings[roleIndex]
                        .duration == 0
                ) {
                    if (
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .grantedAddressesCounter +
                            1 <=
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .maxAddresses
                    ) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                    }
                } else {
                    // get current interval index
                    uint64 interval = (uint64(block.timestamp) /
                        (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .duration
                        )) *
                        (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .duration
                        );
                    if (
                        interval ==
                        _rolesByIndex[rolesWhichCanGrant[i]]
                            .grantSettings[roleIndex]
                            .lastIntervalIndex
                    ) {
                        if (
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .grantedAddressesCounter +
                                1 <=
                            _rolesByIndex[rolesWhichCanGrant[i]]
                                .grantSettings[roleIndex]
                                .maxAddresses
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

    function __rolesWhichCanGrant(
        address sender,
        uint8 targetRoleIndex
    ) internal view returns (uint8[] memory) {
        //uint256 targetRoleID = uint256(targetRoleIndex);

        uint256 iLen;
        uint8[] memory rolesWhichCan;

        if (_isInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
            // owner can do anything. so no need to calculate or loop
            rolesWhichCan = new uint8[](1);
            rolesWhichCan[0] = _roles[DEFAULT_OWNERS_ROLE];
        } else {
            iLen = 0;
            for (uint256 i = 0; i < _rolesByAddress[sender].length(); i++) {
                if (
                    _rolesByIndex[uint8(_rolesByAddress[sender].get(i))]
                        .canGrantRoles
                        .contains(targetRoleIndex) == true
                ) {
                    iLen++;
                }
            }

            rolesWhichCan = new uint8[](iLen);

            iLen = 0;
            for (uint256 i = 0; i < _rolesByAddress[sender].length(); i++) {
                if (
                    _rolesByIndex[uint8(_rolesByAddress[sender].get(i))]
                        .canGrantRoles
                        .contains(targetRoleIndex) == true
                ) {
                    rolesWhichCan[iLen] = _rolesByAddress[sender].get(i);
                    iLen++;
                }
            }
        }

        return rolesWhichCan;
    }

    /**
     * @notice does address belong to role
     * @param target address
     * @param targetRoleIndex role index
     */
    function requireInRole(
        address target,
        uint8 targetRoleIndex
    ) internal view {
        require(
            _isInRole(target, targetRoleIndex),
            string(
                abi.encodePacked(
                    "Missing role '",
                    _rolesByIndex[targetRoleIndex].name.bytes32ToString(),
                    "'"
                )
            )
        );
    }

    function _isRoleValid(uint8 index) internal view {
        require((rolesCount > index), "invalid role");
    }

    function requireAuthorizedManager() internal view {
        if (_msgSender() != defaultAuthorizedInviteManager) {
            revert AuthorizedInviteManagerOnly();
        }
    }

    //////////////////////////////////////
    /**
     * @notice
     * @custom:shortd
     */
    function operationReverted() internal pure {
        revert("CommunityContract: NOT_AUTHORIZED");
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function approve(
        address /*to*/,
        uint256 /*tokenId*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function getApproved(
        uint256 /* tokenId*/
    ) external pure override returns (address /* operator*/) {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function setApprovalForAll(
        address /*operator*/,
        bool /*_approved*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function isApprovedForAll(
        address /*owner*/,
        address /*operator*/
    ) external pure override returns (bool) {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override {
        operationReverted();
    }

    /**
     * @notice getting part of ERC721
     * @custom:shortd part of ERC721
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    ////////////////////////////////////////////
}
