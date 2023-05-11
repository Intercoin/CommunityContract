// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../CommunityHookBase.sol";

contract CommunityHook is CommunityHookBase {
    uint256 public roleGrantedExecuted = 0;
    uint256 public roleRevokedExecuted = 0;
    uint256 public roleCreatedExecuted = 0;

    function roleGranted(
        bytes32 role,
        uint8 roleIndex,
        address account
    ) external {
        roleGrantedExecuted++;
    }

    function roleRevoked(
        bytes32 role,
        uint8 roleIndex,
        address account
    ) external {
        roleRevokedExecuted++;
    }

    function roleCreated(bytes32 role, uint8 roleIndex) external {
        roleCreatedExecuted++;
    }
}
