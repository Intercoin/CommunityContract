// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./lib/StringUtils.sol";
import "./lib/ECDSAExt.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ICommunityInvite.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/IAuthorizedInviteManager.sol";
import "./interfaces/IAuthorizedInvitedHook.sol";

import "@intercoin/releasemanager/contracts/CostManagerHelper.sol";
import "@intercoin/releasemanager/contracts/ReleaseManagerHelper.sol";
import "@intercoin/releasemanager/contracts/interfaces/IReleaseManager.sol";
import "@intercoin/trustedforwarder/contracts/TrustedForwarder.sol";
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

/**
 * @title AuthorizedInviteManager
 * @dev This contract allows community admins to generate invite signatures, and for users to use these signatures to join the community.
 */
contract AuthorizedInviteManager is
    IAuthorizedInviteManager,
    Initializable,
    ReentrancyGuardUpgradeable,
    CostManagerHelper
{
    using StringUtils for *;
    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    // Time delay for invite reservation
    uint64 public constant RESERVE_DELAY = 10 minutes;

    // Mapping of reserved invites
    mapping(bytes32 => inviteReserveStruct) inviteReserved;

    // Mapping of invite signatures to invite information
    mapping(bytes => inviteSignature) inviteSignatures;

    // Index representing no role
    uint8 internal constant NONE_ROLE_INDEX = 0;

    // Number of bits to shift operations in the event payload
    uint8 internal constant OPERATION_SHIFT_BITS = 240; // 256 - 16

    // Constants representing specific operations for the event payload
    uint8 internal constant OPERATION_INITIALIZE = 0x0;

    // Event emitted when an error occurs while adding a role
    event RoleAddedErrorMessage(address indexed sender, string msg);

    /**
     * @notice Initializes the contract.
     * @param costManager_ The address of the cost manager contract.
     */
    function initialize(address costManager_) public override initializer {
        __CostManagerHelper_init(msg.sender);
        _setCostManager(costManager_);

        __ReentrancyGuard_init();

        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(costManager_)),
            0
        );
    }

    /**
     * @notice This function allows the contract owner to receive Ether.
     */
    receive() external payable {}

    /**
     * @notice Reserves an invite signature hash.
     * @dev The hash will be reserved for RESERVE_DELAY minutes before it can be used.
     * @param hash The hash to reserve.
     */
    function inviteReserve(bytes32 hash) external {
        require(inviteReserved[hash].timestamp == 0, "Already reserved");
        inviteReserved[hash].timestamp = uint64(block.timestamp);
        inviteReserved[hash].sender = msg.sender;
    }

    /**
     * @notice registering invite, calling by relayers
     * @param aSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(bytes memory aSig, bytes memory rSig) external {
        bytes32 reverveHash = getInviteReservedHash(aSig, rSig);
        bool isReserved = inviteReserved[reverveHash].timestamp != 0
            ? true
            : false;

        if (isReserved) {
            require(
                inviteReserved[reverveHash].timestamp + RESERVE_DELAY <=
                    block.timestamp,
                "Invite still reserved"
            );
        }

        require(
            inviteSignatures[aSig].exists == false,
            "Such signature is already exists"
        );
        inviteSignatures[aSig].aSig = aSig;
        inviteSignatures[aSig].rSig = rSig;
        inviteSignatures[aSig].used = false;
        inviteSignatures[aSig].exists = true;
    }

    /**
     * @dev
     * @dev ==P==
     * @dev format is "<some string data>:<address of communityContract>:<array of role names (sep=',')>:<chain id>:<deadline in unixtimestamp>:<some string data>"
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:1:1698916962:GregMagarshak
     * @dev ==R==
     * @dev format is "<address of R wallet>:<name of user>"
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe
     *
     * @notice Accepts an invite by recovering addresses from signatures and checking if the invite is valid,
     * then adds roles to the account if it has permission to do so.
     *
     * @param p invite message of admin whom generate messageHash and signed it
     * @param aSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function inviteAccept(
        string memory p,
        bytes memory aSig,
        string memory rp,
        bytes memory rSig 
    ) external {
        // Ensure that the signature has not been used before
        inviteSignature storage signature = inviteSignatures[aSig];
        require(signature.used == false, "Such signature is already used");

        // Recover addresses from signatures
        address pAddr = p.recreateMessageHash().recover(aSig);
        address rpAddr = rp.recreateMessageHash().recover(rSig);

        // Parse data from payloads
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");

        // Get the current chain ID
        uint256 chainId;

        // Second way to get directly from block.chainId. since Istanbul version
        assembly {
            chainId := chainid()
        }

        // Get the destination community address from the signed payload
        address communityDestination = dataArr[1].parseAddr();

        // Check if the current contract is authorized to manage invites for the community
        // and the community instance exists
        // 
        // release manager should be verifing
        // deployer - it's factory
        address releaseManagerAddr = ReleaseManagerHelper(deployer).releaseManager();
        bool isCommunityVerifying = IReleaseManager(releaseManagerAddr).checkInstance(communityDestination);

        // and ICommunityInvite(communityDestination).getAuthorizedInviteManager() != address(this) ||
        isCommunityVerifying = (isCommunityVerifying)
            ? ICommunityInvite(communityDestination)
                .getAuthorizedInviteManager() == address(this)
            : false;

        // Ensure that all conditions for the invite are met
        if (
            pAddr == address(0) ||
            rpAddr == address(0) ||
            keccak256(abi.encode(signature.rSig)) != keccak256(abi.encode(rSig)) ||
            rpDataArr[0].parseAddr() != rpAddr ||
            !isCommunityVerifying ||
            keccak256(abi.encode(str2num(dataArr[3]))) != keccak256(abi.encode(chainId)) ||
            str2num(dataArr[4]) < block.timestamp
        ) {
            revert("Signature are mismatch");
        }

        // Get the indexes of roles that the inviting user can grant to others
        uint8[] memory rolesIndexesTmp = ICommunity(communityDestination).getRolesWhichAccountCanGrant(pAddr, rolesArr);

        // Count the number of non-empty role indexes
        uint256 len;
        for (uint256 i = 0; i < rolesIndexesTmp.length; i++) {
            if (rolesIndexesTmp[i] != NONE_ROLE_INDEX) {
                emit RoleAddedErrorMessage(
                    msg.sender,
                    string(
                        abi.encodePacked(
                            "inviting user did not have permission to add role '",
                            rolesArr[i],
                            "'"
                        )
                    )
                );
                len++;
            }
        }

        // Ensure that at least one role can be added
        if (len == 0) {
            revert("Can not add no one role");
        }

        // Mark the signature as used
        signature.used = true;

        // Add roles to the account
        inviteAcceptPart2(
            pAddr,
            rpAddr,
            communityDestination,
            rolesIndexesTmp,
            len
        );
    }
    
    /**
    * @notice Helper function for `inviteAccept`, responsible for granting roles to the user
    * @param pAddr The address of the user on whose behalf the roles will be granted
    * @param rpAddr The address of the user who will be granted roles
    * @param communityDestination The address of the community instance
    * @param rolesIndexesTmp An array of role indexes for the roles the user will be granted `rpAddr`
    * @param len The length of the `rolesIndexesTmp` array
    */
    function inviteAcceptPart2(
        address pAddr,
        address rpAddr,
        address communityDestination,
        uint8[] memory rolesIndexesTmp,
        uint256 len
    ) private {
        address[] memory accounts = new address[](len);
        uint8[] memory roleIndexes = new uint8[](len);
        uint256 j = 0;
        for (uint256 i = 0; i < rolesIndexesTmp.length; i++) {
            if (rolesIndexesTmp[i] != NONE_ROLE_INDEX) {
                accounts[j] = rpAddr;
                roleIndexes[j] = rolesIndexesTmp[i];
                j++;
            }
        }
        ICommunityInvite(communityDestination).grantRolesExternal(
            pAddr,
            accounts,
            roleIndexes
        );

        address hook = ICommunityInvite(communityDestination).invitedHook();
        if (hook != address(0)) {
            try
                IAuthorizedInvitedHook(hook).supportsInterface(
                    type(IAuthorizedInvitedHook).interfaceId
                )
            returns (bool) {
                IAuthorizedInvitedHook(hook).onInviteAccepted(
                    address(this), //address inviteManager,
                    msg.sender, //address accountWhichInitiated,
                    pAddr, //address accountWhichWillGrant,
                    accounts, //address[] memory accounts,
                    roleIndexes //uint8[] memory roleIndexes
                );
            } catch {
                revert("wrong interface");
            }
        }
    }

    /**
     * @notice view an invite by the admin signature
     * @param aSig signature of the admin who generated and signed the invite
     * @return inviteSignature structure containing information about the invite
     */
    function inviteView(
        bytes memory aSig
    ) public view returns (inviteSignature memory) {
        return inviteSignatures[aSig];
    }

    /**
     * @notice Computes and returns the hash of an invite's reserved signature
     * @param aSig The signature of the admin who generated and signed the invite
     * @param rSig The signature of the user who received the invite and will sign own message later
     * @return The hash of the invite's reserved signature
     */
    function getInviteReservedHash(
        bytes memory aSig,
        bytes memory rSig
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(aSig, rSig));
    }

    /**
     * @notice Converts a string representation of a number to its corresponding uint256 value.
     * @param numString The string representation of the number.
     * @return The uint256 value of the number.
     */
    function str2num(string memory numString) private pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10 ** (exp - 1)));
        }
        return val;
    }
}
