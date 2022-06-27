const { ethers, waffle } = require('hardhat');
const { BigNumber } = require('ethers');
const { expect } = require('chai');
const chai = require('chai');
const { time } = require('@openzeppelin/test-helpers');

const ZERO = BigNumber.from('0');
const ONE = BigNumber.from('1');
const TWO = BigNumber.from('2');
const THREE = BigNumber.from('3');
const FOUR = BigNumber.from('4');
const FIVE = BigNumber.from('5');
const SEVEN = BigNumber.from('7');
const TEN = BigNumber.from('10');
const HUNDRED = BigNumber.from('100');
const THOUSAND = BigNumber.from('1000');


const ONE_ETH = ethers.utils.parseEther('1');

//const TOTALSUPPLY = ethers.utils.parseEther('1000000000');    
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD';

const NO_HOOK = ZERO_ADDRESS;

const TOKEN_NAME = 'TOKEN_NAME';
const TOKEN_SYMBOL = 'TOKEN_SYMBOL';

describe("Community", function () {
    const accounts = waffle.provider.getWallets();
    
    // Setup accounts.
    const owner = accounts[0];                     
    const accountOne = accounts[1];
    const accountTwo = accounts[2];  
    const accountThree = accounts[3];
    const accountFourth= accounts[4];
    const accountFive = accounts[5];
    const accountSix = accounts[6];
    const accountSeven = accounts[7];
    const accountEight = accounts[8];
    const accountNine = accounts[9];
    const accountTen = accounts[10];
    const relayer = accounts[11];
    const trustedForwarder = accounts[12];
    
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
      ['role6', 'Role#6'],
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
      ['role6', 11],
      ['cc_admins', 12]
    ]);
    var CommunityFactory;

    beforeEach("deploying", async() => {
        const CommunityFactoryF = await ethers.getContractFactory("CommunityFactory");
        // const CommunityF = await ethers.getContractFactory("Community");
        // const CommunityERC721F = await ethers.getContractFactory("CommunityERC721");

        // let implementationCommunity = await CommunityF.deploy();
        // let implementationCommunityERC721 = await CommunityERC721F.deploy();

        // CommunityFactory = await CommunityFactoryF.deploy(implementationCommunity.address, implementationCommunityERC721.address);
        CommunityFactory = await CommunityFactoryF.deploy();

    });

    describe("TrustedForwarder", function () {
        var CommunityInstance;
        //var CommunityFactory;
        beforeEach("deploying", async() => {

            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(owner).produce(NO_HOOK,TOKEN_NAME,TOKEN_SYMBOL);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.events.find(event => event.event === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

        });

        it("should be empty after init", async() => {
            expect(await CommunityInstance.isTrustedForwarder(ZERO_ADDRESS)).to.be.true;
        });

        it("should be setup by owner", async() => {
            await expect(CommunityInstance.connect(accountOne).setTrustedForwarder(accountTwo.address)).to.be.revertedWith("Missing role '" +rolesTitle.get('owners')+"'");
            expect(await CommunityInstance.connect(accountOne).isTrustedForwarder(ZERO_ADDRESS)).to.be.true;
            await CommunityInstance.connect(owner).setTrustedForwarder(accountTwo.address);
            expect(await CommunityInstance.connect(accountTwo).isTrustedForwarder(accountTwo.address)).to.be.true;
        });
        
        it("shouldnt become owner and trusted forwarder", async() => {
            await expect(CommunityInstance.connect(owner).setTrustedForwarder(owner.address)).to.be.revertedWith("FORWARDER_CAN_NOT_BE_OWNER");
        });

    });

    for (const trustedForwardMode of [false,true]) {

    var mixedCall = async function(instance, trustedForwardMode, from_, func_signature_, params_, revertedMessage_){
        let expectError = (typeof(revertedMessage_) === 'undefined') ? false : true;

        if (trustedForwardMode) {
            const dataTx = await instance.connect(trustedForwarder).populateTransaction[func_signature_](...params_);
            dataTx.data = dataTx.data.concat((from_.address).substring(2));
            if (expectError) {
                return await expect(trustedForwarder.sendTransaction(dataTx)).to.be.revertedWith(revertedMessage_);
            } else {
                return await trustedForwarder.sendTransaction(dataTx);
            }
        } else {
            if (expectError) {
                return await expect(instance.connect(from_)[func_signature_](...params_)).to.be.revertedWith(revertedMessage_);
            } else {
                return await instance.connect(from_)[func_signature_](...params_);
            }
        }
    }

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} Community Hooks tests`, function () {
        

        it("shouldn't setup hook with invalid interface", async () => {
            
            const CommunityHookF = await ethers.getContractFactory("CommunityHookNoMethods");
            communityHook = await CommunityHookF.deploy();

            await expect(
                CommunityFactory.connect(owner)["produce(address,string,string)"](communityHook.address,TOKEN_NAME,TOKEN_SYMBOL)
            ).to.be.revertedWith("wrong interface");
            // error happens when trying to setup roles for sender

        }); 

        describe("valid hook", function () {
            var CommunityInstance;
            var communityHook;
            beforeEach("deploying", async() => {
                const CommunityHookF = await ethers.getContractFactory("CommunityHook");
                communityHook = await CommunityHookF.deploy();
                let tx,rc,event,instance,instancesCount;
                //
                tx = await CommunityFactory.connect(owner)["produce(address,string,string)"](communityHook.address,TOKEN_NAME,TOKEN_SYMBOL);
                rc = await tx.wait(); // 0ms, as tx is already confirmed
                event = rc.events.find(event => event.event === 'InstanceCreated');
                [instance, instancesCount] = event.args;
                CommunityInstance = await ethers.getContractAt("Community",instance);

                if (trustedForwardMode) {
                    await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
                }

            }); 

            it("while grantRole", async () => {

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')]);
          
                const executedCountBefore = await communityHook.roleGrantedExecuted();

                //grant role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountTwo.address],[rolesIndex.get('role1')]]);
               
                const executedCountAfter = await communityHook.roleGrantedExecuted();

                // grant to owners(while factory produce)
                expect(executedCountBefore).to.be.eq(ONE);

                expect(executedCountAfter.sub(executedCountBefore)).to.be.eq(ONE); // grant to role1(grantRoles)
            }); 

            it("while revokeRole", async () => {
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')]);
                
                const executedCountBefore = await communityHook.roleRevokedExecuted();

                //grant role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountTwo.address],[rolesIndex.get('role1')]]);
                
                //revoke role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountTwo.address],[rolesIndex.get('role1')]]);
                
                const executedCountAfter = await communityHook.roleRevokedExecuted();
                expect(executedCountBefore).to.be.eq(ZERO);
                expect(executedCountAfter).to.be.eq(ONE);
            }); 
            
            it("while createRole", async () => {

                const executedCountBefore = await communityHook.roleCreatedExecuted();

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')]);
                
                const executedCountAfter = await communityHook.roleCreatedExecuted();

                expect(executedCountBefore).to.be.eq(ZERO);
                expect(executedCountAfter).to.be.eq(ONE);

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')], "Such role is already exists");

            }); 
        });

        describe("invalid hook(methods reverted)", function () {
            var CommunityInstance;
            var communityHook;
            beforeEach("deploying", async() => {
                const CommunityHookF = await ethers.getContractFactory("CommunityHookBad");
                communityHook = await CommunityHookF.deploy();
                let tx,rc,event,instance,instancesCount;
                //
                tx = await CommunityFactory.connect(owner)["produce(address,string,string)"](communityHook.address,TOKEN_NAME,TOKEN_SYMBOL);
                rc = await tx.wait(); // 0ms, as tx is already confirmed
                event = rc.events.find(event => event.event === 'InstanceCreated');
                [instance, instancesCount] = event.args;
                CommunityInstance = await ethers.getContractAt("Community",instance);

                if (trustedForwardMode) {
                    await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
                }
            }); 
            it("while grantRole", async () => {

                await communityHook.set(true, false, false);

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);

                //when adding member we grant role members to him
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountTwo.address], [rolesIndex.get('role1')]], "error in granted hook");
            }); 

            it("while revokeRole", async () => {
                await communityHook.set(false, true, false);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
                                
                //grant role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountTwo.address], [rolesIndex.get('role1')]]);
                
                //revoke role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountTwo.address], [rolesIndex.get('role1')]], "error in revoked hook");
            }); 
            
            it("while createRole", async () => {
                await communityHook.set(false, false, true);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')],"error in created hook");
            }); 
        }); 

    });
    
/*
    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} Community tests`, function () {
    
        var CommunityInstance;
        //var CommunityFactory;
        beforeEach("deploying", async() => {

            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(owner)["produce(address)"](NO_HOOK);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.events.find(event => event.event === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

            if (trustedForwardMode) {
                await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
            }

        });

        it("can donate/withdraw ETH", async () => {

            const price = ethers.utils.parseEther('1');
            const amountETHSendToContract = price.mul(TWO); // 2ETH
        
            let balanceBeforeAll = (await ethers.provider.getBalance(CommunityInstance.address));

            // send ETH to Contract      
            await accountThree.sendTransaction({to: CommunityInstance.address, value: amountETHSendToContract});

            let balanceAfterDonate = (await ethers.provider.getBalance(CommunityInstance.address));

            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'withdrawRemainingBalance()', [],"Missing role '" +rolesTitle.get('owners')+"'");

            let balanceOwnerBefore =  (await ethers.provider.getBalance(owner.address));
            let balanceTrustedForwarderBefore =  (await ethers.provider.getBalance(trustedForwarder.address));

            let tx = await mixedCall(CommunityInstance, trustedForwardMode, owner, 'withdrawRemainingBalance()', []);

            let balanceOwnerAfterWithdraw = (await ethers.provider.getBalance(owner.address));
            let balanceTrustedForwarderAfterWithdraw =  (await ethers.provider.getBalance(trustedForwarder.address));

            let balanceAfterWithdraw = (await ethers.provider.getBalance(CommunityInstance.address));

            expect(balanceBeforeAll).to.be.eq(ZERO);
            expect(balanceAfterDonate).to.be.eq(amountETHSendToContract);
            expect(balanceAfterWithdraw).to.be.eq(ZERO);
            expect(balanceOwnerAfterWithdraw).to.be.gt(balanceOwnerBefore);

            let txReceipt = await ethers.provider.getTransactionReceipt(tx.hash);
            let transactionFee = BigNumber.from(txReceipt.cumulativeGasUsed).mul(
                                    BigNumber.from(txReceipt.effectiveGasPrice)
                                );
            if (trustedForwardMode) {
                // no fee consuming for owner. because trasaction initiated trusted forwarder
                expect(
                    balanceOwnerAfterWithdraw.sub(balanceOwnerBefore)
                ).to.be.eq(amountETHSendToContract); // transaction fee is paid by the contract
                // transaction fee consumed by TrustedForwarder
                expect(
                    balanceTrustedForwarderBefore.sub(balanceTrustedForwarderAfterWithdraw)
                ).to.be.eq(transactionFee); // transaction fee is paid by the contract
            } else {
                expect(
                    balanceOwnerAfterWithdraw.sub(balanceOwnerBefore).add(transactionFee)
                ).to.be.eq(amountETHSendToContract); // transaction fee is paid by the contract
            }
        });


        it("creator must be owner and admin", async () => {
            
            var rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](owner.address));
            expect(rolesList.includes(rolesTitle.get('owners'))).to.be.eq(true); // outside OWNERS role
            expect(rolesList.includes(rolesTitle.get('admins'))).to.be.eq(true); // outside ADMINS role

        });
        
        it("can add member", async () => {
            
            expect(
                await CommunityInstance.isMemberHasRole(accountTwo.address, rolesTitle.get('members'))
            ).to.be.false;

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountTwo.address]]);
            var rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));

            expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true); // outside members role

            expect(
                await CommunityInstance.isMemberHasRole(accountTwo.address, rolesTitle.get('members'))
            ).to.be.true;
        });

        
        it("can remove member", async () => {
            
            var rolesList;

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountTwo.address]]);
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
            expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(true);
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'removeMembers(address[])', [[accountTwo.address]]);
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
            expect(rolesList.includes(rolesTitle.get('members'))).to.be.eq(false);
        });
        
        
        it("can create new role", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'createRole(string)', [rolesTitle.get('role1')], "Missing role '" +rolesTitle.get('owners')+"'");

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('owners')], "Such role is already exists");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('admins')], "Such role is already exists");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('members')], "Such role is already exists");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('cc_admins')], "Such role is already exists");
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')], "Such role is already exists");
            
        });

        it("can view all roles", async () => {
            var rolesList;
            [rolesList,] = await CommunityInstance.connect(owner)["getRoles()"]();
            
            // here it will be only internal roles

            let rolesExists =[
                rolesTitle.get('owners'),
                rolesTitle.get('admins'),
                rolesTitle.get('members'),
                rolesTitle.get('relayers')
            ];

            let rolesNotExists =[
                rolesTitle.get('role1'),
                rolesTitle.get('role2'),
                rolesTitle.get('role3'),
                rolesTitle.get('role4')
            ];

            rolesExists.forEach((value, key, map) => {
                 expect(rolesList.includes(value)).to.be.eq(true);
            });

            rolesNotExists.forEach((value, key, map) => {
                 expect(rolesList.includes(value)).to.be.eq(false);
            })

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            
            [rolesList,] = await CommunityInstance.connect(owner)["getRoles()"]();
            (
                rolesExists.concat(
                    [rolesTitle.get('role1')]
                )
            ).forEach((value, key, map) => {
                 expect(rolesList.includes(value)).to.be.eq(true);
            })

            
        });

        it("can view all members in role", async () => {
            // create roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            //add member
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[
                accountTwo.address,
                accountThree.address,
                accountFourth.address,
                accountFive.address,
                accountSix.address,
                accountSeven.address
            ]]);
            // add member to role
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[
                accountTwo.address,
                accountThree.address,
                accountFourth.address,
                accountFive.address,
                accountSix.address
            ], [rolesTitle.get('role1')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[
                accountFive.address,
                accountSix.address,
                accountSeven.address
            ], [rolesTitle.get('role2')]]);

            let allMembers = await CommunityInstance.connect(owner)["getMembers()"]();
            expect(allMembers.length).to.be.eq(SEVEN); // accounts - One,Two,Three,Four,Five,Six,Seven

            let allMembersInMemebers = await CommunityInstance.connect(owner)["getMembers(string)"](rolesTitle.get('members'));
            expect(allMembersInMemebers.length).to.be.eq(SEVEN);
            expect(allMembersInMemebers.length).to.be.eq(allMembers.length);

            let allMembersInRole1 = await CommunityInstance.connect(owner)["getMembers(string)"](rolesTitle.get('role1'));
            expect(allMembersInRole1.length).to.be.eq(FIVE); // accounts - Two,Three,Four,Five,Six

            let allMembersInRole2 = await CommunityInstance.connect(owner)["getMembers(string)"](rolesTitle.get('role2'));
            expect(allMembersInRole2.length).to.be.eq(THREE); // accounts - Five,Six,Seven


        }); 

        it("can manage role", async () => {
            
            // create two roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            
            // ownable check
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'manageRole(string,string)', [rolesTitle.get('role1'),rolesTitle.get('role2')],"Missing role '" +rolesTitle.get('owners')+"'");
            
            // role exist check
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role4'),rolesTitle.get('role2')],"Source role does not exists");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role1'),rolesTitle.get('role4')],"Source role does not exists");
            
            // manage role
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role1'),rolesTitle.get('role2')]);
            //add member
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountTwo.address]]);
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role1')]
            ], "Sender can not manage Members with role '" +rolesTitle.get('role1')+"'");

            // added member to none-exists member
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountThree.address], [rolesTitle.get('role1')]
            ], "Missing role '" +rolesTitle.get('members')+"'");

            // added member to none-exists role 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role4')]
            ], "Such role '"+rolesTitle.get('role4')+"' does not exists");
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role1')]
            ]);
            
            //add member 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountFourth.address]]);

            //add role2 to accountFourth by accountTwo
            await mixedCall(CommunityInstance, trustedForwardMode, accountTwo, 'grantRoles(address[],uint8[])', [
                [accountFourth.address], [rolesTitle.get('role2')]
            ]);

        });

        it("can remove account from role", async () => {

            var rolesList;
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            //add member
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountTwo.address,accountThree.address]]);
            // add member to role
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address, accountThree.address], [rolesTitle.get('role1'),rolesTitle.get('role2')]
            ]);
            
            // check that accountTwo got `get('role1')`
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); // 'outside role'
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'revokeRoles(address[],uint8[])', [
                [accountFourth.address], [rolesTitle.get('role1')]
            ],"Missing role '" +rolesTitle.get('members')+"'");
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role1')]
            ],"Sender can not manage Members with role '" +rolesTitle.get('role1')+"'");

            // remove
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role1')]
            ]);

            // check removing
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address));
            expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); // 'outside role'
            
            // check allowance to remove default role `members`
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('members')]
            ], "Can not remove role '" +rolesTitle.get('members')+"'");
            
        });

        it("shouldnt manage owners role by none owners", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role1'), rolesTitle.get('role2')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role2'), rolesTitle.get('owners')],"targetRole can not be '" +rolesTitle.get('owners')+"'");
        }); 
        
        it("possible to grant with cycle.", async () => {
            
            // create roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role5')]);

            // manage roles to cycle 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role2'), rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role3'), rolesTitle.get('role4')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role4'), rolesTitle.get('role5')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role5'), rolesTitle.get('role2')]);
            
            // account2
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountTwo.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role2')]
            ]);
            
            // check
            rolesList = await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address);
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
            
            // account 3
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountThree.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountTwo, 'grantRoles(address[],uint8[])', [
                [accountThree.address], [rolesTitle.get('role3')]
            ]);
            
            // account 4
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountFourth.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'grantRoles(address[],uint8[])', [
                [accountFourth.address], [rolesTitle.get('role4')]
            ]);
            
            // account 5
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountFive.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountFourth, 'grantRoles(address[],uint8[])', [
                [accountFive.address], [rolesTitle.get('role5')]
            ]);
            
            // account 5 remove account2 from role2
            await mixedCall(CommunityInstance, trustedForwardMode, accountFive, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesTitle.get('role2')]
            ]);
            
            // check again
            rolesList = await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address);
            expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(false); 
        });

        it("check amount of roles after revoke(empty strings)", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountFive.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address], [rolesTitle.get('role1')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address], [rolesTitle.get('role1')]
            ]);
            
            var rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFive.address));

            expect(rolesList.length).to.be.eq(ONE); // members

        });

        it("check amount of roles after revoke(empty strings)::more roles", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role5')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role6')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountFive.address]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role1')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role1')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role2')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role2')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role3')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role3')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role4')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role5')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role5')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesTitle.get('role4')]]);
            
            var rolesList;

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFive.address));
            expect(rolesList.length).to.be.eq(ONE); // members
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role1'),rolesTitle.get('role2')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role3'),rolesTitle.get('role4')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role5'),rolesTitle.get('role6')]
            ]);

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFive.address));
            expect(rolesList.length).to.be.eq(SEVEN); // members,role#1,role#2,role#3,role#4,role#5,role#6

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role6'),rolesTitle.get('role1')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role2'),rolesTitle.get('role3')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address,accountFive.address], 
                [rolesTitle.get('role4'),rolesTitle.get('role5')]
            ]);

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](accountFive.address));
            expect(rolesList.length).to.be.eq(ONE); // members
        });

        describe("test using params as array", function () {
            beforeEach("prepare", async() => {
                
                // create roles
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);

                // Adding
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [
                    [
                        owner.address,
                        accountTwo.address,
                        accountThree.address,
                        accountFourth.address,
                        accountFive.address,
                        accountSix.address,
                        accountSeven.address
                    ]
                ]);

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        owner.address,
                        accountTwo.address,
                        accountThree.address
                    ], 
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3'),
                    ]
                ]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        accountFourth.address,
                        accountFive.address
                    ], 
                    [
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3')
                    ]
                ]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        accountSix.address,
                        accountSeven.address
                    ], 
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2')
                    ]
                ]);

            }); 

            it("check getRoles(address)", async () => {

                
                ///// checking by Members
                var rolesList;
                // owner
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address)"](owner.address));
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

            });

            it("check getRoles(address[])", async () => {
                let rolesList;

                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountTwo.address, accountThree.address]));
                expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 

                // 6 + (twice)internal role "members"
                expect(rolesList.length).to.be.eq(8);
                
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountThree.address, accountFive.address]));
                expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role4'))).to.be.eq(false); 

                // 5 + (twice)internal role "members"
                expect(rolesList.length).to.be.eq(7);
            });

            it("check memberCount(string)", async () => {
                let memberCount;
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
            });

            it("check memberCount()", async () => {
                let memberCount = (await CommunityInstance.connect(accountTen)["memberCount()"]());
                expect(memberCount).to.be.eq(7);
            });

            it("check getMembers(address[])", async () => {
                let allMembersInRole1AndRole2 = await CommunityInstance.connect(accountTen)["getMembers(string[])"]([rolesTitle.get('role1'), rolesTitle.get('role2')]);

                // accounts in role1 - One, Two,Three, Six, Seven
                // accounts in role2 - One, Two,Three, Fourth, Five, Six, Seven
                expect(allMembersInRole1AndRole2.length).to.be.eq(12); 
                
            });
            
        }); 

        describe("invites", function () {
            //var privatekey1, 
            //privatekey2,
            var CommunityInstanceStartingBalance;
            beforeEach("deploying", async() => {
                // privatekey1 = owner._signingKey()["privateKey"];
                // privatekey2 = accountTwo._signingKey()["privateKey"];
               
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
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[relayer.address]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[relayer.address], [rolesTitle.get('relayers')]]);
                
                // create roles
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
                
            });

            it("signatures mismatch (recipient address not equal)", async () => {   
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
                let recipientMsg = ''+accountNine.address+':John Doe';
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                // imitate inviteAccept
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");

            });

            it("signatures mismatch (contract address not equal)", async () => {   
                let adminMsg = [
                    'invite',
                    accountThree.address,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3')
                    ].join(','),
                    'GregMagarshak'
                    ].join(':');;
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                // imitate inviteAccept
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");
                

            });

            it("invites by admins which cant add any role from list", async () => {   
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
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);
                // imitate inviteAccept
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Can not add no one role");

            }); 

            it("invites by admins which cant add role (1 of 2)", async () => {   
                let adminMsg = [
                    'invite',
                    CommunityInstance.address,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2')
                    ].join(','),
                    'GregMagarshak'
                    ].join(':');
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountThree.address]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [ [accountThree.address], [rolesTitle.get('role3')]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(string,string)', [rolesTitle.get('role3'),rolesTitle.get('role2')]);
                
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                // imitate inviteAccept
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig]);
                
                // check roles of accountTwo
                rolesList = await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address);
                expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(false); 
                expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 

            }); 

            it("invites test", async () => {   

                var rolesList;
            
                rolesList = (await CommunityInstance.connect(owner)["getRoles(address)"](relayer.address));
                expect(rolesList.includes(rolesTitle.get('relayers'))).to.be.eq(true); 

                
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
                
                let sSig = await owner.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                const recipientStartingBalance = (await ethers.provider.getBalance(accountTwo.address));
                const relayerStartingBalance = (await ethers.provider.getBalance(relayer.address));

                // imitate invitePrepare and check it in system
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                let invite = await CommunityInstance.connect(relayer).inviteView(sSig);
                expect(invite.exists).to.be.true; // 'invite not found';
                expect(invite.exists && invite.used==false).to.be.true; // 'invite not used before'
                //console.log('(1)invite.gasCost=',invite.gasCost);
            
                // imitate inviteAccept
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig]);

                const relayerEndingBalance = await ethers.provider.getBalance(relayer.address);
                const recipientEndingBalance = await ethers.provider.getBalance(accountTwo.address);
                const CommunityInstanceEndingBalance = (await ethers.provider.getBalance(CommunityInstance.address));
                
                // check roles of accountTwo
                rolesList = await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address);
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
                
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig], "Such signature is already exists");
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig], "Such signature is already used");
                
                await expect(await CommunityInstance.invitedBy(accountTwo.address)).to.be.eq(owner.address); //'does not store invited mapping'
                await expect(await CommunityInstance.invitedBy(accountTwo.address)).not.to.be.eq(accountNine.address); //'store wrong keys in invited mapping'
                
            
                
            });

            it("check first invites test", async () => {   
                
                // Adding another relayer(accountSix)
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountSix.address]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountSix.address], [rolesTitle.get('relayers')]]);
                // Adding another owner(accountSeven)
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'addMembers(address[])', [[accountSeven.address]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountSeven.address], [rolesTitle.get('owners')]]);

                let adminMsgFirst = [
                    'invite',
                    CommunityInstance.address,
                    [
                        rolesTitle.get('role1')
                    ].join(','),
                    'GregMagarshak'
                    ].join(':');
                let adminMsgSecond = [
                    'invite',
                    CommunityInstance.address,
                    [
                        rolesTitle.get('role2')
                    ].join(','),
                    'GregMagarshak'
                    ].join(':');
                let recipientMsg = ''+accountTwo.address+':John Doe';

                let rSig;

                let sSigFirst = await owner.signMessage(adminMsgFirst);
                rSig = await accountTwo.signMessage(recipientMsg);

                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSigFirst,rSig]);
                await mixedCall(CommunityInstance, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsgFirst, sSigFirst, recipientMsg, rSig]);

                //  make with another owner
                let sSigSecond = await accountSeven.signMessage(adminMsgSecond);
                
                await mixedCall(CommunityInstance, trustedForwardMode, accountSix, 'invitePrepare(bytes,bytes)', [sSigSecond,rSig]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountSix, 'inviteAccept(string,bytes,string,bytes)', [adminMsgSecond, sSigSecond, recipientMsg, rSig]);

                await expect(await CommunityInstance.invitedBy(accountTwo.address)).to.be.eq(owner.address); // should be invited by first owner
                await expect(await CommunityInstance.invitedBy(accountTwo.address)).not.to.be.eq(accountSeven.address); // shouldnt be invited by swcond owner(accountSeven)
                await expect(await CommunityInstance.invitedBy(accountTwo.address)).not.to.be.eq(accountNine.address); //'store wrong keys in invited mapping'

                // check roles of accountTwo
                rolesList = await CommunityInstance.connect(owner)["getRoles(address)"](accountTwo.address);
                expect(rolesList.includes(rolesTitle.get('role1'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role2'))).to.be.eq(true); 
                expect(rolesList.includes(rolesTitle.get('role3'))).to.be.eq(false); 
            });
        });


    });

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''}CommunityERC721 tests`, function () {
        
        var CommunityInstance;
        
        beforeEach("deploying", async() => {
            
            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(accountTen)["produce(address,string,string)"](NO_HOOK, "Community", "Community");
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.events.find(event => event.event === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("CommunityERC721",instance);

            if (trustedForwardMode) {
                await CommunityInstance.connect(accountTen).setTrustedForwarder(trustedForwarder.address);
            }

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
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role3')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role4')]);

                // Adding
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'addMembers(address[])', [
                    [
                        owner.address,
                        accountTwo.address,
                        accountThree.address,
                        accountFourth.address,
                        accountSix.address,
                    ]
                ]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [owner.address], 
                    [rolesTitle.get('role1')]
                ]);

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [accountTwo.address], 
                    [rolesTitle.get('role2')]
                ]);

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [accountThree.address,
                    accountSix.address], 
                    [
                        rolesTitle.get('role3')
                    ]
                ]);
                
            });

            
            it("should correct balanceOf for holders", async () => {
                // using "+ONE" because any account in community have extra role "members"
                expect(await CommunityInstance.balanceOf(owner.address)).to.be.eq(ONE.add(ONE));
                expect(await CommunityInstance.balanceOf(accountTwo.address)).to.be.eq(ONE.add(ONE));
                expect(await CommunityInstance.balanceOf(accountThree.address)).to.be.eq(ONE.add(ONE));
                expect(await CommunityInstance.balanceOf(accountFourth.address)).to.be.eq(ZERO.add(ONE));
            });

            it("should correct balanceOf for none-holders", async () => {
                expect(await CommunityInstance.balanceOf(accountFive.address)).to.be.eq(ZERO);
            });

            it("should be owner of token", async () => {
                expect(
                    await CommunityInstance.ownerOf(generateTokenId(owner.address, rolesIndex.get('role1')))
                ).to.be.eq(owner.address);
                expect(
                    await CommunityInstance.ownerOf(generateTokenId(accountTwo.address, rolesIndex.get('role2')))
                ).to.be.eq(accountTwo.address);
                expect(
                    await CommunityInstance.ownerOf(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq(accountThree.address);
                
            });

            it("shouldn't be owner of token", async () => {
                expect(
                    await CommunityInstance.ownerOf(generateTokenId(owner.address, rolesIndex.get('role2')))
                ).to.be.eq(ZERO_ADDRESS);
            });

            it("shouldn't approve", async () => {
                await expect(
                    CommunityInstance.connect(owner).approve(
                        accountFourth.address,
                        generateTokenId(owner.address, rolesIndex.get('role1'))
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
            });

            it("shouldn't transferFrom", async () => {
                await expect(
                    CommunityInstance.connect(owner).transferFrom(
                        owner.address,
                        accountFourth.address,
                        generateTokenId(owner.address, rolesIndex.get('role1'))
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
            });

            it("shouldn't safeTransferFrom", async () => {
                await expect(
                    CommunityInstance.connect(owner)["safeTransferFrom(address,address,uint256)"](
                        owner.address,
                        accountFourth.address,
                        generateTokenId(owner.address, rolesIndex.get('role1'))
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");

                await expect(
                    CommunityInstance.connect(owner)["safeTransferFrom(address,address,uint256,bytes)"](
                        owner.address,
                        accountFourth.address,
                        generateTokenId(owner.address, rolesIndex.get('role1')),
                        []
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
            });

            it("shouldn't getApproved", async () => {
                await expect(
                    CommunityInstance.connect(owner).getApproved(
                        generateTokenId(owner.address, rolesIndex.get('role1'))
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
            });

            it("shouldn't setApprovalForAll", async () => {
                await expect(
                    CommunityInstance.connect(owner).setApprovalForAll(
                        owner.address,
                        true
                    )
                ).to.be.revertedWith("CommunityContract: NOT_AUTHORIZED");
            });

            it("shouldn't isApprovedForAll", async () => {
                await expect(
                    CommunityInstance.connect(owner).isApprovedForAll(
                        owner.address,
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
                    await CommunityInstance.connect(owner).supportsInterface(interfaceIERC721UpgradeableId)
                ).to.be.true;
                await expect(
                    await CommunityInstance.connect(owner).supportsInterface(interfaceIERC721MetadataUpgradeableId)
                ).to.be.true;
                await expect(
                    await CommunityInstance.connect(owner).supportsInterface(interfaceIERC165UpgradeableId)
                ).to.be.true;
                await expect(
                    await CommunityInstance.connect(owner).supportsInterface(interfaceWrongId)
                ).to.be.false;
            });

            it("check setRoleURI and setExtraURI", async () => {
                let uri = "http://google.com/";
                let extrauri = "http://google.com/extra";

                await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'setRoleURI(string,string)', [rolesTitle.get('role3'),uri],"Sender can not manage Members with role '" +rolesTitle.get('role3')+"'");

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq("");

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
                ).to.be.eq("");

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'setRoleURI(string,string)', [rolesTitle.get('role3'),uri]);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq(uri);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
                ).to.be.eq(uri);

                await mixedCall(CommunityInstance, trustedForwardMode, accountSix, 'setExtraURI(string,string)', [rolesTitle.get('role3'),extrauri]);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq(uri);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
                ).to.be.eq(extrauri);
                
            });

        });
    });
*/
    }

});
