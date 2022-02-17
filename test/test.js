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

describe("Community tests", function () {
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
    var rolesTitle = new Map([
      ['owners', 'owners'],
      ['admins', 'admins'],
      ['members', 'members'],
      ['relayers', 'relayers'],
      ['role1', 'Role#1'],
      ['role2', 'Role#2'],
      ['role3', 'Role#3'],
      ['role4', 'Role#4'],
      ['role5', 'Role#5'],
      ['cc_admins', 'AdMiNs']
    ]);
    var CommunityInstance;
    var CommunityFactory;
    beforeEach("deploying", async() => {
        CommunityFactory = await ethers.getContractFactory("Community");
        CommunityInstance = await CommunityFactory.deploy();
        await CommunityInstance.connect(owner).init();
    });

    it("creator must be owner and admin", async () => {
        
        var rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](owner.address));
        expect(rolesList.includes(rolesTitle.get('owners'))).to.be.eq(true); // outside OWNERS role
        expect(rolesList.includes(rolesTitle.get('admins'))).to.be.eq(true); // outside ADMINS role

    });
    
    it("can add member", async () => {
        
        await CommunityInstance.addMembers([accountTwo.address]);
        var rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true); // outside members role
    });
    
    it('can remove member', async () => {
        
        var rolesList;

        await CommunityInstance.addMembers([accountTwo.address]);
        rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true);
        
        await CommunityInstance.removeMembers([accountTwo.address]);
        rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(false);
    });
    
    
    it('can create new role', async () => {
        await expect(CommunityInstance.connect(accountThree).createRole(rolesTitle.get('role1'))).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('owners')+"''");
        await expect(CommunityInstance.connect(accountOne).createRole(rolesTitle.get('owners'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityInstance.connect(accountOne).createRole(rolesTitle.get('admins'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityInstance.connect(accountOne).createRole(rolesTitle.get('members'))).to.be.revertedWith("Such role is already exists");
        await expect(CommunityInstance.connect(accountOne).createRole(rolesTitle.get('cc_admins'))).to.be.revertedWith("Such role is already exists");
        
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await expect(CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role1'))).to.be.revertedWith("Such role is already exists");
        
    });
    
    it('can manage role', async () => {
        
        // create two roles
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        
        // ownbale check
        await expect(
            CommunityInstance.connect(accountThree).manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'))
        ).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('owners')+"'");
        
        // role exist check
        await expect(
            CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role4'),rolesTitle.get('role2'))
        ).to.be.revertedWith("Source role does not exists");
        await expect(
            CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role1'),rolesTitle.get('role4'))
        ).to.be.revertedWith("Source role does not exists");
        
        // manage role
        await CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role1'),rolesTitle.get('role2'));
        //add member
        await CommunityInstance.connect(accountOne).addMembers([accountTwo.address]);

        // added member to none-exists member
        await expect(
            CommunityInstance.connect(accountOne).grantRoles([accountThree.address], [rolesTitle.get('role1')])
        ).to.be.revertedWith("Target account must be with role '" +rolesTitle.get('members')+"'");
        

        // added member to none-exists role 
        await expect(
            CommunityInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role4')])
        ).to.be.revertedWith("Such role '"+rolesTitle.get('role4')+"' does not exists");
        
        await CommunityInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role1')]);

        //add member by accountTwo
        await CommunityInstance.connect(accountTwo).addMembers([accountFourth.address]);

        //add role2 to accountFourth by accountTwo
        await CommunityInstance.connect(accountTwo).grantRoles([accountFourth.address], [rolesTitle.get('role2')]);

    });
    
    it('can remove account from role', async () => {

        var rolesList;
        
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        //add member
        await CommunityInstance.connect(accountOne).addMembers([accountTwo.address]);
        // add member to role
        await CommunityInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role1')]);
        
        // check that accountTwo got `get('role1')`
        rolesList = (await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); // 'outside role'
        
        // remove
        await CommunityInstance.connect(accountOne).revokeRoles([accountTwo.address], [rolesTitle.get('role1')]);
        // check removing
        rolesList = (await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); // 'outside role'
        
        // check allowance to remove default role `members`
        await expect(
            CommunityInstance.connect(accountOne).revokeRoles([accountTwo.address], [rolesTitle.get('members')])
        ).to.be.revertedWith("Can not remove role '" +rolesTitle.get('members')+"'");
            
    });
    
    it('possible to grant with cycle. ', async () => {
        
        // create roles
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role3'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role4'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role5'));
        // manage roles to cycle 
        await CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role2'),rolesTitle.get('role3'));
        await CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role3'),rolesTitle.get('role4'));
        await CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role4'),rolesTitle.get('role5'));
        await CommunityInstance.connect(accountOne).manageRole(rolesTitle.get('role5'),rolesTitle.get('role2'));
        
        // account2
        await CommunityInstance.connect(accountOne).addMembers([accountTwo.address]);
        await CommunityInstance.connect(accountOne).grantRoles([accountTwo.address], [rolesTitle.get('role2')]);
        
        // check
        rolesList = await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTwo.address);
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        
        // account 3
        await CommunityInstance.connect(accountTwo).addMembers([accountThree.address]);
        await CommunityInstance.connect(accountTwo).grantRoles([accountThree.address], [rolesTitle.get('role3')]);
        
        // account 4
        await CommunityInstance.connect(accountThree).addMembers([accountFourth.address]);
        await CommunityInstance.connect(accountThree).grantRoles([accountFourth.address], [rolesTitle.get('role4')]);
        
        // account 5
        await CommunityInstance.connect(accountFourth).addMembers([accountFive.address]);
        await CommunityInstance.connect(accountFourth).grantRoles([accountFive.address], [rolesTitle.get('role5')]);
        
        // account 5 remove account2 from role2
        await CommunityInstance.connect(accountFive).revokeRoles([accountTwo.address], [rolesTitle.get('role2')]);
        
        // check again
        rolesList = await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTwo.address);
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(false); 
    });
       
    it('invites test', async () => {   


        let privatekey1 = accountOne._signingKey()["privateKey"];
        let privatekey2 = accountTwo._signingKey()["privateKey"];

        var rolesList;
    
        const price = ethers.utils.parseEther('1');
        const amountETHSendToContract = price.mul(TWO); // 2ETH
        
    
        // send ETH to Contract      
        await accountThree.sendTransaction({
            to: CommunityInstance.address, 
            value: amountETHSendToContract
        });

        const CommunityInstanceStartingBalance = (await ethers.provider.getBalance(CommunityInstance.address));
        // create relayers user
        // Adding
        await CommunityInstance.connect(accountOne).addMembers([accountTen.address]);
        await CommunityInstance.connect(accountOne).grantRoles(
            [accountTen.address], 
            [rolesTitle.get('relayers')]
        );
        rolesList = (await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTen.address));
        expect(rolesList.includes(rolesTitle.get('relayers'))).to.be.eq(true); 
        
        // create roles
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role1'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role2'));
        await CommunityInstance.connect(accountOne).createRole(rolesTitle.get('role3'));
    
        // generate messages and signatures
            
        //let adminMsg = 'invite:'+CommunityInstance.address+':role1,role2,role3:GregMagarshak';
        let adminMsg = [
            'invite',
            CommunityInstance.address,
            [
                rolesTitle.get('role1'),
                rolesTitle.get('role2'),
                rolesTitle.get('role3')
            ].join(','),
            'GregMagarshak'
            ].join(':');;
        let recipientMsg = ''+accountTwo.address+':John Doe';
        
        let pSig = await accountOne.signMessage(adminMsg);

        let rpSig = await accountTwo.signMessage(recipientMsg);

        const recipientStartingBalance = (await ethers.provider.getBalance(accountTwo.address));
        const accountTenStartingBalance = (await ethers.provider.getBalance(accountTen.address));

        // imitate invitePrepare and check it in system
        await CommunityInstance.connect(accountTen).invitePrepare(pSig,rpSig);

        let invite = await CommunityInstance.connect(accountTen).inviteView(pSig);
        expect(invite.exists).to.be.true; // 'invite not found';
        expect(invite.exists && invite.used==false).to.be.true; // 'invite not used before'
        //console.log('(1)invite.gasCost=',invite.gasCost);
       
        // imitate inviteAccept
        await CommunityInstance.connect(accountTen).inviteAccept(adminMsg, pSig, recipientMsg, rpSig);

        const accountTenEndingBalance = await ethers.provider.getBalance(accountTen.address);
        const recipientEndingBalance = await ethers.provider.getBalance(accountTwo.address);
        const CommunityInstanceEndingBalance = (await ethers.provider.getBalance(CommunityInstance.address));
        
        // check roles of accountTwo
        rolesList = await CommunityInstance.connect(accountOne)["getRoles(address)"](accountTwo.address);
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
         

        let rewardAmount = await CommunityInstance.REWARD_AMOUNT();
        let replenishAmount = await CommunityInstance.REPLENISH_AMOUNT();
        
        // if (parseInt((BigNumber(CommunityInstanceStartingBalance).minus(BigNumber(rewardAmount))).toString(10))>0) {
        //     assert.isTrue(
        //         parseInt((BigNumber(CommunityInstanceStartingBalance).minus(BigNumber(CommunityInstanceEndinggBalance))).toString(10))>=0, 
        //         "wrong Reward count"
        //     );
        // }

        expect(recipientEndingBalance.sub(recipientStartingBalance)).to.be.eq(replenishAmount); // "wrong replenishAmount"
        
        await expect(
            CommunityInstance.connect(accountTen).invitePrepare(pSig,rpSig)
        ).to.be.revertedWith("Such signature is already exists");
        
        await expect(
            CommunityInstance.connect(accountTen).inviteAccept(adminMsg, pSig, recipientMsg, rpSig)
        ).to.be.revertedWith("Such signature is already used");
         
        await expect(await CommunityInstance.invitedBy(accountTwo.address)).to.be.eq(accountOne.address); //'does not store invited mapping'
        await expect(await CommunityInstance.invitedBy(accountTwo.address)).not.to.be.eq(accountNine.address); //'store wrong keys in invited mapping'
        
      
        
    });

    
    it('test using params as array', async () => {

        // create roles
        await CommunityInstance.connect(owner).createRole(rolesTitle.get('role1'));
        await CommunityInstance.connect(owner).createRole(rolesTitle.get('role2'));
        await CommunityInstance.connect(owner).createRole(rolesTitle.get('role3'));
        await CommunityInstance.connect(owner).createRole(rolesTitle.get('role4'));

        // Adding
        await CommunityInstance.connect(owner).addMembers(
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

        await CommunityInstance.connect(owner).grantRoles(
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
        await CommunityInstance.connect(owner).grantRoles(
            [
                accountFourth.address,
                accountFive.address
            ], 
            [
                rolesTitle.get('role2'),
                rolesTitle.get('role3')
            ]
        );
        await CommunityInstance.connect(owner).grantRoles(
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
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountOne.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountTwo
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountTwo.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountThree
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountThree.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountFourth
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFourth.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountFive
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFive.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountSix
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountSix.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(false); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 
        // accountSeven
        rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountSeven.address));
        expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
        expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(false); 
        expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 

        var memberCount;
        // role1
        memberCount = (await CommunityInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role1')));
        expect(memberCount).to.be.eq(5);
        // role2
        memberCount = (await CommunityInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role2')));
        expect(memberCount).to.be.eq(7);
        // role3
        memberCount = (await CommunityInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role3')));
        expect(memberCount).to.be.eq(5);
        // role4
        memberCount = (await CommunityInstance.connect(accountTen)["memberCount(string)"](rolesTitle.get('role4')));
        expect(memberCount).to.be.eq(0);
        // all members
        memberCount = (await CommunityInstance.connect(accountTen)["memberCount()"]());
        expect(memberCount).to.be.eq(7);

    });



/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////


});

describe("CommunityERC721 tests", function () {
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
    
    var rolesTitle = new Map([
      ['owners', 'owners'],
      ['admins', 'admins'],
      ['members', 'members'],
      ['relayers', 'relayers'],
      ['role1', 'Role#1'],
      ['role2', 'Role#2'],
      ['role3', 'Role#3'],
      ['role4', 'Role#4'],
      ['role5', 'Role#5'],
      ['cc_admins', 'AdMiNs']
    ]);

    var rolesIndex = new Map([
      ['owners', 1],
      ['admins', 2],
      ['members', 3],
      ['relayers', 4],
      ['role1', 5],
      ['role2', 6],
      ['role3', 7],
      ['role4', 9],
      ['role5', 10],
      ['cc_admins', 11]
    ]);

    var CommunityInstance;
    var CommunityFactory;
    beforeEach("deploying", async() => {
        CommunityFactory = await ethers.getContractFactory("CommunityERC721");
        CommunityInstance = await CommunityFactory.deploy();
        await CommunityInstance.connect(accountTen).init();
    });

    it("name should be `Community`", async () => {
        var name = await CommunityInstance.connect(accountTen).name();
        await expect(name).to.be.eq("Community");
    });

    it("symbol should be `Community`", async () => {
        var name = await CommunityInstance.connect(accountTen).symbol();
        await expect(name).to.be.eq("Community");
    });
    
    describe("erc721 tokens tests", function () {
        let generateTokenId = function(address, roleIndex) {
            
            // roleIndex<<160 + address
            let t = BigNumber.from("0x"+roleIndex+"0000000000000000000000000000000000000000")
            let t2 = BigNumber.from(address);
            return t.add(t2);
        }
        beforeEach("deploying", async() => {

             // create roles
            await CommunityInstance.connect(accountTen).createRole(rolesTitle.get('role1'));
            await CommunityInstance.connect(accountTen).createRole(rolesTitle.get('role2'));
            await CommunityInstance.connect(accountTen).createRole(rolesTitle.get('role3'));
            await CommunityInstance.connect(accountTen).createRole(rolesTitle.get('role4'));

            // Adding
            await CommunityInstance.connect(accountTen).addMembers(
                [
                    accountOne.address,
                    accountTwo.address,
                    accountThree.address,
                    accountFourth.address,
                    accountSix.address,
                ]
            );

            await CommunityInstance.connect(accountTen).grantRoles(
                [accountOne.address], 
                [rolesTitle.get('role1')]
            );

            await CommunityInstance.connect(accountTen).grantRoles(
                [accountTwo.address], 
                [rolesTitle.get('role2')]
            );

            await CommunityInstance.connect(accountTen).grantRoles(
                [accountThree.address,
                accountSix.address], 
                [
                    rolesTitle.get('role3')
                ]
            );
            
        });

        
        it("should correct balanceOf for holders", async () => {
            // using "+ONE" because any account in community have extra role "members"
            expect(await CommunityInstance.balanceOf(accountOne.address)).to.be.eq(ONE.add(ONE));
            expect(await CommunityInstance.balanceOf(accountTwo.address)).to.be.eq(ONE.add(ONE));
            expect(await CommunityInstance.balanceOf(accountThree.address)).to.be.eq(ONE.add(ONE));
            expect(await CommunityInstance.balanceOf(accountFourth.address)).to.be.eq(ZERO.add(ONE));
        });

        it("should correct balanceOf for none-holders", async () => {
            expect(await CommunityInstance.balanceOf(accountFive.address)).to.be.eq(ZERO);
        });

        it("should be owner of token", async () => {
            expect(
                await CommunityInstance.ownerOf(generateTokenId(accountOne.address, rolesIndex.get('role1')))
            ).to.be.eq(accountOne.address);
            expect(
                await CommunityInstance.ownerOf(generateTokenId(accountTwo.address, rolesIndex.get('role2')))
            ).to.be.eq(accountTwo.address);
            expect(
                await CommunityInstance.ownerOf(generateTokenId(accountThree.address, rolesIndex.get('role3')))
            ).to.be.eq(accountThree.address);
            
        });

        it("shouldn't be owner of token", async () => {
            expect(
                await CommunityInstance.ownerOf(generateTokenId(accountOne.address, rolesIndex.get('role2')))
            ).to.be.eq(ZERO_ADDRESS);
        });

        it("shouldn't approve", async () => {
            await expect(
                CommunityInstance.connect(accountOne).approve(
                    accountFourth.address,
                    generateTokenId(accountOne.address, rolesIndex.get('role1'))
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("shouldn't transferFrom", async () => {
            await expect(
                CommunityInstance.connect(accountOne).transferFrom(
                    accountOne.address,
                    accountFourth.address,
                    generateTokenId(accountOne.address, rolesIndex.get('role1'))
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("shouldn't safeTransferFrom", async () => {
            await expect(
                CommunityInstance.connect(accountOne)["safeTransferFrom(address,address,uint256)"](
                    accountOne.address,
                    accountFourth.address,
                    generateTokenId(accountOne.address, rolesIndex.get('role1'))
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");

            await expect(
                CommunityInstance.connect(accountOne)["safeTransferFrom(address,address,uint256,bytes)"](
                    accountOne.address,
                    accountFourth.address,
                    generateTokenId(accountOne.address, rolesIndex.get('role1')),
                    []
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("shouldn't getApproved", async () => {
            await expect(
                CommunityInstance.connect(accountOne).getApproved(
                    generateTokenId(accountOne.address, rolesIndex.get('role1'))
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("shouldn't setApprovalForAll", async () => {
            await expect(
                CommunityInstance.connect(accountOne).setApprovalForAll(
                    accountOne.address,
                    true
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("shouldn't isApprovedForAll", async () => {
            await expect(
                CommunityInstance.connect(accountOne).isApprovedForAll(
                    accountOne.address,
                    accountTwo.address
                )
            ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
        });

        it("check supportsInterface", async () => {
            let interfaceIERC721UpgradeableId = "0x80ac58cd";
            let interfaceIERC721MetadataUpgradeableId = "0x5b5e139f";
            let interfaceIERC165UpgradeableId = "0x01ffc9a7";
            let interfaceWrongId = "0x00ff0000";
             
            await expect(
                await CommunityInstance.connect(accountOne).supportsInterface(interfaceIERC721UpgradeableId)
            ).to.be.true;
            await expect(
                await CommunityInstance.connect(accountOne).supportsInterface(interfaceIERC721MetadataUpgradeableId)
            ).to.be.true;
            await expect(
                await CommunityInstance.connect(accountOne).supportsInterface(interfaceIERC165UpgradeableId)
            ).to.be.true;
            await expect(
                await CommunityInstance.connect(accountOne).supportsInterface(interfaceWrongId)
            ).to.be.false;
        });

        it("check setRoleURI and setExtraURI", async () => {
            let uri = "http://google.com/";
            let extrauri = "http://google.com/extra";

            await expect(
                CommunityInstance.connect(accountThree).setRoleURI(
                    rolesTitle.get('role3'),
                    uri
                )
            ).to.be.revertedWith("Sender can not manage Members with role '" +rolesTitle.get('role3')+"'");

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
            ).to.be.eq("");

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
            ).to.be.eq("");

            await CommunityInstance.connect(accountTen).setRoleURI(rolesTitle.get('role3'), uri);

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
            ).to.be.eq(uri);

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
            ).to.be.eq(uri);

            await CommunityInstance.connect(accountSix).setExtraURI(rolesTitle.get('role3'), extrauri);

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
            ).to.be.eq(uri);

            expect(
                await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
            ).to.be.eq(extrauri);
            
        });

        //it("should setRoleURI", async () => {});
        //it("", async () => {});

        /*
    //       function setRoleURI(
    //     string memory role,
    //     string memory roleURI
    // ) 
    //     public 
    //     canManage(msg.sender, role.stringToBytes32())
    // {
    //     _rolesIndices[_roles[role.stringToBytes32()]].roleURI = roleURI;
    // }

    // function setExtraURI(
    //     string memory role,
    //     string memory extraURI
    // )
    //     public
    //     ifTargetInRole(msg.sender, role.stringToBytes32())
    // {
    //     _rolesIndices[_roles[role.stringToBytes32()]].extraURI = extraURI;
    // }

  

  
    // /**
    // * @notice getting part of ERC721
    // * @param tokenId token ID
    // * @custom:shortd part of ERC721
    // * @return tokenuri
    // */
    // function tokenURI(uint256 tokenId) external view override returns (string memory)
    // {
    //     return _rolesIndices[uint8(tokenId >> 160)].roleURI;
    // }
        // */
    });
});
