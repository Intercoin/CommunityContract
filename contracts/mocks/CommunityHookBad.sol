// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../CommunityHookBase.sol";

contract CommunityHookBad is CommunityHookBase {
    
    bool public throwInRoleGrantedExecuted = false;
    bool public throwInRevokedExecuted = false;
    bool public throwInCreatedExecuted = false;

    function set(
        bool throwInRoleGrantedExecuted_,
        bool throwInRevokedExecuted_,
        bool throwInCreatedExecuted_
    ) public  {
        throwInRoleGrantedExecuted = throwInRoleGrantedExecuted_;
        throwInRevokedExecuted = throwInRevokedExecuted_;
        throwInCreatedExecuted = throwInCreatedExecuted_;
    }
    function roleGranted(bytes32 role, uint8 roleIndex, address account) external {
        if (throwInRoleGrantedExecuted) {revert("error in granted hook");}
    }
    function roleRevoked(bytes32 role, uint8 roleIndex, address account) external {
        if (throwInRevokedExecuted) {revert("error in revoked hook");}
    }
    function roleCreated(bytes32 role, uint8 roleIndex) external {
        if (throwInCreatedExecuted) {revert("error in created hook");}
    }
    
}
