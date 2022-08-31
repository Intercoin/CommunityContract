// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./CommunityStorage.sol";
contract CommunityView is CommunityStorage {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;    
    function balanceOf(address account) external view override returns (uint256 balance) {
        for (uint8 i = 1; i < rolesCount; i++) {
            if (_isTargetInRole(account, i)) {
                balance += 1;}}}
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));
        owner = (_isTargetInRole(w, roleId)) ? w : address(0);}
    function tokenURI(uint256 tokenId) external view override returns (string memory){
        uint8 roleId = uint8(tokenId >> 160);
        address w = address(uint160(tokenId - (roleId << 160)));
        bytes memory bytesExtraURI = bytes(_rolesByIndex[roleId].extraURI[w]);
        if (bytesExtraURI.length != 0) {return _rolesByIndex[roleId].extraURI[w];} else {return _rolesByIndex[roleId].roleURI;}}
    function getAddresses(uint8[] memory rolesIndexes) public view returns(address[] memory) {
        address[] memory l;
        if (rolesIndexes.length == 0) {
            l = new address[](0);
        } else {
            uint256 len;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                len += _rolesByIndex[rolesIndexes[j]].members.length();}
            l = new address[](len);
            uint256 ilen;
            uint256 tmplen;
            for (uint256 j = 0; j < rolesIndexes.length; j++) {
                tmplen = _rolesByIndex[rolesIndexes[j]].members.length();
                for (uint256 i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByIndex[rolesIndexes[j]].members.at(i);
                    ilen += 1;}}}
        return l;}
    function getRoles(address[] memory accounts) public view returns(uint8[] memory){
        uint8[] memory l;
        uint256 len;
        uint256 tmplen;
            for (uint256 j = 0; j < accounts.length; j++) {
                tmplen = _rolesByMember[accounts[j]].length();
                len += tmplen;}
            l = new uint8[](len);
            uint256 ilen;
            for (uint256 j = 0; j < accounts.length; j++) {
                uint256 i;
                tmplen = _rolesByMember[accounts[j]].length();
                for (i = 0; i < tmplen; i++) {
                    l[ilen] = _rolesByMember[accounts[j]].get(i);
                    ilen += 1;}}
        return l;}
    function getRoles() public view returns(uint8[] memory, string[] memory, string[] memory){
        uint8[] memory indexes = new uint8[](rolesCount-1);
        string[] memory names = new string[](rolesCount-1);
        string[] memory roleURIs = new string[](rolesCount-1);
        for (uint8 i = 1; i < rolesCount; i++) {
            indexes[i-1] = i-1;
            names[i-1] = _rolesByIndex[i].name.bytes32ToString();
            roleURIs[i-1] = _rolesByIndex[i].roleURI;
        }
        return (indexes, names, roleURIs);}
    function addressesCount(uint8 roleIndex)public view returns(uint256){return _rolesByIndex[roleIndex].members.length();}
    function addressesCount() public view returns(uint256) {return addressesCounter;}
    function inviteView(bytes memory sSig) public view returns(inviteSignature memory){return inviteSignatures[sSig];}
    function isAccountHasRole(address account, string memory rolename) public view returns(bool) {return _rolesByMember[account].contains(_roles[rolename.stringToBytes32()]);}
}
    