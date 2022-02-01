const { ethers, waffle } = require('hardhat');
const { BigNumber } = require('ethers');
const { expect } = require('chai');
const chai = require('chai');
const { time } = require('@openzeppelin/test-helpers');

const ZERO = BigNumber.from('0');
const ONE = BigNumber.from('1');
const TWO = BigNumber.from('2');
const THREE = BigNumber.from('3');
const FOUR = BigNumber.from('3');
const SEVEN = BigNumber.from('7');
const TEN = BigNumber.from('10');
const HUNDRED = BigNumber.from('100');
const THOUSAND = BigNumber.from('1000');


const ONE_ETH = ethers.utils.parseEther('1');

//const TOTALSUPPLY = ethers.utils.parseEther('1000000000');    
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD';

describe("CommunityContract tests", function () {
    const accounts = waffle.provider.getWallets();
    
    // Setup accounts.
    const owner = accounts[0];                     
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
      ['role5', 'Role#5'],
      ['cc_admins', 'AdMiNs']
    ]);

    var CommunityContractInstance;
    var CommunityContractFactory;
    beforeEach("deploying", async() => {
        CommunityContractFactory = await ethers.getContractFactory("CommunityContract");
        CommunityContractInstance = await CommunityContractFactory.deploy();
        await CommunityContractInstance.connect(owner).init();
    });

    it("creator must be owner and admin", async () => {
        
        var rolesList = (await CommunityContractInstance.connect(owner)["getRoles(address)"](owner.address));
        expect(rolesList.includes(rolesTitle.get('owners'))).to.be.eq(true); // outside OWNERS role
        expect(rolesList.includes(rolesTitle.get('admins'))).to.be.eq(true); // outside ADMINS role

    });
    
    it("can add member", async () => {
        
        await CommunityContractInstance.addMembers([accountTwo.address]);
        var rolesList = (await CommunityContractInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true); // outside members role
    });
    
    it('can remove member', async () => {
        
        var rolesList;

        await CommunityContractInstance.addMembers([accountTwo.address]);
        rolesList = (await CommunityContractInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true);
        
        await CommunityContractInstance.removeMembers([accountTwo.address]);
        rolesList = (await CommunityContractInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(false);
    });
    
    
    it('can create new role', async () => {
        await expect(CommunityContractInstance.connect(accountThree).createRole(rolesTitle.get('role1'))).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('owners')+"''");
        await expect(CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('owners'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('admins'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('members'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('cc_admins'))).to.be.revertedWith("Such role is already exists");
        
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await expect(CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role1'))).to.be.revertedWith("Such role is already exists");
        
    });
    
    it('can manage role', async () => {
        
        // create two roles
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        
        // ownbale check
        await expect(
            CommunityContractInstance.connect(accountThree).manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'))
        ).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('owners')+"'");
        
        // role exist check
        await expect(
            CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role4'),rolesTitle.get('role2'))
        ).to.be.revertedWith("Source role does not exists");
        await expect(
            CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role1'),rolesTitle.get('role4'))
        ).to.be.revertedWith("Source role does not exists");
        
        // manage role
        await CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'));
        //add member
        await CommunityContractInstance.connect(accountOne).addMembers([accountTwo.address]);

        // added member to none-exists member
        await expect(
            CommunityContractInstance.connect(accountOne).grantRoles([accountThree.address], [rolesTitle.get('role1')])
        ).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('members')+"'");
        

        // added member to none-exists role 
        await expect(
            CommunityContractInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role4')])
        ).to.be.revertedWith("Such role '"+rolesTitle.get('role4')+"' does not exists");
        
        await CommunityContractInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role1')]);

        //add member by accountTwo
        await CommunityContractInstance.connect(accountTwo).addMembers([accountFourth.address]);

        //add role2 to accountFourth by accountTwo
        await CommunityContractInstance.connect(accountTwo).grantRoles([accountFourth.address], [rolesTitle.get('role2')]);

    });
    
    it('can remove account from role', async () => {

        var rolesList;
        
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        //add member
        await CommunityContractInstance.connect(accountOne).addMembers([accountTwo.address]);
        // add member to role
        await CommunityContractInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role1')]);
        
        // check that accountTwo got `get('role1')`
        rolesList = (await CommunityContractInstance.connect(accountOne)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); // 'outside role'
        
        // remove
        await CommunityContractInstance.connect(accountOne).revokeRoles([accountTwo.address], [rolesTitle.get('role1')]);
        // check removing
        rolesList = (await CommunityContractInstance.connect(accountOne)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); // 'outside role'
        
        // check allowance to remove default role `members`
        await expect(
            CommunityContractInstance.connect(accountOne).revokeRoles([accountTwo.address], [rolesTitle.get('members')])
        ).to.be.revertedWith("Can not remove role '" +rolesTitle.get('members')+"'");
            
    });
    
    it('possible to grant with cycle. ', async () => {
        
        // create roles
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role3'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role4'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role5'));
        // manage roles to cycle 
        await CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role2'),rolesTitle.get('role3'));
        await CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role3'),rolesTitle.get('role4'));
        await CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role4'),rolesTitle.get('role5'));
        await CommunityContractInstance.connect(accountOne).manageRole(rolesTitle.get('role5'),rolesTitle.get('role2'));
        
        // account2
        await CommunityContractInstance.connect(accountOne).addMembers([accountTwo.address]);
        await CommunityContractInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role2')]);
        
        // check
        rolesList = await CommunityContractInstance.connect(accountOne)["getRoles(address)"](accountTwo.address);
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        
        // account 3
        await CommunityContractInstance.connect(accountTwo).addMembers([accountThree.address]);
        await CommunityContractInstance.connect(accountTwo).grantRoles([accountThree.address], [rolesTitle.get('role3')]);
        
        // account 4
        await CommunityContractInstance.connect(accountThree).addMembers([accountFourth.address]);
        await CommunityContractInstance.connect(accountThree).grantRoles([accountFourth.address], [rolesTitle.get('role4')]);
        
        // account 5
        await CommunityContractInstance.connect(accountFourth).addMembers([accountFive.address]);
        await CommunityContractInstance.connect(accountFourth).grantRoles([accountFive.address], [rolesTitle.get('role5')]);
        
        // account 5 remove account2 from role2
        await CommunityContractInstance.connect(accountFive).revokeRoles([accountTwo.address], [rolesTitle.get('role2')]);
        
        // check again
        rolesList = await CommunityContractInstance.connect(accountOne)["getRoles(address)"](accountTwo.address);
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(false); 
    });
       
    xit('invites test', async () => {   


        let privatekey1 = accountOne._signingKey()["privateKey"];
        let privatekey2 = accountTwo._signingKey()["privateKey"];

        var rolesList;
    
        const price = ethers.utils.parseEther('1');
        const amountETHSendToContract = price.mul(TWO); // 2ETH
        
    
        // send ETH to Contract      
        await accountThree.sendTransaction({
            to: CommunityContractInstance.address, 
            value: amountETHSendToContract
        });

        const CommunityContractInstanceStartingBalance = (await ethers.provider.getBalance(CommunityContractInstance.address));
        // create webx user
        // Adding
        await CommunityContractInstance.connect(accountOne).addMembers([accountTen.address]);
        await CommunityContractInstance.connect(accountOne).grantRoles(
            [accountTen.address], 
            [rolesTitle.get('webx')]
        );
        rolesList = (await CommunityContractInstance.connect(accountOne)["getRoles(address)"](accountTen.address));
        expect(rolesList.includes(rolesTitle.get('webx'))).to.be.eq(true); 
        
        // create roles
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        await CommunityContractInstance.connect(accountOne).createRole(rolesTitle.get('role3'));
    
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
        let recipientMsg = ''+accountTwo.address+':John Doe';
        
        //!let psignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(adminMsg)), new Buffer(privatekey1, 'hex')); 
        let psignature = await accountOne.signMessage(adminMsg);
     console.log(psignature);   
        //let pSig = EthUtil.toRpcSig(psignature.v, psignature.r, psignature.s);
        let sig = ethers.utils.splitSignature(psignature);
console.log(sig);
console.log(ethers.utils);
//hashMessage
//

var r = psignature.substr(0,66)
// "0x9242685bf161793cc25603c231bc2f568eb630ea16aa137d2664ac8038825608"

var s = "0x" + psignature.substr(66,64)
// "0x4f8ae3bd7535248d0bd448298cc2e2071e56992d0774dc340c368ae950852ada"

var v =  "0x" + psignature.substr(130,2);//28
// 28

console.log(r,s,v);


//         let rpsignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(recipientMsg)), new Buffer(privatekey2, 'hex')); 
//         //let rpsignature = EthUtil.ecsign(EthUtil.hashPersonalMessage(new Buffer(recipientMsg)), bufferPrivateKey2); 
//         let rpSig = EthUtil.toRpcSig(rpsignature.v, rpsignature.r, rpsignature.s);
        
//         const recipientStartingBalance = (await web3.eth.getBalance(accountTwo));
//         const accountTenStartingBalance = (await web3.eth.getBalance(accountTen));
        
//         // imitate invitePrepare and check it in system
//         await CommunityContractInstance.invitePrepare(pSig,rpSig, {from: accountTen});

//         let invite = await CommunityContractInstance.inviteView(pSig, {from: accountTen});
//         assert.isTrue(invite.exists, 'invite not found');
//         assert.isTrue(invite.exists && invite.used==false, 'invite not used before');
//         //console.log('(1)invite.gasCost=',invite.gasCost);
       
//         // imitate inviteAccept
//         await CommunityContractInstance.inviteAccept(adminMsg, pSig, recipientMsg, rpSig, {from: accountTen});

//         const accountTenEndingBalance = (await web3.eth.getBalance(accountTen));

//         const CommunityContractInstanceEndinggBalance = (await web3.eth.getBalance(CommunityContractInstance.address));
//         const recipientEndingBalance = (await web3.eth.getBalance(accountTwo));

//         // check roles of accountTwo
//         rolesList = (await CommunityContractInstance.getRoles(accountTwo,{from: accountOne}));
//         assert.isTrue(rolesList.includes(rolesTitle.get('role1')), 'outside role1 role');
//         assert.isTrue(rolesList.includes(rolesTitle.get('role2')), 'outside role2 role');
//         assert.isTrue(rolesList.includes(rolesTitle.get('role3')), 'outside role3 role');
        
        

//         // let rewardAmount = await CommunityContractInstance.getRewardAmount();
//         // let replenishAmount = await CommunityContractInstance.getReplenishAmount();
        
//         // if (parseInt((BigNumber(CommunityContractInstanceStartingBalance).minus(BigNumber(rewardAmount))).toString(10))>0) {
//         //     assert.isTrue(
//         //         parseInt((BigNumber(CommunityContractInstanceStartingBalance).minus(BigNumber(CommunityContractInstanceEndinggBalance))).toString(10))>=0, 
//         //         "wrong Reward count"
//         //     );
//         // }
//         // assert.equal(BigNumber(recipientEndingBalance).minus(BigNumber(recipientStartingBalance)).toString(10), BigNumber(replenishAmount).toString(10), "wrong replenishAmount");
        
        
//         await truffleAssert.reverts(
//             CommunityContractInstance.invitePrepare(pSig,rpSig, {from: accountTen}),
//             "Such signature is already exists"
//         );

        
//          await truffleAssert.reverts(
             
//              CommunityContractInstance.inviteAccept(adminMsg, pSig, recipientMsg, rpSig, {from: accountTen}),
//              "Such signature is already used"
//          );
        
    
//         assert.isTrue((await CommunityContractInstance.isInvited(accountOne, accountTwo)), 'does not store invited mapping');
//         assert.isFalse((await CommunityContractInstance.isInvited(accountNine, accountTwo)), 'store wrong keys in invited mapping');
      
        
    });
    describe("tests", function () {
        beforeEach("deploying", async() => {
            
            CommunityContractInstance = await CommunityContractFactory.deploy();
            await CommunityContractInstance.connect(accountTen).init();
        });
        it('test using params as array', async () => {

            // create roles
            await CommunityContractInstance.connect(accountTen).createRole(rolesTitle.get('role1'));
            await CommunityContractInstance.connect(accountTen).createRole(rolesTitle.get('role2'));
            await CommunityContractInstance.connect(accountTen).createRole(rolesTitle.get('role3'));
            await CommunityContractInstance.connect(accountTen).createRole(rolesTitle.get('role4'));

            // Adding
            await CommunityContractInstance.connect(accountTen).addMembers(
                [
                    accountOne.address,
                    accountTwo.address,
                    accountThree.address,
                    accountFourth.address,
                    accountFive.address,
                    accountSix.address,
                    accountSeven.address
                ]
            );

            await CommunityContractInstance.connect(accountTen).grantRoles(
                [
                    accountOne.address,
                    accountTwo.address,
                    accountThree.address
                ], 
                [
                    rolesTitle.get('role1'),
                    rolesTitle.get('role2'),
                    rolesTitle.get('role3'),
                ]
            );
            await CommunityContractInstance.connect(accountTen).grantRoles(
                [
                    accountFourth.address,
                    accountFive.address
                ], 
                [
                    rolesTitle.get('role2'),
                    rolesTitle.get('role3')
                ]
            );
            await CommunityContractInstance.connect(accountTen).grantRoles(
                [
                    accountSix.address,
                    accountSeven.address
                ], 
                [
                    rolesTitle.get('role1'),
                    rolesTitle.get('role2')
                ]
            );

            ///// checking by Members
            var rolesList;
            // accountOne
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountOne.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountTwo
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountTwo.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountThree
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountThree.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountFourth
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountFourth.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountFive
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountFive.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountSix
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountSix.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(false); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
            // accountSeven
            rolesList = (await CommunityContractInstance.connect(accountTen)["getRoles(address)"](accountSeven.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(false); 
            expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 

            var memberCount;
            // role1
            memberCount = (await CommunityContractInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role1')));
            expect(memberCount).to.be.eq(5);
            // role2
            memberCount = (await CommunityContractInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role2')));
            expect(memberCount).to.be.eq(7);
            // role3
            memberCount = (await CommunityContractInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role3')));
            expect(memberCount).to.be.eq(5);
            // role4
            memberCount = (await CommunityContractInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role4')));
            expect(memberCount).to.be.eq(0);
            // all members
            memberCount = (await CommunityContractInstance.connect(accountTen)["memberCount()"]());
            expect(memberCount).to.be.eq(7);

        });

      
    });


/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////


});