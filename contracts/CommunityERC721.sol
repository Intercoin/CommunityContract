// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "./CommunityBase.sol";
import "./interfaces/ICommunityERC721.sol";

contract CommunityERC721 is CommunityBase, IERC721Upgradeable, IERC721MetadataUpgradeable, ICommunityERC721 {
   
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
    * @param roleIndex role index
    * @param roleURI token URI
    * @custom:shortd setting tokenURI for role
    * @custom:calledby any who can manage this role
    */
    function setRoleURI(
        uint8 roleIndex,
        string memory roleURI
    ) 
        public 
        
    {
        ifCanGrant(_msgSender(), roleIndex);
        _rolesByIndex[roleIndex].roleURI = roleURI;
    }

    /**
    * @notice setting extraURI for role.
    * @param roleIndex role index
    * @param extraURI extra token URI. user can set custom uri for himself
    * @custom:calledby any who belong to role
    */
    function setExtraURI(
        uint8 roleIndex,
        string memory extraURI
    )
        public
        
    {
        ifTargetInRole(_msgSender(), roleIndex);
        _rolesByIndex[roleIndex].extraURI[_msgSender()] = extraURI;
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
        
        for (uint8 i = 1; i < rolesCount; i++) {
            if (_isTargetInRole(account, i)) {
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
        
        owner = (_isTargetInRole(w, roleId)) ? w : address(0);

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
        pure 
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
        pure 
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
        //_rolesByIndex[_roles[role.stringToBytes32()]].roleURI = roleURI;
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));

        bytes memory bytesExtraURI = bytes(_rolesByIndex[roleId].extraURI[w]);

        if (bytesExtraURI.length != 0) {
            return _rolesByIndex[roleId].extraURI[w];
        } else {
            return _rolesByIndex[roleId].roleURI;
        }
        
    }

    /**
    * @param hook address of contract implemented ICommunityHook interface. Can be address(0)
    * @param name_ erc721 name
    * @param symbol_ erc721 symbol
    */
    function init(
        address hook,
        string memory name_, 
        string memory symbol_
    ) 
        external 
        initializer 
    {
        name = name_;
        symbol = symbol_;

        __CommunityBase_init(hook);
    }

}