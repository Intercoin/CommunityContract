// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStorage.sol";

//import "hardhat/console.sol";

contract CommunityView is CommunityStorage {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;    

    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param rolesIndexes array of roles indexes
     * @return array of address 
     */
    function getAddresses(
        uint8[] memory rolesIndexes
    ) 
        public 
        view
        returns(address[] memory)
    {
        address[] memory l;

        if (rolesIndexes.length == 0) {
            l = new address[](0);
        } else {
            uint256 len;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                len += _rolesByIndex[rolesIndexes[j]].members.length();
            }

            l = new address[](len);
            
            uint256 ilen;
            uint256 tmplen;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                tmplen = _rolesByIndex[rolesIndexes[j]].members.length();
                for (uint256 i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[rolesIndexes[j]].members.at(i);
                    ilen += 1;
                }
            }
        }
        return l;
    }
    
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd member's roles
     * @param members member's addresses
     * @return l array of roles 
     */
    function getRoles(
        address[] memory members
    ) 
        public 
        view
        returns(uint8[] memory)
    {
        uint8[] memory l;

        uint256 len;
        uint256 tmplen;

            for (uint256 j = 0; j < members.length; j++) {
                tmplen = _rolesByMember[members[j]].length();
                len += tmplen;
            }

            l = new uint8[](len);
            
            uint256 ilen;
            for (uint256 j = 0; j < members.length; j++) {
                uint256 i;

                tmplen = _rolesByMember[members[j]].length();

                for (i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByMember[members[j]].get(i);
                    ilen += 1;
                }
            }

        return l;
    }
  
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice if call without params then returns all existing roles 
     * @custom:shortd all roles
     * @return array of roles 
     */
    function getRoles(
    ) 
        public 
        view
        returns(uint8[] memory, string[] memory, string[] memory)
    {
        uint8[] memory indexes = new uint8[](rolesCount-1);
        string[] memory names = new string[](rolesCount-1);
        string[] memory roleURIs = new string[](rolesCount-1);
        // rolesCount start from 1
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i-1] = i-1;
            names[i-1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i-1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);
    }
    
    /**
     * @notice count of members for that role
     * @custom:shortd count of members for role
     * @param roleIndex role index
     * @return count of members for that role
     */
    function addressesCount(
        uint8 roleIndex
    )
        public
        view
        returns(uint256)
    {
        return _rolesByIndex[roleIndex].members.length();
    }
        
    /**
     * @notice if call without params then returns count of all users which have at least one role
     * @custom:shortd all members count
     * @return count of members
     */
    function addressesCount(
    )
        public
        view
        returns(uint256)
    {
        return addressesCounter;
    }
    
    /**
     * @notice viewing invite by admin signature
     * @custom:shortd viewing invite by admin signature
     * @param sSig signature of admin whom generate invite and signed it
     * @return structure inviteSignature
     */
    function inviteView(
        bytes memory sSig
    ) 
        public 
        view
        returns(inviteSignature memory)
    {
        return inviteSignatures[sSig];
    }
    

    /**
     * @notice is member has role
     * @custom:shortd checking is member belong to role
     * @param account user address
     * @param rolename role name
     * @return bool 
     */
    //function isMemberHasRole(
    function isAccountHasRole(
        address account, 
        string memory rolename
    ) 
        public 
        view 
        returns(bool) 
    {

        //require(_roles[rolename.stringToBytes32()] != 0, "Such role does not exists");

        return _rolesByMember[account].contains(_roles[rolename.stringToBytes32()]);

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
}
    