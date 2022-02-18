// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "./CommunityBase.sol";
import "./interfaces/ICommunity.sol";

contract Community is CommunityBase, ICommunity {
    
    
    ///////////////////////////////////////////////////////////
    /// external section
    ///////////////////////////////////////////////////////////

    /**
     * @dev creates three default roles and manage relations between it
     */
    function init() external initializer {
        __CommunityBase_init();
        
    }
    
}
