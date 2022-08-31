// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;
import "./CommunityStorage.sol";
import "./CommunityState.sol";
import "./CommunityView.sol";
import "./interfaces/ICommunity.sol";
contract Community is CommunityStorage, ICommunity {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    CommunityState implCommunityState;
    CommunityView implCommunityView;
    function initialize(address implCommunityState_,address implCommunityView_,address hook,address costManager_,string memory name, string memory symbol) public override initializer {
        implCommunityState = CommunityState(implCommunityState_);
        implCommunityView = CommunityView(implCommunityView_);
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager_);
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.initialize.selector,
                hook, name, symbol
            ));
        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(hook)),
            uint256(uint160(costManager_))
        );
    }
    function withdrawRemainingBalance() public nonReentrant() { _functionDelegateCall(address(implCommunityState), msg.data);} 
    function grantRoles(address[] memory accounts, uint8[] memory rolesIndexes) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_GRANT_ROLES << OPERATION_SHIFT_BITS,0,0);
    }
    function revokeRoles(address[] memory accounts, uint8[] memory rolesIndexes) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_REVOKE_ROLES << OPERATION_SHIFT_BITS,0,0);
    }
    function createRole(string memory role) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_CREATE_ROLE << OPERATION_SHIFT_BITS,0,0);
    }
    function manageRole(uint8 byRole, uint8 ofRole, bool canGrantRole, bool canRevokeRole, uint8 requireRole, uint256 maxAddresses, uint64 duration) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_MANAGE_ROLE << OPERATION_SHIFT_BITS,0,0);
    }
    function setTrustedForwarder(address forwarder) public override {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_SET_TRUSTED_FORWARDER << OPERATION_SHIFT_BITS,0,0);
    }
    function invitePrepare(bytes memory sSig, bytes memory rSig) public accummulateGasCost(sSig) {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_INVITE_PREPARE << OPERATION_SHIFT_BITS,0,0);
    }
    function inviteAccept(string memory p, bytes memory sSig, string memory rp, bytes memory rSig) public refundGasCost(sSig) nonReentrant() {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_INVITE_ACCEPT << OPERATION_SHIFT_BITS,0,0);
    }
    function setRoleURI(uint8 roleIndex,string memory roleURI) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_SET_ROLE_URI << OPERATION_SHIFT_BITS,0,0);
    }
    function setExtraURI(uint8 roleIndex,string memory extraURI) public {
        _functionDelegateCall(address(implCommunityState), msg.data);
        _accountForOperation(OPERATION_SET_EXTRA_URI << OPERATION_SHIFT_BITS,0,0);
    }
    function getAddresses(uint8 rolesIndex) public view returns(address[] memory) {
        uint8[] memory rolesIndexes = new uint8[](1);
        rolesIndexes[0] = rolesIndex;
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(CommunityView.getAddresses.selector,rolesIndexes), ""), (address[]));  
    }
    function getAddresses(uint8[] memory rolesIndexes) public view returns(address[] memory) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(CommunityView.getAddresses.selector,rolesIndexes), ""), (address[]));  
    }
    function getRoles(address member) public view returns(uint8[] memory) {
        address[] memory members = new address[](1);
        members[0] = member;
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(bytes4(keccak256("getRoles(address[])")),members), ""), (uint8[]));  
    }
    function getRoles(address[] memory members) public view returns(uint8[] memory){
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(bytes4(keccak256("getRoles(address[])")),members), ""), (uint8[]));  
    }
    function getRoles() public view returns(uint8[] memory, string[] memory, string[] memory) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(bytes4(keccak256("getRoles()"))), ""), (uint8[], string[], string[]));  
    }
    function addressesCount(uint8 roleIndex) public view returns(uint256) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(bytes4(keccak256("addressesCount(uint8)")),roleIndex), ""), (uint256));  
    }
    function addressesCount() public view returns(uint256) {
        return addressesCounter;
    }
    function inviteView(bytes memory sSig) public view returns(inviteSignature memory) {
        return inviteSignatures[sSig];
    }
    function isAccountHasRole(address account, uint8 roleIndex) public view returns(bool) {
        return _rolesByMember[account].contains(roleIndex);
    }
    function getRoleIndex(string memory rolename) public view returns(uint8) {
        return _roles[rolename.stringToBytes32()];
    }
    function balanceOf(address account) external view override returns (uint256 balance) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(CommunityView.balanceOf.selector,account), ""), (uint256));  
    }
    function ownerOf(uint256 tokenId) external view override returns (address owner) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(CommunityView.ownerOf.selector,tokenId), ""), (address));
    }
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return abi.decode(_functionDelegateCallView(address(implCommunityView), abi.encodeWithSelector(CommunityView.tokenURI.selector,tokenId), ""), (string));
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) { 
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}}
    }
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    function _functionDelegateCallView(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        data = abi.encodePacked(target,data,msg.sender);    
        (bool success, bytes memory returndata) = address(this).staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    receive() external payable {}
    fallback() payable external {
        if (msg.sender == address(this)) {
            address implementationLogic;
            bytes memory msgData = msg.data;
            bytes memory msgDataPure;
            uint256 offsetnew;
            uint256 offsetold;
            uint256 i;
            assembly {
                implementationLogic:= mload(add(msgData,0x14))
            }
            msgDataPure = new bytes(msgData.length-20);
            uint256 max = msgData.length + 31;
            offsetold=20+32;        
            offsetnew=32;
            assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            for (i=52+32; i<=max; i+=32) {
                offsetnew = i-20;
                offsetold = i;
                assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            }
            (bool success, bytes memory data) = address(implementationLogic).delegatecall(msgDataPure);
            assembly {
                switch success
                    case 0 { revert(add(data, 32), returndatasize()) }
                    default { return(add(data, 32), returndatasize()) }
            }}}
}
