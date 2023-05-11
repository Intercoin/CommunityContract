// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./lib/StringUtils.sol";
import "./lib/ECDSAExt.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ICommunityInvite.sol";
import "./interfaces/ICommunity.sol";
import "./interfaces/IAuthorizedInviteManager.sol";
import "@artman325/releasemanager/contracts/CostManagerHelper.sol";
import "@artman325/releasemanager/contracts/ReleaseManagerHelper.sol";
import "@artman325/releasemanager/contracts/interfaces/IReleaseManager.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";
//import "hardhat/console.sol";

 
contract AuthorizedInviteManager is IAuthorizedInviteManager, Initializable, ReentrancyGuardUpgradeable, CostManagerHelper {

    using StringUtils for *;  
    using ECDSAExt for string;
    using ECDSAUpgradeable for bytes32;
    
      
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    //using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint64 internal constant RESERVE_DELAY = 10 minutes;
       
    mapping (bytes32 => inviteReserveStruct) inviteReserved;

    mapping (bytes => inviteSignature) inviteSignatures;  
    
    //receiver => sender
    mapping(address => address) public invitedBy;
    //sender => receivers
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal invited;
 
    uint8 internal constant NONE_ROLE_INDEX = 0;
        
    /**
    * @notice constant reward that user-relayers will obtain
    * @custom:shortd reward that user-relayers will obtain
    */
    uint256 public constant REWARD_AMOUNT = 1000000000000000; // 0.001 * 1e18
    /**
    * @notice constant reward amount that user-recepient will replenish
    * @custom:shortd reward amount that user-recepient will replenish
    */
    uint256 public constant REPLENISH_AMOUNT = 1000000000000000; // 0.001 * 1e18

    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;

    event RoleAddedErrorMessage(address indexed sender, string msg);

    /**
     * param sSig signature of admin whom generate invite and signed it
     */
    modifier accummulateGasCostWhenReserve(bytes32 hash)
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();

        inviteReserved[hash].gasCost = inviteReserved[hash].gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;
//        24979
        //----
    }

    modifier accummulateGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;

        uint remainingGasEnd = gasleft();
//console.log("total = ",remainingGasStart - remainingGasEnd + 56867);
        // uint usedGas = remainingGasStart - remainingGasEnd;
        // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        // // usedGas += 21000 + 9700;
        // usedGas += 30700;
        // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        // uint gasCost = usedGas * tx.gasprice;
        // // accummulate refund gas cost
        // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
        //inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;
        //inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 56867) * tx.gasprice;
        inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + (remainingGasStart - remainingGasEnd + 51146) * tx.gasprice;
        
        //gasCost = gasCost + (remainingGasStart - remainingGasEnd + 30700) * tx.gasprice;
        //----
    }
    
    /**
     * @param sSig signature of admin whom generate invite and signed it
     */
    modifier refundGasCost(bytes memory sSig)
    {
        uint remainingGasStart = gasleft();

        _;
        
        uint gasCost;
        
        if (inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE) {
            uint remainingGasEnd = gasleft();
            // uint usedGas = remainingGasStart - remainingGasEnd;
            // // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            // usedGas += 21000 + 9700 + 47500;
            // // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
            // gasCost = usedGas * tx.gasprice;

            // inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + gasCost;
            //inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + ((remainingGasStart - remainingGasEnd + 78200) * tx.gasprice);
            inviteSignatures[sSig].gasCost = inviteSignatures[sSig].gasCost + ((remainingGasStart - remainingGasEnd + 47240) * tx.gasprice);
            
        }
        // Refund gas cost
        gasCost = inviteSignatures[sSig].gasCost;

        if (
            (gasCost <= address(this).balance) && 
            (
            inviteSignatures[sSig].reimbursed == ReimburseStatus.NONE ||
            inviteSignatures[sSig].reimbursed == ReimburseStatus.PENDING
            )
        ) {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.CLAIMED;
            //payable (inviteSignatures[sSig].caller).transfer(gasCost);
           
            payable(msg.sender).transfer(gasCost);

        } else {
            inviteSignatures[sSig].reimbursed = ReimburseStatus.PENDING;
        }
        
        
    }

    /**
    * @notice initializes contract
    */
    function initialize(
        address costManager_
    ) 
        public 
        override
        initializer 
    {

        __CostManagerHelper_init(msg.sender);
        _setCostManager(costManager_);

        __ReentrancyGuard_init();
        
        _accountForOperation(
            OPERATION_INITIALIZE << OPERATION_SHIFT_BITS,
            uint256(uint160(costManager_)),
            0
        );
    }

    
    
    receive() external payable {}
    
    function inviteReserve(
        bytes32 hash
    ) 
        external 
        accummulateGasCostWhenReserve(hash)
    {
        require (inviteReserved[hash].timestamp == 0, "Already reserved");
        inviteReserved[hash].timestamp = uint64(block.timestamp);
        inviteReserved[hash].sender = msg.sender;
    }

    /**
     * @notice registering invite, calling by relayers
     * @custom:shortd registering invite 
     * @param sSig signature of admin whom generate invite and signed it
     * @param rSig signature of recipient
     */
    function invitePrepare(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        external
        accummulateGasCost(sSig)
    {
        bytes32 reverveHash = getInviteReservedHash(sSig, rSig);
        bool isReserved = inviteReserved[reverveHash].timestamp != 0 ? true : false;

        if (isReserved) {
            require(inviteReserved[reverveHash].timestamp + RESERVE_DELAY <= block.timestamp, "Invite still reserved");
        }
        
        require(inviteSignatures[sSig].exists == false, "Such signature is already exists");
        inviteSignatures[sSig].sSig= sSig;
        inviteSignatures[sSig].rSig = rSig;
        inviteSignatures[sSig].reimbursed = ReimburseStatus.NONE;
        inviteSignatures[sSig].used = false;
        inviteSignatures[sSig].exists = true;        
    }

    
    /**
     * @dev
     * @dev ==P==  
     * @dev format is "<some string data>:<address of communityContract>:<array of role names (sep=',')>:<chain id>:<deadline in unixtimestamp>:<some string data>"          
     * @dev invite:0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC:judges,guests,admins:1:1698916962:GregMagarshak  
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
        external 
        refundGasCost(sSig)
        //nonReentrant()
    {
        
        inviteSignature storage signature = inviteSignatures[sSig];
        require(signature.used == false, "Such signature is already used");

        (address pAddr, address rpAddr) = _recoverAddresses(p, sSig, rp, rSig);
       
        string[] memory dataArr = p.slice(":");
        string[] memory rolesArr = dataArr[2].slice(",");
        string[] memory rpDataArr = rp.slice(":");
        
        uint256 chainId;
        //second way to get directly from block.chainId. since instambul version
        assembly {
            chainId := chainid()
        }

        address communityDestination = dataArr[1].parseAddr();


        // community instance check
        // should be
        // release manager should be verifing
        // deployer - it's factory
        address releaseManagerAddr = ReleaseManagerHelper(deployer).releaseManager();
        bool isCommunityVerifying = IReleaseManager(releaseManagerAddr).checkInstance(communityDestination);
        // and ICommunityInvite(communityDestination).getAuthorizedInviteManager() != address(this) ||
        isCommunityVerifying = 
            (isCommunityVerifying) 
            ?
            ICommunityInvite(communityDestination).getAuthorizedInviteManager() == address(this) 
            :
            false;

        
        if (
            pAddr == address(0) || 
            rpAddr == address(0) || 
            keccak256(abi.encode(signature.rSig)) != keccak256(abi.encode(rSig)) ||
            rpDataArr[0].parseAddr() != rpAddr || 
            !isCommunityVerifying ||
            keccak256(abi.encode(str2num(dataArr[3]))) != keccak256(abi.encode(chainId)) ||
            str2num(dataArr[4]) < block.timestamp
        ) {
            revert("Signature are mismatch");
        }

        uint8[] memory rolesIndexesTmp = ICommunity(communityDestination).getRolesWhichAccountCanGrant(pAddr, rolesArr);
        // create none empty rolesindexes
        uint256 len;
        for (uint256 i = 0; i < rolesIndexesTmp.length; i++) {
            if (rolesIndexesTmp[i] != NONE_ROLE_INDEX) {
                emit RoleAddedErrorMessage(msg.sender, string(abi.encodePacked("inviting user did not have permission to add role '",rolesArr[i],"'")));
                len++;
            }
        }

        if (len == 0) {
            revert("Can not add no one role");
        }

        address[] memory accounts = new address[](len);
        uint8[] memory roleIndexes = new uint8[](len);
        uint256 j = 0;
        for (uint256 i = 0; i < rolesIndexesTmp.length; i++) {
            if (rolesIndexesTmp[i] != NONE_ROLE_INDEX) {
                accounts[j] = rpAddr;
                roleIndexes[j] = rolesIndexesTmp[i];
                j++;
            }
        }
        ICommunityInvite(communityDestination).grantRolesExternal(pAddr, accounts, roleIndexes);

        signature.used = true;

        inviteAcceptPart2(pAddr, rpAddr);
       
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
    
    function getInviteReservedHash(
        bytes memory sSig, 
        bytes memory rSig
    ) 
        public
        pure 
        returns(bytes32)
    {
        return keccak256(abi.encode(sSig, rSig));
    }

    // used to split `inviteAccept` method to avoid "stack is too deep error"
    function inviteAcceptPart2(address pAddr, address rpAddr) internal {
        
        //store first inviter
        if (invitedBy[rpAddr] == address(0)) {
            invitedBy[rpAddr] = pAddr;
        }

        invited[pAddr].add(rpAddr);
        
        _rewardCaller();
        _replenishRecipient(rpAddr);
    }

    /**
     * reward caller(relayers)
     */
    function _rewardCaller(
    ) 
        private 
    {
        if (REWARD_AMOUNT <= address(this).balance) {
            payable(msg.sender).transfer(REWARD_AMOUNT);
        }
    }
    
    /**
     * replenish recipient which added via invite
     * @param rpAddr recipient's address 
     */
    function _replenishRecipient(
        address rpAddr
    ) 
        private 
    {
        if (REPLENISH_AMOUNT <= address(this).balance) {
            payable(rpAddr).transfer(REPLENISH_AMOUNT);
        }
    }
    
    function _recoverAddresses(
        string memory p, 
        bytes memory sSig, 
        string memory rp, 
        bytes memory rSig
    ) 
        private 
        pure
        returns(address, address)
    {
        // bytes32 pHash = p.recreateMessageHash();
        // bytes32 rpHash = rp.recreateMessageHash();
        // address pAddr = pHash.recover(sSig);
        // address rpAddr = rpHash.recover(rSig);
        // return (pAddr, rpAddr);
        return (
            p.recreateMessageHash().recover(sSig), 
            rp.recreateMessageHash().recover(rSig)
        );
    }

    
    function str2num(string memory numString) private pure returns(uint256) {
        uint256 val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint256  i =  0; i<stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);
   
            val +=  (uint256(jval) * (10**(exp-1))); 
        }
        return val;
    }
    


    
    
}