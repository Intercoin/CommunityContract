// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommunityStorage.sol";

//import "hardhat/console.sol";

contract CommunityView is CommunityStorage {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;    

    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////
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
    
    

    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////
    /**
     * @dev since user will be in several roles then addresses in output can be duplicated.
     * @notice Returns all addresses belong to Role
     * @custom:shortd all addresses belong to Role
     * @param rolesIndexes array of roles indexes
     * @return array of array addresses ([uint256][uint160(address)])
     */
    function getAddresses(uint8[] memory rolesIndexes) public view returns(uint256[][] memory) {
        uint256[][] memory l;

        l = new uint256[][](rolesIndexes.length);
        if (rolesIndexes.length != 0) {
            
            uint256 tmplen;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                tmplen = _rolesByIndex[rolesIndexes[j]].members.length();
                l[j] = new uint256[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = uint160(_rolesByIndex[rolesIndexes[j]].members.at(i));
                }
            }
        }
        return l;
    }
    
    /**
     * @dev can be duplicate items in output. see https://github.com/Intercoin/CommunityContract/issues/4#issuecomment-1049797389
     * @notice Returns all roles which member belong to
     * @custom:shortd account's roles
     * @param accounts account's addresses
     * @return l array of roles 
     */
    function getRoles(address[] memory accounts) public view returns(uint256[][] memory) {
        uint256[][] memory l;

        l = new uint256[][](accounts.length);
        if (accounts.length != 0) {
        
            uint256 tmplen;
            for (uint256 j = 0; j < accounts.length; j++) {
                tmplen = _rolesByMember[accounts[j]].length();
                l[j] = new uint256[](tmplen);
                for (uint256 i = 0; i < tmplen; i++) {
                    l[j][i] = _rolesByMember[accounts[j]].get(i);

                }
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
     * @notice count of accounts for that role
     * @custom:shortd count of accounts for role
     * @param roleIndex role index
     * @return count of accounts for that role
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
     * @custom:shortd all accounts count
     * @return count of accounts
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

}
    