pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../CommunityContract.sol";

contract CommunityContractMock is CommunityContract {
   
    function getTargetRoleID(string memory targetRole) public view returns(uint256) {
        return _roles[stringToBytes32(targetRole)];
    }
    function getRolesByMemberLength(address account) public view returns(uint256) {
        return _rolesByMember[account].length();
    }
    
    
    function canManageRoles(string memory sourceRole) public view returns(string[] memory) {
        
        uint256 sourceRoleID = _roles[stringToBytes32(sourceRole)];
        
        uint256 len = _canManageRoles[sourceRoleID].length();
        string[] memory l = new string[](len);
        for (uint256 i = 0; i<len; i++) {
            l[i] = bytes32ToString(_rolesIndices[_canManageRoles[sourceRoleID].at(i)]);
        }
        return l;
   }

}


