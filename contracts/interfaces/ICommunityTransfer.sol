// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
interface ICommunityTransfer {
    function grantRoles(address[] memory accounts, uint8[] memory rolesIndexes) external; }
