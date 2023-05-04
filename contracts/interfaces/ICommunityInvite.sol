// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICommunityInvite {
    function getAuthorizedInviteManager() external view returns(address);
    function grantRolesExternal(address accountWhichWillGrant, address[] memory accounts, uint8[] memory roleIndexes) external;
    function revokeRolesExternal(address accountWhichWillRevoke, address[] memory accounts, uint8[] memory roleIndexes) external;
}