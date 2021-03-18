const BigNumber = require('bignumber.js');

//const Web3 = require("web3");
//const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
//var util = require('web3-utils');

const util = require('util');

const CommunityContract = artifacts.require("CommunityContract");
//const CommunityContractMock = artifacts.require("CommunityContractMock");
//const ERC20MintableToken = artifacts.require("ERC20Mintable");
const truffleAssert = require('truffle-assertions');

const helper = require("../helpers/truffleTestHelper");
const EthUtil             = require('ethereumjs-util');

contract('CommunityContract', (accounts) => {
    
    // it("should assert true", async function(done) {
    //     await TestExample.deployed();
    //     assert.isTrue(true);
    //     done();
    //   });
    
    // Setup accounts.
    const accountOne = accounts[0];
    const accountTwo = accounts[1];  
    const accountThree = accounts[2];
    const accountFourth= accounts[3];
    const accountFive = accounts[4];
    const accountSix = accounts[5];
    const accountSeven = accounts[6];
    const accountEight = accounts[7];
    const accountNine = accounts[8];
    const accountTen = accounts[9];
    const accountEleven = accounts[10];
    const accountTwelwe = accounts[11];

    // setup useful vars
    var rolesTitle = 'OWNERS';
    var roleStringADMINS = 'ADMINS';
    
    var rolesTitle = new Map([
      ['owners', 'owners'],
      ['admins', 'admins'],
      ['members', 'members'],
      ['webx', 'webx'],
      ['role1', 'Role#1'],
      ['role2', 'Role#2'],
      ['role3', 'Role#3'],
      ['role4', 'Role#4'],
      ['cc_admins', 'AdMiNs']
    ]);
   
   
  var CommunityContractInstance;
   
    beforeEach(function() {
        return CommunityContract.new({from: accountOne})
        .then(function(instance) {
            CommunityContractInstance = instance;
        });
    });
    
  
    it('creator must be owner and admin', async () => {
        
        await CommunityContractInstance.init({from: accountOne});
        
        var rolesList = (await CommunityContractInstance.getRoles(accountOne,{from: accountOne}));
        assert.isTrue(rolesList.includes(rolesTitle.get('owners')), 'outside OWNERS role');
        assert.isTrue(rolesList.includes(rolesTitle.get('admins')), 'outside ADMINS role');
    });
    
    it('can add member', async () => {
        
        await CommunityContractInstance.init({from: accountOne});
        
        await CommunityContractInstance.addMembers([accountTwo]);
        var rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
        assert.isTrue(rolesList.includes(rolesTitle.get('members')), 'outside members role');
    });
    
    it('can remove member', async () => {
        await CommunityContractInstance.init({from: accountOne});
        var rolesList;

        await CommunityContractInstance.addMembers([accountTwo]);
        rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
        assert.isTrue(rolesList.includes(rolesTitle.get('members')), 'outside members role');
        
        await CommunityContractInstance.removeMembers([accountTwo]);
        rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
        assert.isFalse(rolesList.includes(rolesTitle.get('members')), 'outside members role');
    });
    
    
    it('can create new role', async () => {
        await CommunityContractInstance.init({from: accountOne});
        
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountThree}),
            "Ownable: caller is not the owner"
        );
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('owners'), {from: accountOne}),
            "Such role is already exists"
        );
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('admins'), {from: accountOne}),
            "Such role is already exists"
        );
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('members'), {from: accountOne}),
            "Such role is already exists"
        );
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('cc_admins'), {from: accountOne}),
            "Such role is already exists"
        );
        
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne});
        await truffleAssert.reverts(
            CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne}),
            "Such role is already exists"
        );
    });
    
    it('can manage role', async () => {
        await CommunityContractInstance.init({from: accountOne});
        
        // create two roles
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne});
        await CommunityContractInstance.createRole(rolesTitle.get('role2'), {from: accountOne});
        
        // ownbale check
        await truffleAssert.reverts(
            CommunityContractInstance.manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'), {from: accountThree}),
            "Ownable: caller is not the owner"
        );
        // role exist check
        await truffleAssert.reverts(
            CommunityContractInstance.manageRole(rolesTitle.get('role4'),rolesTitle.get('role2'), {from: accountOne}),
            "Source role does not exists"
        );
        await truffleAssert.reverts(
            CommunityContractInstance.manageRole(rolesTitle.get('role1'),rolesTitle.get('role4'), {from: accountOne}),
            "Source role does not exists"
        );
        // manage role
        await CommunityContractInstance.manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'), {from: accountOne});
        //add member
        await CommunityContractInstance.addMembers([accountTwo], {from: accountOne});

        // added member to none-exists member
        await truffleAssert.reverts(
            CommunityContractInstance.addRoles([accountThree], [rolesTitle.get('role1')], {from: accountOne}),
            "Target account must be with role '" +rolesTitle.get('members')+"'"
        );

         // added member to none-exists role 
        await truffleAssert.reverts(
            CommunityContractInstance.addRoles([accountTwo], [rolesTitle.get('role4')], {from: accountOne}),
            "Such role '"+rolesTitle.get('role4')+"' does not exists"
        );
       
        await CommunityContractInstance.addRoles([accountTwo], [rolesTitle.get('role1')], {from: accountOne});

        //add member by accountTwo
        await CommunityContractInstance.addMembers([accountFourth], {from: accountTwo});
       
        //add role2 to accountFourth by accountTwo
        await CommunityContractInstance.addRoles([accountFourth], [rolesTitle.get('role2')], {from: accountTwo});
        
    });
    
    it('can remove account from role', async () => {
        await CommunityContractInstance.init({from: accountOne});
        var rolesList;
        
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne});
        //add member
        await CommunityContractInstance.addMembers([accountTwo], {from: accountOne});
        // add member to role
        await CommunityContractInstance.addRoles([accountTwo], [rolesTitle.get('role1')], {from: accountOne});
        
        // check that accountTwo got `get('role1')`
        rolesList = (await CommunityContractInstance.getRoles(accountTwo, {from: accountOne}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // remove
        await CommunityContractInstance.removeRoles([accountTwo], [rolesTitle.get('role1')], {from: accountOne});
        // check removing
        rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // check allowance to remove default role `members`
        await truffleAssert.reverts(
            CommunityContractInstance.removeRoles([accountTwo], [rolesTitle.get('members')], {from: accountOne}),
            "Can not remove role '" +rolesTitle.get('members')+"'"
        );
    });
    
    it('possible to grant with cycle. ', async () => {
        
        await CommunityContractInstance.init({from: accountTen});
        
        // create roles
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role2'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role3'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role4'), {from: accountTen});
        // manage roles to cycle 
        await CommunityContractInstance.manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'), {from: accountTen});
        await CommunityContractInstance.manageRole(rolesTitle.get('role2'),rolesTitle.get('role3'), {from: accountTen});
        await CommunityContractInstance.manageRole(rolesTitle.get('role3'),rolesTitle.get('role4'), {from: accountTen});
        await CommunityContractInstance.manageRole(rolesTitle.get('role4'),rolesTitle.get('role1'), {from: accountTen});
        
        // account 1
        await CommunityContractInstance.addMembers([accountOne], {from: accountTen});
        await CommunityContractInstance.addRoles([accountOne], [rolesTitle.get('role1')], {from: accountTen});
        
        // check
        rolesList = (await CommunityContractInstance.getRoles(accountOne,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // account 2
        await CommunityContractInstance.addMembers([accountTwo], {from: accountOne});
        await CommunityContractInstance.addRoles([accountTwo], [rolesTitle.get('role2')], {from: accountOne});
        
        // account 3
        await CommunityContractInstance.addMembers([accountThree], {from: accountTwo});
        await CommunityContractInstance.addRoles([accountThree], [rolesTitle.get('role3')], {from: accountTwo});
        
        // account 4
        await CommunityContractInstance.addMembers([accountFourth], {from: accountThree});
        await CommunityContractInstance.addRoles([accountFourth], [rolesTitle.get('role4')], {from: accountThree});
        
        // account 4 remove account1 from role1
        await CommunityContractInstance.removeRoles([accountOne], [rolesTitle.get('role1')], {from: accountFourth});
        
        // check again
        rolesList = (await CommunityContractInstance.getRoles(accountOne,{from: accountTen}));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
    });
    
    it('test using params as array', async () => {
        
        await CommunityContractInstance.init({from: accountTen});
        // create roles
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role2'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role3'), {from: accountTen});
        await CommunityContractInstance.createRole(rolesTitle.get('role4'), {from: accountTen});
        
        // Adding
        await CommunityContractInstance.addMembers(
            [
                accountOne,
                accountTwo,
                accountThree,
                accountFourth,
                accountFive,
                accountSix,
                accountSeven
            ], {from: accountTen}
        );
        
        await CommunityContractInstance.addRoles(
            [
                accountOne,
                accountTwo,
                accountThree
            ], 
            [
                rolesTitle.get('role1'),
                rolesTitle.get('role2'),
                rolesTitle.get('role3'),
            ], {from: accountTen}
        );
        await CommunityContractInstance.addRoles(
            [
                accountFourth,
                accountFive
            ], 
            [
                rolesTitle.get('role2'),
                rolesTitle.get('role3')
            ], {from: accountTen}
        );
        await CommunityContractInstance.addRoles(
            [
                accountSix,
                accountSeven
            ], 
            [
                rolesTitle.get('role1'),
                rolesTitle.get('role2')
            ], {from: accountTen}
        );
        
        ///// checking by Members
        var rolesList;
        // accountOne
        rolesList = (await CommunityContractInstance.getRoles(accountOne,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountTwo
        rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountThree
        rolesList = (await CommunityContractInstance.getRoles(accountThree,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountFourth
        rolesList = (await CommunityContractInstance.getRoles(accountFourth,{from: accountTen}));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountFive
        rolesList = (await CommunityContractInstance.getRoles(accountFive,{from: accountTen}));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountSix
        rolesList = (await CommunityContractInstance.getRoles(accountSix,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        // accountSeven
        rolesList = (await CommunityContractInstance.getRoles(accountSeven,{from: accountTen}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role3')), 'outside role');
        assert.isFalse(rolesList.includes(rolesTitle.get('role4')), 'outside role');
        
        var memberCount;
        // role1
        memberCount = (await CommunityContractInstance.memberCount(rolesTitle.get('role1'),{from: accountTen}));
        assert.equal(memberCount, 5, "Wrong memberCount for role '"+rolesTitle.get('role1')+"'");
        // role2
        memberCount = (await CommunityContractInstance.memberCount(rolesTitle.get('role2'),{from: accountTen}));
        assert.equal(memberCount, 7, "Wrong memberCount for role '"+rolesTitle.get('role2')+"'");
        // role3
        memberCount = (await CommunityContractInstance.memberCount(rolesTitle.get('role3'),{from: accountTen}));
        assert.equal(memberCount, 5, "Wrong memberCount for role '"+rolesTitle.get('role3')+"'");
        // role4
        memberCount = (await CommunityContractInstance.memberCount(rolesTitle.get('role4'),{from: accountTen}));
        assert.equal(memberCount, 0, "Wrong memberCount for role '"+rolesTitle.get('role4')+"'");
        // all members
        memberCount = (await CommunityContractInstance.memberCount({from: accountTen}));
        assert.equal(memberCount, 7, "Wrong memberCount for all roles");
    });
    
    
    
    it('invites test', async () => {   

        // be sure that ganashe run with params 
        // ganache-cli --account "0xbde48e940a420314a923b9714be791b3d7917b186a7acd6bc0fabbd94016e980,300000000000000000000" 
        //             --account "0xd18dff433755e36145ed20c6d17e080b38ee1de8cf03c1d9acddce03e6a46748,300000000000000000000" 
//console.log(web3.currentProvider);        
        // let bufferPrivateKey1 = web3.currentProvider.wallets[accountOne.toLowerCase()].getPrivateKey();
        // let bufferPrivateKey2 = web3.currentProvider.wallets[accountTwo.toLowerCase()].getPrivateKey();    
         let privatekey1 = 'bde48e940a420314a923b9714be791b3d7917b186a7acd6bc0fabbd94016e980';
         let privatekey2 = 'd18dff433755e36145ed20c6d17e080b38ee1de8cf03c1d9acddce03e6a46748';

        var rolesList;
        
        await CommunityContractInstance.init({from: accountOne});
        
        const amountETHSendToContract = 2*10**18; // 2ETH
        
        // console.log(accountNine);
        // console.log(CommunityContractInstance.address);
        // console.log('0x'+amountETHSendToContract.toString(16));
        
        // send ETH to Contract      
        await web3.eth.sendTransaction({
            from:accountThree,
            to: CommunityContractInstance.address, 
            value: amountETHSendToContract
        });
        const CommunityContractInstanceStartingBalance = (await web3.eth.getBalance(CommunityContractInstance.address));
        // create webx user
        // Adding
        await CommunityContractInstance.addMembers([accountTen], {from: accountOne});
        await CommunityContractInstance.addRoles(
            [accountTen], 
            [rolesTitle.get('webx')], 
            {from: accountOne}
        );
        rolesList = (await CommunityContractInstance.getRoles(accountTen,{from: accountOne}));
        
        assert.isTrue(rolesList.includes(rolesTitle.get('webx')), 'outside webx role');
        
        // create roles
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne});
        await CommunityContractInstance.createRole(rolesTitle.get('role2'), {from: accountOne});
        await CommunityContractInstance.createRole(rolesTitle.get('role3'), {from: accountOne});
    
        // generate messages and signatures
            
        //let adminMsg = 'invite:'+CommunityContractInstance.address+':role1,role2,role3:GregMagarshak';
        let adminMsg = [
            'invite',
            CommunityContractInstance.address,
            [
                rolesTitle.get('role1'),
                rolesTitle.get('role2'),
                rolesTitle.get('role3')
            ].join(','),
            'GregMagarshak'
            ].join(':');;
        let recipientMsg = ''+accountTwo+':John Doe';
        
        let psignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(adminMsg)), new Buffer(privatekey1, 'hex')); 
        //let psignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(adminMsg)), bufferPrivateKey1); 
        let pSig = EthUtil.toRpcSig(psignature.v, psignature.r, psignature.s);
        
        let rpsignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(recipientMsg)), new Buffer(privatekey2, 'hex')); 
        //let rpsignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(recipientMsg)), bufferPrivateKey2); 
        let rpSig = EthUtil.toRpcSig(rpsignature.v, rpsignature.r, rpsignature.s);
        
        const recipientStartingBalance = (await web3.eth.getBalance(accountTwo));
        const accountTenStartingBalance = (await web3.eth.getBalance(accountTen));
        
        // imitate invitePrepare and check it in system
        await CommunityContractInstance.invitePrepare(pSig,rpSig, {from: accountTen});

        let invite = await CommunityContractInstance.inviteView(pSig, {from: accountTen});
        assert.isTrue(invite.exists, 'invite not found');
        assert.isTrue(invite.exists && invite.used==false, 'invite not used before');
        //console.log('(1)invite.gasCost=',invite.gasCost);
       
        // imitate inviteAccept
        await CommunityContractInstance.inviteAccept(adminMsg, pSig, recipientMsg, rpSig, {from: accountTen});

        const accountTenEndingBalance = (await web3.eth.getBalance(accountTen));

        const CommunityContractInstanceEndinggBalance = (await web3.eth.getBalance(CommunityContractInstance.address));
        const recipientEndingBalance = (await web3.eth.getBalance(accountTwo));

        // check roles of accountTwo
        rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role1 role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role2 role');
        assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role3 role');
        
        

        // let rewardAmount = await CommunityContractInstance.getRewardAmount();
        // let replenishAmount = await CommunityContractInstance.getReplenishAmount();
        
        // if (parseInt((BigNumber(CommunityContractInstanceStartingBalance).minus(BigNumber(rewardAmount))).toString(10))>0) {
        //     assert.isTrue(
        //         parseInt((BigNumber(CommunityContractInstanceStartingBalance).minus(BigNumber(CommunityContractInstanceEndinggBalance))).toString(10))>=0, 
        //         "wrong Reward count"
        //     );
        // }
        // assert.equal(BigNumber(recipientEndingBalance).minus(BigNumber(recipientStartingBalance)).toString(10), BigNumber(replenishAmount).toString(10), "wrong replenishAmount");
        
        
        await truffleAssert.reverts(
            CommunityContractInstance.invitePrepare(pSig,rpSig, {from: accountTen}),
            "Such signature is already exists"
        );

        
         await truffleAssert.reverts(
             
             CommunityContractInstance.inviteAccept(adminMsg, pSig, recipientMsg, rpSig, {from: accountTen}),
             "Such signature is already used"
         );
        
        
        
        assert.isTrue((await CommunityContractInstance.isInvited(accountTwo, accountOne)), 'does not store invited mapping');
        assert.isFalse((await CommunityContractInstance.isInvited(accountTwo, accountNine)), 'store wrong keys in invited mapping');
      
       
    });
    
    
});
