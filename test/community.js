const BN = require('bn.js'); // https://github.com/indutny/bn.js
const util = require('util');
const CommunityContract = artifacts.require("CommunityContract");
const CommunityContractMock = artifacts.require("CommunityContractMock");
//const ERC20MintableToken = artifacts.require("ERC20Mintable");
const truffleAssert = require('truffle-assertions');

const helper = require("../helpers/truffleTestHelper");

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
      ['role1', 'Role#1'],
      ['role2', 'Role#2'],
      ['role3', 'Role#3'],
      ['role4', 'Role#4'],
      ['cc_admins', 'AdMiNs']
    ]);
    
    it('creator must be owner and admin', async () => {
        var CommunityContractInstance = await CommunityContract.new({from: accountOne});
        var rolesList = (await CommunityContractInstance.getRoles(accountOne));
        assert.isTrue(rolesList.includes(rolesTitle.get('owners')), 'outside OWNERS role');
        assert.isTrue(rolesList.includes(rolesTitle.get('admins')), 'outside ADMINS role');
    });
    
    it('can add member', async () => {
        var CommunityContractInstance = await CommunityContract.new({from: accountOne});
        
        await CommunityContractInstance.addMember(accountTwo);
        var rolesList = (await CommunityContractInstance.getRoles(accountTwo));
        assert.isTrue(rolesList.includes(rolesTitle.get('members')), 'outside members role');
    });
    
    it('can remove member', async () => {
        var rolesList;
        var CommunityContractInstance = await CommunityContract.new({from: accountOne});
        
        await CommunityContractInstance.addMember(accountTwo);
        rolesList = (await CommunityContractInstance.getRoles(accountTwo));
        assert.isTrue(rolesList.includes(rolesTitle.get('members')), 'outside members role');
        
        await CommunityContractInstance.removeMember(accountTwo);
        rolesList = (await CommunityContractInstance.getRoles(accountTwo));
        assert.isFalse(rolesList.includes(rolesTitle.get('members')), 'outside members role');
    });
    
    
    it('can create new role', async () => {
        var CommunityContractInstance = await CommunityContract.new({from: accountOne});
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
        var CommunityContractInstance = await CommunityContractMock.new({from: accountOne});
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
        await CommunityContractInstance.addMember(accountTwo, {from: accountOne});

        // added member to none-exists member
        await truffleAssert.reverts(
            CommunityContractInstance.addMemberRole(accountThree, rolesTitle.get('role1'), {from: accountOne}),
            "Target account must be with role '" +rolesTitle.get('members')+"'"
        );

         // added member to none-exists role 
        await truffleAssert.reverts(
            CommunityContractInstance.addMemberRole(accountTwo, rolesTitle.get('role4'), {from: accountOne}),
            "Such role '"+rolesTitle.get('role4')+"' does not exists"
        );
       
        await CommunityContractInstance.addMemberRole(accountTwo, rolesTitle.get('role1'), {from: accountOne});

        //add member by accountTwo
        await CommunityContractInstance.addMember(accountFourth, {from: accountTwo});
       
        //add role2 to accountFourth by accountTwo
        await CommunityContractInstance.addMemberRole(accountFourth, rolesTitle.get('role2'), {from: accountTwo});
        
    });
    
    it('can remove account from role', async () => {
        var rolesList;
        var CommunityContractInstance = await CommunityContractMock.new({from: accountOne});
        await CommunityContractInstance.createRole(rolesTitle.get('role1'), {from: accountOne});
        //add member
        await CommunityContractInstance.addMember(accountTwo, {from: accountOne});
        // add member to role
        await CommunityContractInstance.addMemberRole(accountTwo, rolesTitle.get('role1'), {from: accountOne});
        
        // check that accountTwo got `get('role1')`
        rolesList = (await CommunityContractInstance.getRoles(accountTwo));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // remove
        await CommunityContractInstance.removeMemberRole(accountTwo, rolesTitle.get('role1'), {from: accountOne});
        // check removing
        rolesList = (await CommunityContractInstance.getRoles(accountTwo));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // check allowance to remove default role `members`
        await truffleAssert.reverts(
            CommunityContractInstance.removeMemberRole(accountTwo, rolesTitle.get('members'), {from: accountOne}),
            "Can not remove role '" +rolesTitle.get('members')+"'"
        );
    });
    
    
    
    it('possible to grant with cycle. ', async () => {
        var CommunityContractInstance = await CommunityContractMock.new({from: accountTen});
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
        await CommunityContractInstance.addMember(accountOne, {from: accountTen});
        await CommunityContractInstance.addMemberRole(accountOne, rolesTitle.get('role1'), {from: accountTen});
        
        // check
        rolesList = (await CommunityContractInstance.getRoles(accountOne));
        assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role');
        
        // account 2
        await CommunityContractInstance.addMember(accountTwo, {from: accountOne});
        await CommunityContractInstance.addMemberRole(accountTwo, rolesTitle.get('role2'), {from: accountOne});
        
        // account 3
        await CommunityContractInstance.addMember(accountThree, {from: accountTwo});
        await CommunityContractInstance.addMemberRole(accountThree, rolesTitle.get('role3'), {from: accountTwo});
        
        // account 4
        await CommunityContractInstance.addMember(accountFourth, {from: accountThree});
        await CommunityContractInstance.addMemberRole(accountFourth, rolesTitle.get('role4'), {from: accountThree});
        
        // account 4 remove account1 from role1
        await CommunityContractInstance.removeMemberRole(accountOne, rolesTitle.get('role1'), {from: accountFourth});
        
        // check again
        rolesList = (await CommunityContractInstance.getRoles(accountOne));
        assert.isFalse(rolesList.includes(rolesTitle.get('role1')), 'outside role');
    });
   
});
