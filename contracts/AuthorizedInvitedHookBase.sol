// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IAuthorizedInvitedHook.sol";

/**
 * @title AuthorizedInvitedHookBase
 * @dev Base contract that implements the IAuthorizedInvitedHook interface
 */
abstract contract AuthorizedInvitedHookBase is IAuthorizedInvitedHook {
    /**
     * @dev Returns true if `interfaceId` is equal to the interface identifier
     * of the `IAuthorizedInvitedHook` interface.
     *
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IAuthorizedInvitedHook).interfaceId;
    }
}
