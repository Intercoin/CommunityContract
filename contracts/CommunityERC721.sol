// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "./CommunityBase.sol";
import "./interfaces/ICommunityERC721.sol";

contract CommunityERC721 is CommunityBase, IERC721Upgradeable, IERC721MetadataUpgradeable, ICommunityERC721 {
    using StringUtils for *;

    /**
    * @notice getting name
    * @custom:shortd ERC721'name
    * @return name 
    */
    string public name;
    
    /**
    * @notice getting symbol
    * @custom:shortd ERC721's symbol
    * @return symbol 
    */
    string public symbol;

    /**
    * @notice setting tokenURI for role
    * @param role role name
    * @param roleURI token URI
    * @custom:shortd setting tokenURI for role
    * @custom:calledby any who can manage this role
    */
    function setRoleURI(
        string memory role,
        string memory roleURI
    ) 
        public 
        canManage(msg.sender, role.stringToBytes32())
    {
        _rolesIndices[_roles[role.stringToBytes32()]].roleURI = roleURI;
    }

    /**
    * @notice setting extraURI for role.
    * @custom:calledby any who belong to role
    */
    function setExtraURI(
        string memory role,
        string memory extraURI
    )
        public
        ifTargetInRole(msg.sender, role.stringToBytes32())
    {
        _rolesIndices[_roles[role.stringToBytes32()]].extraURI[msg.sender] = extraURI;
    }

    /**
    * @notice getting balance of owner address
    * @param account user's address
    * @custom:shortd part of ERC721
    */
    function balanceOf(
        address account
    ) 
        external 
        view 
        override
        returns (uint256 balance) 
    {
        
        for (uint8 i = 1; i < rolesIndex; i++) {
            if (_isTargetInRole(account, _rolesIndices[i].name)) {
                balance += 1;
            }
        }
    }

    /**
    * @notice getting owner of tokenId
    * @param tokenId tokenId
    * @custom:shortd part of ERC721
    */
    function ownerOf(
        uint256 tokenId
    ) 
        external 
        view 
        override
        returns (address owner) 
    {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));
        
        owner = (_isTargetInRole(w, _rolesIndices[roleId].name)) ? w : address(0);

    }

    /**
    * @notice 
    * @custom:shortd 
    */
    function operationReverted(
    ) 
        internal 
        pure
    {
        revert("CommunityContract: NOT_AUTHORIZED");
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function transferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }
    
    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function approve(
        address /*to*/, 
        uint256 /*tokenId*/
    )
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function getApproved(
        uint256/* tokenId*/
    ) 
        external
        view 
        override 
        returns (address/* operator*/) 
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function setApprovalForAll(
        address /*operator*/, 
        bool /*_approved*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function isApprovedForAll(
        address /*owner*/, 
        address /*operator*/
    ) 
        external 
        view 
        override
        returns (bool) 
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) 
        external 
        pure
        override
    {
        operationReverted();
    }

    /**
    * @notice getting part of ERC721
    * @custom:shortd part of ERC721
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
    * @notice getting tokenURI(part of ERC721)
    * @custom:shortd getting tokenURI
    * @param tokenId token ID
    * @return tokenuri
    */
    function tokenURI(
        uint256 tokenId
    ) 
        external 
        view 
        override 
        returns (string memory)
    {

        //_rolesIndices[_roles[role.stringToBytes32()]].roleURI = roleURI;
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        bytes memory bytesExtraURI = bytes(_rolesIndices[roleId].extraURI[w]);

        if (bytesExtraURI.length != 0) {
            return _rolesIndices[roleId].extraURI[w];
        } else {
            return _rolesIndices[roleId].roleURI;
        }
        
    }

    /**
    * @param name_ erc721 name
    * @param symbol_ erc721 symbol
    */
    function init(
        string memory name_, 
        string memory symbol_
    ) 
        external 
        initializer 
    {
        name = name_;
        symbol = symbol_;

        __CommunityBase_init();
    }

}