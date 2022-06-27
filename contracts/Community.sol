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

    /**
    * @notice initializes contract
    */
    function initialize(
        address implCommunityState_,
        address implCommunityView_,
        address hook,
        string memory name, 
        string memory symbol
    ) 
        public 
        override
        initializer 
    {

        implCommunityState = CommunityState(implCommunityState_);
        implCommunityView = CommunityView(implCommunityView_);

        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.initialize.selector,
                hook, name, symbol
            )
            //msg.data
        );

    }


    ///////////////////////////////////////////////////////////
    /// public  section
    ///////////////////////////////////////////////////////////

    /**
    * @notice the way to withdraw remaining ETH from the contract. called by owners only 
    * @custom:shortd the way to withdraw ETH from the contract.
    * @custom:calledby owners
    */
    function withdrawRemainingBalance(
    ) 
        public 
        nonReentrant()
    {
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.withdrawRemainingBalance.selector
            )
            //msg.data
        );
    } 

    /**
     * @notice Added new Roles for each account
     * @custom:shortd Added new Roles for each account
     * @param accounts participant's addresses
     * @param rolesIndexes Roles indexes
     */
    function grantRoles(
        address[] memory accounts, 
        uint8[] memory rolesIndexes
    )
        public 
    {
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.grantRoles.selector,
                accounts, rolesIndexes
            )
            //msg.data
        );

    }
    
    /**
     * @notice Removed Roles from each member
     * @custom:shortd Removed Roles from each member
     * @param accounts participant's addresses
     * @param rolesIndexes Roles indexes
     */
    function revokeRoles(
        address[] memory accounts, 
        uint8[] memory rolesIndexes
    ) 
        public 
    {

        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.revokeRoles.selector,
                accounts, rolesIndexes
            )
            //msg.data
        );
    }
    
    /**
     * @notice creating new role. can called owners role only
     * @custom:shortd creating new role. can called owners role only
     * @param role role name
     */
    function createRole(
        string memory role
    ) 
        public 
        
    {
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.createRole.selector,
                role
            )
            //msg.data
        );
        
    }
    
    /**
     * @notice allow account with byRole:
     * (if canGrantRole ==true) grant ofRole to another account if account has requireRole
     *          it can be available `maxAddresses` during `duration` time
     *          if duration == 0 then no limit by time: `maxAddresses` will be max accounts on this role
     *          if maxAddresses == 0 then no limit max accounts on this role
     * (if canRevokeRole ==true) revoke ofRole from account.
     */
    function manageRole(
        uint8 byRole, 
        uint8 ofRole, 
        bool canGrantRole, 
        bool canRevokeRole, 
        uint8 requireRole, 
        uint256 maxAddresses, 
        uint64 duration
    )
        public 
    {
        
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.manageRole.selector,
                byRole, ofRole, canGrantRole, canRevokeRole, requireRole, maxAddresses, duration
            )
            //msg.data
        );
        
    }
  
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
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    CommunityView.getAddresses.selector,
                    rolesIndexes
                ), 
                ""
            ), 
            (address[])
        );  

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
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.getRoles().selector,
                    bytes4(keccak256("getRoles(address[])")),
                    members
                ), 
                ""
            ), 
            (uint8[])
        );  

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
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.getRoles.selector
                    bytes4(keccak256("getRoles()"))
                ), 
                ""
            ), 
            (uint8[], string[], string[])
        );  

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
        return abi.decode(
            _functionDelegateCallView(
                address(implCommunityView), 
                abi.encodeWithSelector(
                    //CommunityView.addressesCount.selector,
                    bytes4(keccak256("addressesCount(uint8)")),
                    roleIndex
                ), 
                ""
            ), 
            (uint256)
        );  

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
     * @notice registering invite,. calling by relayers
     * @custom:shortd registering invite 
     * @param sSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        public 
        
        accummulateGasCost(sSig)
    {
        _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.invitePrepare.selector,
                sSig, rSig
            )
            //msg.data
        );

    }
    
    /**
     * @dev
     * @dev ==P==  
     * @dev format is "<some string data>:<address of communityContract>:<array of rolenames (sep=',')>:<some string data>"          
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:GregMagarshak  
     * @dev ==R==  
     * @dev format is "<address of R wallet>:<name of user>"  
     * @dev 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4:John Doe  
     * @notice accepting invite
     * @custom:shortd accepting invite
     * @param p invite message of admin whom generate messageHash and signed it
     * @param sSig signature of admin whom generate invite and signed it
     * @param rp message of recipient whom generate messageHash and signed it
     * @param rSig signature of recipient
     */
    function inviteAccept(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    )
        public 
        refundGasCost(sSig)
        nonReentrant()
    {
         _functionDelegateCall(
            address(implCommunityState), 
            abi.encodeWithSelector(
                CommunityState.inviteAccept.selector,
                p, sSig, rp, rSig
            )
            //msg.data
        );

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
  
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        //require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    function _functionDelegateCallView(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        //require(isContract(target), "Address: static call to non-contract");
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
            
            // extract address implementation;
            assembly {
                implementationLogic:= mload(add(msgData,0x14))
            }
            
            msgDataPure = new bytes(msgData.length-20);
            uint256 max = msgData.length + 31;
            offsetold=20+32;        
            offsetnew=32;
            // extract keccak256 of methods's hash
            assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            
            // extract left data
            for (i=52+32; i<=max; i+=32) {
                offsetnew = i-20;
                offsetold = i;
                assembly { mstore(add(msgDataPure, offsetnew), mload(add(msgData, offsetold))) }
            }
            
            // finally make call
            (bool success, bytes memory data) = address(implementationLogic).delegatecall(msgDataPure);
            assembly {
                switch success
                    // delegatecall returns 0 on error.
                    case 0 { revert(add(data, 32), returndatasize()) }
                    default { return(add(data, 32), returndatasize()) }
            }
            
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
