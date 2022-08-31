// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICommunityTransfer.sol";
import "./interfaces/ICommunity.sol";
import "releasemanager/contracts/CostManagerFactoryHelper.sol";
import "releasemanager/contracts/ReleaseManagerHelper.sol";
contract CommunityFactory is CostManagerFactoryHelper, ReleaseManagerHelper {
    using Clones for address;
    address public immutable implementation;
    address public immutable implementationState;
    address public immutable implementationView;
    address[] public instances;
    event InstanceCreated(address instance, uint instancesCount);
    constructor(address _implementation,address _implementationState,address _implementationView,address _costManager) CostManagerFactoryHelper(_costManager) {
        implementation      = _implementation;
        implementationState = _implementationState;
        implementationView  = _implementationView;}
    function instancesCount()external view returns (uint256 amount) {amount = instances.length;}
    function produce(address hook,string memory name,string memory symbol) public returns (address instance) {
        instance = address(implementation).clone();
        _produce(instance);
        ICommunity(instance).initialize(address(implementationState), address(implementationView), hook, costManager, name, symbol);
        _postProduce(instance);}
    function _produce(address instance) internal {
        require(instance != address(0), "CommunityCoinFactory: INSTANCE_CREATION_FAILED");
        instances.push(instance);
        emit InstanceCreated(instance, instances.length);}
    function _postProduce(address instance) internal {
        address[] memory s = new address[](1);
        s[0] = msg.sender;
        uint8[] memory r = new uint8[](1);
        r[0] = 2;//"owners";
        ICommunityTransfer(instance).grantRoles(s, r);
        registerInstance(instance);}
}