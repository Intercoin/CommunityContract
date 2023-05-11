// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAuthorizedInvitedHook is IERC165 {
    function onInviteAccepted(
        address inviteManager, 
        address accountWhichInitiated, 
        address accountWhichWillGrant, 
        address[] memory accounts, 
        uint8[] memory roleIndexes
    ) external;
}