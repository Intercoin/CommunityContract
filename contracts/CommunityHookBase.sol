// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/ICommunityHook.sol";

/**
 * @title CommunityHookBase
 * @dev Base contract that implements the ICommunityHook interface
 */
abstract contract CommunityHookBase is ICommunityHook {

    /**
     * @dev Returns true if `interfaceId` is equal to the interface identifier
     * of the `ICommunityHook` interface.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(ICommunityHook).interfaceId;
    }
}
