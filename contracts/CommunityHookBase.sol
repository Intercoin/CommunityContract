// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./interfaces/ICommunityHook.sol";
abstract contract CommunityHookBase is ICommunityHook {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {return interfaceId == type(ICommunityHook).interfaceId;}
}
