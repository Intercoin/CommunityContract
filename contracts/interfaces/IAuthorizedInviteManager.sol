// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAuthorizedInviteManager {
    struct inviteSignature {
        bytes aSig;
        bytes rSig;
        bool used;
        bool exists;
    }

    struct inviteReserveStruct {
        address sender;
        uint64 timestamp;
    }

    function initialize(address costManager) external;

    function inviteReserve(bytes32 hash) external;

    /**
     * @notice registering invite,. calling by relayers
     * @custom:shortd registering invite
     * @param aSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(bytes memory aSig, bytes memory rSig) external;

    /**
     * @dev
     * @dev ==P==
     * @dev format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<chain id>:<deadline in unixtimestamp>:<some string data>"
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:1:1698916962:GregMagarshak
     * @dev ==R==
     * @dev format is "<address of R wallet>:<name of user>"
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe
     * @notice accepting invite
     * @custom:shortd accepting invite
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
    ) external;

    /**
     * @notice viewing invite by admin signature
     * @custom:shortd viewing invite by admin signature
     * @param aSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory aSig
    ) external view returns (inviteSignature memory);
}
