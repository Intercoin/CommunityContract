// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IAuthorizedInvitedHook.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract AuthorizedInvitedHookBase is IAuthorizedInvitedHook {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IAuthorizedInvitedHook).interfaceId;
    }
}
