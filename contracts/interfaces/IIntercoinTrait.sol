// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IIntercoinTrait {
    
    function setIntercoinAddress(address addr) external returns(bool);
    function getIntercoinAddress() external view returns (address);
    
}