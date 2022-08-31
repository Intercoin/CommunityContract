// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./CommunityStorage.sol";
contract CommunityState is CommunityStorage {
    using PackedSet for PackedSet.Set;
    using StringUtils for *;
    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    function initialize(address hook,string memory name_, string memory symbol_) external {
        name = name_;
        symbol = symbol_;
        __CommunityBase_init(hook);}
    function withdrawRemainingBalance() public {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        payable(_msgSender()).transfer(address(this).balance);} 
    function grantRoles(address[] memory accounts, uint8[] memory rolesIndexes) public {
        uint8[] memory rolesIndexWhichWillGrant;
        uint8 roleIndexWhichWillGrant;
        for (uint256 i = 0; i < rolesIndexes.length; i++) {
            _isRoleValid(rolesIndexes[i]); 
            rolesIndexWhichWillGrant = _isCanGrant(_msgSender(), rolesIndexes[i], FlagFork.NONE);
            require(
                rolesIndexWhichWillGrant.length != 0,
                string(abi.encodePacked("Sender can not grant role '",_rolesByIndex[rolesIndexes[i]].name.bytes32ToString(),"'"))
            );
            roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, rolesIndexes[i], FlagFork.REVERT);
            for (uint256 j = 0; j < accounts.length; j++) {
                _grantRole(roleIndexWhichWillGrant, _msgSender(), rolesIndexes[i], accounts[j]);
            }}}
    function revokeRoles(address[] memory accounts, uint8[] memory rolesIndexes) public {
        uint8 roleWhichWillRevoke;
        address sender = _msgSender();
        for (uint256 i = 0; i < rolesIndexes.length; i++) {
            _isRoleValid(rolesIndexes[i]); 
            roleWhichWillRevoke = NONE_ROLE_INDEX;
            if (_isTargetInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
                roleWhichWillRevoke = _roles[DEFAULT_OWNERS_ROLE];
            } else {
                for (uint256 j = 0; j<_rolesByMember[sender].length(); j++) {
                    if (_rolesByIndex[uint8(_rolesByMember[sender].get(j))].canRevokeRoles.contains(rolesIndexes[i]) == true) {
                        roleWhichWillRevoke = _rolesByMember[sender].get(j);
                        break;}}}
            require(roleWhichWillRevoke != NONE_ROLE_INDEX, string(abi.encodePacked("Sender can not revoke role '",_rolesByIndex[rolesIndexes[i]].name.bytes32ToString(),"'")));
            for (uint256 k = 0; k < accounts.length; k++) {
                _revokeRole(/*roleWhichWillRevoke, */sender, rolesIndexes[i], accounts[k]);
            }}}
    function createRole(string memory role) public {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        require((_roles[role.stringToBytes32()] == 0) && (_roles[role._toLower().stringToBytes32()] == 0) , "Such role is already exists");
        require(rolesCount < type(uint8).max -1, "Max amount of roles exceeded");
        _createRole(role.stringToBytes32());}
    function manageRole(uint8 byRole, uint8 ofRole, bool canGrantRole, bool canRevokeRole, uint8 requireRole, uint256 maxAddresses, uint64 duration) public {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        require(ofRole != _roles[DEFAULT_OWNERS_ROLE], string(abi.encodePacked("ofRole can not be '", _rolesByIndex[ofRole].name.bytes32ToString(), "'")));
        _manageRole(byRole, ofRole, canGrantRole, canRevokeRole, requireRole, maxAddresses, duration);}
  
    function invitePrepare(bytes memory sSig, bytes memory rSig) public accummulateGasCost(sSig) {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);
        require(inviteSignatures[sSig].exists == false, "Such signature is already exists");
        inviteSignatures[sSig].sSig= sSig;
        inviteSignatures[sSig].rSig = rSig;
        inviteSignatures[sSig].reimbursed = ReimburseStatus.NONE;
        inviteSignatures[sSig].used = false;
        inviteSignatures[sSig].exists = true;}
    function inviteAccept(string memory p, bytes memory sSig, string memory rp, bytes memory rSig)public refundGasCost(sSig){
        ifTargetInRole(_msgSender(), _roles[DEFAULT_RELAYERS_ROLE]);
        require(inviteSignatures[sSig].used == false, "Such signature is already used");
        (address pAddr, address rpAddr) = _recoverAddresses(p, sSig, rp, rSig);
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");
        if (pAddr == address(0) || rpAddr == address(0) || keccak256(abi.encode(inviteSignatures[sSig].rSig)) != keccak256(abi.encode(rSig)) ||rpDataArr[0].parseAddr() != rpAddr || dataArr[1].parseAddr() != address(this)) {
            revert("Signature are mismatch");}
        bool isCanProceed = false;
        for (uint256 i = 0; i < rolesArr.length; i++) {
            uint8 roleIndex = _roles[rolesArr[i].stringToBytes32()];
            if (roleIndex == 0) {emit RoleAddedErrorMessage(_msgSender(), "invalid role");}
            uint8[] memory rolesIndexWhichWillGrant = _isCanGrant(pAddr, roleIndex, FlagFork.EMIT);
            uint8 roleIndexWhichWillGrant = validateGrantSettings(rolesIndexWhichWillGrant, roleIndex, FlagFork.EMIT);
            if (roleIndexWhichWillGrant == NONE_ROLE_INDEX) {
                emit RoleAddedErrorMessage(_msgSender(), string(abi.encodePacked("inviting user did not have permission to add role '",_rolesByIndex[roleIndex].name.bytes32ToString(),"'")));
            } else {
                isCanProceed = true;
                _grantRole(roleIndexWhichWillGrant, pAddr, roleIndex, rpAddr);}}
        if (isCanProceed == false) {revert("Can not add no one role");}
        inviteSignatures[sSig].used = true;
        if (invitedBy[rpAddr] == address(0)) {invitedBy[rpAddr] = pAddr;}
        invited[pAddr].add(rpAddr);
        _rewardCaller();
        _replenishRecipient(rpAddr);}
    function setTrustedForwarder(address forwarder) public override {
        ifTargetInRole(_msgSender(), _roles[DEFAULT_OWNERS_ROLE]);
        require(!_isTargetInRole(forwarder, _roles[DEFAULT_OWNERS_ROLE]),"FORWARDER_CAN_NOT_BE_OWNER");
        _setTrustedForwarder(forwarder);}
    function setRoleURI(uint8 roleIndex,string memory roleURI) public {
        ifTargetInRole(_msgSender(), roleIndex);
        _rolesByIndex[roleIndex].roleURI = roleURI;}
    function setExtraURI(uint8 roleIndex,string memory extraURI) public {
        ifTargetInRole(_msgSender(), roleIndex);
        _rolesByIndex[roleIndex].extraURI[_msgSender()] = extraURI;}
    function validateGrantSettings(uint8[] memory rolesWhichCanGrant,uint8 targetRoleIndex,FlagFork flag) internal returns(uint8) {
        uint8 roleWhichCanGrant = NONE_ROLE_INDEX;
        for (uint256 i = 0; i < rolesWhichCanGrant.length; i++) {
            if ((_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses == 0)) {
                roleWhichCanGrant = rolesWhichCanGrant[i];
            } else {
                if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration == 0 ) {
                    if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses) {
                        roleWhichCanGrant = rolesWhichCanGrant[i];}
                } else {
                    uint64 interval = uint64(block.timestamp)/(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration)*(_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].duration);
                    if (interval == _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].lastIntervalIndex) {
                        if (_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter+1 <= _rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].maxAddresses) {
                            roleWhichCanGrant = rolesWhichCanGrant[i];
                        }
                    } else {
                        roleWhichCanGrant = rolesWhichCanGrant[i];
                        _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].lastIntervalIndex = interval;
                        _rolesByIndex[roleWhichCanGrant].grantSettings[targetRoleIndex].grantedAddressesCounter = 0;}}}
            if (roleWhichCanGrant != NONE_ROLE_INDEX) {_rolesByIndex[rolesWhichCanGrant[i]].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;break;}}
        if (roleWhichCanGrant == NONE_ROLE_INDEX) {
            if (flag == FlagFork.REVERT) {
                revert("Max amount addresses exceeded");
            } else if (flag == FlagFork.EMIT) {
                emit RoleAddedErrorMessage(_msgSender(), "Max amount addresses exceeded");}}
        return roleWhichCanGrant;}
    function ifCanGrant(address sender, uint8 targetRoleIndex) internal {
        _isCanGrant(sender, targetRoleIndex,FlagFork.REVERT);}
    function _createRole(bytes32 role) internal {
        _roles[role] = rolesCount;
        _rolesByIndex[rolesCount].name = role;
        rolesCount += 1;
        if (hook != address(0)) {            
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleCreated(role, rolesCount);
            } catch {revert("wrong interface");}}
        emit RoleCreated(role, _msgSender());}
    function _manageRole(uint8 byRole, uint8 ofRole, bool canGrantRole, bool canRevokeRole, uint8 requireRole, uint256 maxAddresses, uint64 duration) internal {
        _isRoleValid(byRole);
        _isRoleValid(ofRole);
        if (canGrantRole) {
            _rolesByIndex[byRole].canGrantRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canGrantRoles.remove(ofRole);}
        if (canRevokeRole) {
            _rolesByIndex[byRole].canRevokeRoles.add(ofRole);
        } else {
            _rolesByIndex[byRole].canRevokeRoles.remove(ofRole);}
        _rolesByIndex[byRole].grantSettings[ofRole].requireRole = requireRole;
        _rolesByIndex[byRole].grantSettings[ofRole].maxAddresses = maxAddresses;
        _rolesByIndex[byRole].grantSettings[ofRole].duration = duration;
        emit RoleManaged(byRole, ofRole, canGrantRole, canRevokeRole, requireRole, maxAddresses, duration,_msgSender());}
    function _grantRole(uint8 sourceRoleIndex, address sourceAccount, uint8 targetRoleIndex, address targetAccount) internal {
        if (_rolesByMember[targetAccount].length() == 0) {addressesCounter++;}
       _rolesByMember[targetAccount].add(targetRoleIndex);
       _rolesByIndex[targetRoleIndex].members.add(targetAccount);
        grantedBy[targetAccount].push(ActionInfo({actor: sourceAccount,timestamp: uint64(block.timestamp),extra: uint32(targetRoleIndex)}));
        granted[sourceAccount].push(ActionInfo({actor: targetAccount,timestamp: uint64(block.timestamp),extra: uint32(targetRoleIndex)}));
        _rolesByIndex[sourceRoleIndex].grantSettings[targetRoleIndex].grantedAddressesCounter += 1;
        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleGranted(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");}}
        emit RoleGranted(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);}
    function _revokeRole(address sourceAccount, uint8 targetRoleIndex, address targetAccount) internal {
        _rolesByMember[targetAccount].remove(targetRoleIndex);
        _rolesByIndex[targetRoleIndex].members.remove(targetAccount);
        if (_rolesByMember[targetAccount].length() == 0 &&addressesCounter != 0) {addressesCounter--;}
        revokedBy[targetAccount].push(ActionInfo({actor: sourceAccount,timestamp: uint64(block.timestamp),extra: uint32(targetRoleIndex)}));
        revoked[sourceAccount].push(ActionInfo({actor: targetAccount,timestamp: uint64(block.timestamp),extra: uint32(targetRoleIndex)}));
        if (hook != address(0)) {
            try ICommunityHook(hook).supportsInterface(type(ICommunityHook).interfaceId) returns (bool) {
                ICommunityHook(hook).roleRevoked(_rolesByIndex[targetRoleIndex].name, targetRoleIndex, targetAccount);
            } catch {
                revert("wrong interface");}}
        emit RoleRevoked(_rolesByIndex[targetRoleIndex].name, targetAccount, sourceAccount);}
    function _isCanGrant(address sender, uint8 targetRoleIndex, FlagFork flag) internal returns (uint8[] memory) {
        uint256 iLen;
        uint8[] memory rolesWhichCan;
        if (_isTargetInRole(sender, _roles[DEFAULT_OWNERS_ROLE])) {
            rolesWhichCan = new uint8[](1);
            rolesWhichCan[0] = _roles[DEFAULT_OWNERS_ROLE];
        } else {
            iLen = 0;
            for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    iLen++;}}
            rolesWhichCan = new uint8[](iLen);
            iLen = 0;
            for (uint256 i = 0; i<_rolesByMember[sender].length(); i++) {
                if (_rolesByIndex[uint8(_rolesByMember[sender].get(i))].canGrantRoles.contains(targetRoleIndex) == true) {
                    rolesWhichCan[iLen] = _rolesByMember[sender].get(i);
                    iLen++;}}
            if (rolesWhichCan.length == 0) {
                string memory errMsg = string(abi.encodePacked("Sender can not grant account with role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(), "'"));
                if (flag == FlagFork.REVERT) {
                    revert(errMsg);
                } else if (flag == FlagFork.EMIT) {
                    emit RoleAddedErrorMessage(sender, errMsg);}}}
        return rolesWhichCan;}
    function __CommunityBase_init(address hook_) internal onlyInitializing {
        __TrustedForwarder_init();
        __ReentrancyGuard_init();
        rolesCount = 1;
        _createRole(DEFAULT_RELAYERS_ROLE);
        _createRole(DEFAULT_OWNERS_ROLE);
        _createRole(DEFAULT_ADMINS_ROLE);
        _createRole(DEFAULT_MEMBERS_ROLE);
        _createRole(DEFAULT_ALUMNI_ROLE);
        _createRole(DEFAULT_VISITORS_ROLE);
        _grantRole(_roles[DEFAULT_OWNERS_ROLE], _msgSender(), _roles[DEFAULT_OWNERS_ROLE], _msgSender());
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_MEMBERS_ROLE],  true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_ALUMNI_ROLE],   true, true, 0, 0, 0);
        _manageRole(_roles[DEFAULT_ADMINS_ROLE], _roles[DEFAULT_VISITORS_ROLE], true, true, 0, 0, 0);
        hook = hook_;}
    function ifTargetInRole(address target, uint8 targetRoleIndex) internal view {
        require(_isTargetInRole(target, targetRoleIndex),string(abi.encodePacked("Missing role '", _rolesByIndex[targetRoleIndex].name.bytes32ToString(),"'")));}
    function _isRoleValid(uint8 index) internal view {
        require((rolesCount > index), "invalid role"); }
    function _rewardCaller() private {
        if (REWARD_AMOUNT <= address(this).balance) {payable(_msgSender()).transfer(REWARD_AMOUNT);}}
    function _replenishRecipient(address rpAddr) private {if (REPLENISH_AMOUNT <= address(this).balance) {payable(rpAddr).transfer(REPLENISH_AMOUNT);}}
    function _recoverAddresses(string memory p, bytes memory sSig, string memory rp, bytes memory rSig) private pure returns(address, address) {
        return (p.recreateMessageHash().recover(sSig), rp.recreateMessageHash().recover(rSig));}
}
    