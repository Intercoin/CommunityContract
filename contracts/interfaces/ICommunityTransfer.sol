// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
* @title interface helps to transfer owners from factory to sender that produce instance
*/
interface ICommunityTransfer {
    function addMembers(address[] memory members) external;
    function grantRoles(address[] memory members, string[] memory roles) external;
}