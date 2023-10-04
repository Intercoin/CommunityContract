const { ethers } = require('hardhat');
const { utils, AbiCoder } = require("ethers");
const { time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai'); 
require("@nomicfoundation/hardhat-chai-matchers");


const ZERO      = BigInt('0');
const ONE       = BigInt('1');
const TWO       = BigInt('2');
const THREE     = BigInt('3');
const FOUR      = BigInt('4');
const FIVE      = BigInt('5');
const SIX       = BigInt('6');
const SEVEN     = BigInt('7');
const EIGHT     = BigInt('8');
const NINE      = BigInt('9');
const TEN       = BigInt('10');
const HUNDRED   = BigInt('100');
const THOUSAND  = BigInt('1000');


const ONE_ETH = ethers.parseEther('1');

//const TOTALSUPPLY = ethers.parseEther('1000000000');    
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const DEAD_ADDRESS = '0x000000000000000000000000000000000000dEaD';

const NO_HOOK = ZERO_ADDRESS;
const NO_INVITED_HOOK = ZERO_ADDRESS;
const NO_COSTMANAGER = ZERO_ADDRESS;

const TOKEN_NAME = 'TOKEN_NAME';
const TOKEN_SYMBOL = 'TOKEN_SYMBOL';

const CONTRACT_URI = 'http://some.domain/info';

describe("Community", function () {

    
    // setup useful vars
    
    var rolesTitle = new Map([
      ['owners', 'owners'],
      ['admins', 'admins'],
      ['members', 'members'],
      ['alumni', 'alumni'],
      ['visitors', 'visitors'],
      ['role1', 'Role#1'],
      ['role2', 'Role#2'],
      ['role3', 'Role#3'],
      ['role4', 'Role#4'],
      ['role5', 'Role#5'],
      ['role6', 'Role#6'],
      ['cc_admins', 'AdMiNs']
      
    ]);

    var rolesIndex = new Map([
      ['owners',    1n],
      ['admins',    2n],
      ['members',   3n],
      ['alumni',    4n],
      ['visitors',  5n],
      // do not change order indexes above. and in tests try to create role in this order to be able to compare with index. or need to get role index by string  from contract
      ['role1',     6n],
      ['role2',     7n],
      ['role3',     8n],
      ['role4',     9n],
      ['role5',     10n],
      ['role6',     11n],
      ['cc_admins', 12n]
    ]);
    var CommunityFactory;
    var AuthorizedInviteManager;
    var AuthorizedInviteManagerGasTracker;
    var CostManagerBad, CostManagerGood;

    var owner,
        accountOne,
        accountTwo,
        accountThree,
        accountFourth,
        accountFive,
        accountSix,
        accountSeven,
        accountEight,
        accountNine,
        accountTen,
        relayer,
        trustedForwarder;

    beforeEach("deploying", async() => {

        // Setup accounts.
        [
            owner,
            accountOne,
            accountTwo,
            accountThree,
            accountFourth,
            accountFive,
            accountSix,
            accountSeven,
            accountEight,
            accountNine,
            accountTen,
            relayer,
            trustedForwarder
        ] = await ethers.getSigners();
        
        let tx,rc,event,instance,instancesCount,factoriesList,factoriesInfo;

        const ReleaseManagerFactoryF = await ethers.getContractFactory("MockReleaseManagerFactory");
        const CommunityFactoryF = await ethers.getContractFactory("CommunityFactory");
        const CostManagerGoodF = await ethers.getContractFactory("MockCostManagerGood");
        const CostManagerBadF = await ethers.getContractFactory("MockCostManagerBad");

        const ReleaseManagerF = await ethers.getContractFactory("MockReleaseManager");
        const CommunityF = await ethers.getContractFactory("Community");
        
        CostManagerGood = await CostManagerGoodF.deploy();
        CostManagerBad = await CostManagerBadF.deploy();

        let implementationReleaseManager    = await ReleaseManagerF.deploy();
        let implementationCommunity         = await CommunityF.deploy();
        
        let releaseManagerFactory   = await ReleaseManagerFactoryF.connect(owner).deploy(implementationReleaseManager.target);
        
        //
        tx = await releaseManagerFactory.connect(owner).produce();
        rc = await tx.wait(); // 0ms, as tx is already confirmed

        event = rc.logs.find(event => event.fragment.name === 'InstanceProduced');
        [instance, instancesCount] = event.args;

        let releaseManager = await ethers.getContractAt("MockReleaseManager",instance);

        // 
        const AuthorizedInviteManagerFactoryF = await ethers.getContractFactory("AuthorizedInviteManagerFactory");
        const AuthorizedInviteManagerF = await ethers.getContractFactory("AuthorizedInviteManager");
        const implementationAuthorizedInviteManager = await AuthorizedInviteManagerF.deploy();
        const AuthorizedInviteManagerFactory = await AuthorizedInviteManagerFactoryF.connect(owner).deploy(
            implementationAuthorizedInviteManager.target,
            NO_COSTMANAGER,
            releaseManager.target
        );

        await releaseManager.connect(owner).newRelease(
            [AuthorizedInviteManagerFactory.target], 
            [
                [
                    2,//uint8 factoryIndex; 
                    2,//uint16 releaseTag; 
                    "0x53696c766572000000000000000000000000000000000000"//bytes24 factoryChangeNotes;
                ]
            ]
        );

        tx = await AuthorizedInviteManagerFactory.connect(owner).produce();
        rc = await tx.wait(); // 0ms, as tx is already confirmed
        event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
        [instance, instancesCount] = event.args;
        AuthorizedInviteManager = await ethers.getContractAt("AuthorizedInviteManager",instance);
   
        // CommunityFactory = await CommunityFactoryF.deploy(implementationCommunity.target, implementationCommunityERC721.target);
        CommunityFactory = await CommunityFactoryF.connect(owner).deploy(
            implementationCommunity.target,
            NO_COSTMANAGER,
            releaseManager.target,
            AuthorizedInviteManager.target
        );

        await releaseManager.connect(owner).newRelease(
            [
                CommunityFactory.target
            ], 
            [
                [
                    1,//uint8 factoryIndex; 
                    1,//uint16 releaseTag; 
                    "0x53696c766572000000000000000000000000000000000000"//bytes24 factoryChangeNotes;
                ]
            ]
        );

    });

    describe("factory produce", function () {
        const salt    = "0x00112233445566778899AABBCCDDEEFF00000000000000000000000000000000";
        const salt2   = "0x00112233445566778899AABBCCDDEEFF00000000000000000000000000000001";
        it("should produce", async() => {
             
            let tx = await CommunityFactory.connect(owner).produce(NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);

            const rc = await tx.wait(); // 0ms, as tx is already confirmed
            const event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            const [instance,] = event.args;
            expect(instance).not.to.be.eq(ZERO_ADDRESS);
            //simpleContract = await ethers.getContractAt("MockSimpleContract",instance);   
        });
        it("should produce deterministic", async() => {

            let tx = await CommunityFactory.connect(owner).produceDeterministic(salt,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);

            let rc = await tx.wait(); // 0ms, as tx is already confirmed
            let event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            let [instance,] = event.args;
            expect(instance).not.to.be.eq(ZERO_ADDRESS);
            await expect(CommunityFactory.connect(owner).produceDeterministic(salt,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI)).to.be.revertedWith('ERC1167: create2 failed');

        });

        it("can't create2 if created before with the same salt, even if different sender", async() => {
            let tx,event,instanceWithSaltAgain, instanceWithSalt, instanceWithSalt2;

            //make snapshot
            let snapId = await ethers.provider.send('evm_snapshot', []);

            tx = await CommunityFactory.connect(owner).produceDeterministic(salt,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instanceWithSalt,] = event.args;
            //revert snapshot
            await ethers.provider.send('evm_revert', [snapId]);

            // make create2. then create and finally again with salt. 
            tx = await CommunityFactory.connect(owner).produceDeterministic(salt2,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instanceWithSalt2,] = event.args;
            
            await CommunityFactory.connect(owner).produce(NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);

            tx = await CommunityFactory.connect(owner).produceDeterministic(salt,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instanceWithSaltAgain,] = event.args;


            expect(instanceWithSaltAgain).to.be.eq(instanceWithSalt);
            expect(instanceWithSalt2).not.to.be.eq(instanceWithSalt);

            await expect(CommunityFactory.connect(owner).produceDeterministic(salt,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI)).to.be.revertedWith('ERC1167: create2 failed');
            await expect(CommunityFactory.connect(owner).produceDeterministic(salt2,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI)).to.be.revertedWith('ERC1167: create2 failed');
            await expect(CommunityFactory.connect(accountOne).produceDeterministic(salt2,NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI)).to.be.revertedWith('ERC1167: create2 failed');
            
        });
    });

    describe("TrustedForwarder", function () {
        var CommunityInstance;
        //var CommunityFactory;
        beforeEach("deploying", async() => {

            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(owner).produce(NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

        });

        it("should be empty after init", async() => {
            expect(await CommunityInstance.isTrustedForwarder(ZERO_ADDRESS)).to.be.true;
        });

        it("should be setup by owner", async() => {
            await expect(CommunityInstance.connect(accountOne).setTrustedForwarder(accountTwo.address)).to.be.revertedWith("MISSING_ROLE '" +rolesTitle.get('owners')+"'");
            expect(await CommunityInstance.connect(accountOne).isTrustedForwarder(ZERO_ADDRESS)).to.be.true;
            await CommunityInstance.connect(owner).setTrustedForwarder(accountTwo.address);
            expect(await CommunityInstance.connect(accountTwo).isTrustedForwarder(accountTwo.address)).to.be.true;
        });
        
        it("shouldnt become owner and trusted forwarder", async() => {
            await expect(CommunityInstance.connect(owner).setTrustedForwarder(owner.address)).to.be.revertedWith("FORWARDER_CANNOT_BE_OWNER");
        });

    });


    for (const trustedForwardMode of [false,true]) {

    var mixedCall = async function(instance, trustedForwardMode, from_, func_signature_, params_, revertedMessage_){
        let expectError = (typeof(revertedMessage_) === 'undefined') ? false : true;

        if (trustedForwardMode) {
            const dataTx = await instance.connect(trustedForwarder)[func_signature_].populateTransaction(...params_);
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

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} CostManager test`, function () {
        
        it("should set costmanager while factory produce", async () => {
            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            let communityInstance1 = await ethers.getContractAt("Community",instance);

            await CommunityFactory.connect(owner).setCostManager(CostManagerGood.target);

            tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            let communityInstance2 = await ethers.getContractAt("Community",instance);

            expect(await communityInstance1.costManager()).to.be.eq(ZERO_ADDRESS);
            expect(await communityInstance2.costManager()).to.be.eq(CostManagerGood.target);

        }); 


        describe('costmanager', function () {
        
            var CommunityInstance;
            var communityHook;
            beforeEach("deploying", async() => {
                
                let tx,rc,event,instance,instancesCount;
                //
                tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
                rc = await tx.wait(); // 0ms, as tx is already confirmed
                event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
                [instance, instancesCount] = event.args;
                CommunityInstance = await ethers.getContractAt("Community",instance);

                if (trustedForwardMode) {
                    await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
                }

            }); 

            it("shouldnt override costmanager", async () => {
                // await expect(
                //     CommunityInstance.connect(accountSix).overrideCostManager(CostManagerGood.target)
                // ).to.be.revertedWith("cannot override");
                await mixedCall(CommunityInstance, trustedForwardMode, accountSix, 'overrideCostManager(address)', [CostManagerGood.target], "cannot override");
            }); 

            it("shouldnt override costmanager if `factory's owner` lost ownership", async () => {
                await CommunityFactory.connect(owner).transferOwnership(accountSix.address);
                // await expect(
                //     CommunityInstance.connect(owner).overrideCostManager(CostManagerGood.target)
                // ).to.be.revertedWith("cannot override");
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'overrideCostManager(address)', [CostManagerGood.target], "cannot override");
            }); 

            it("should override costmanager", async () => {
                let oldCostManager = await CommunityInstance.costManager();
                
                // here owner it's factory owner
                //await CommunityInstance.connect(owner).overrideCostManager(CostManagerGood.target);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'overrideCostManager(address)', [CostManagerGood.target]);

                let newCostManager = await CommunityInstance.costManager();

                expect(oldCostManager).not.to.be.eq(newCostManager);
                expect(newCostManager).to.be.eq(CostManagerGood.target);

            }); 
            
            it("should override costmanager for new factory's owner", async () => {
                let oldCostManager = await CommunityInstance.costManager();
                
                // here owner it's factory owner
                await CommunityFactory.connect(owner).transferOwnership(accountSix.address);

                //await CommunityInstance.connect(accountSix).overrideCostManager(CostManagerGood.target);
                await mixedCall(CommunityInstance, trustedForwardMode, accountSix, 'overrideCostManager(address)', [CostManagerGood.target]);

                let newCostManager = await CommunityInstance.costManager();

                expect(oldCostManager).not.to.be.eq(newCostManager);
                expect(newCostManager).to.be.eq(CostManagerGood.target);

            }); 

            it("should call renounceOverrideCostManager by owner only", async () => {
                await expect(
                    CommunityFactory.connect(accountSix).renounceOverrideCostManager(CommunityInstance.target)
                ).to.be.revertedWith("Ownable: caller is not the owner");

                await CommunityFactory.connect(owner).renounceOverrideCostManager(CommunityInstance.target)

                // await expect(
                //     CommunityInstance.connect(owner).overrideCostManager(CostManagerGood.target)
                // ).to.be.revertedWith("cannot override");
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'overrideCostManager(address)', [CostManagerGood.target], "cannot override");
                
            }); 

            // xit("should renounceOverrideCostManager", async () => {}); 
            // xit("should renounceOverrideCostManager", async () => {}); 
            // xit("should renounceOverrideCostManager", async () => {}); 

        });     

        
    });

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} Community Hooks tests`, function () {
        

        it("shouldn't setup hook with invalid interface", async () => {
            
            const CommunityHookF = await ethers.getContractFactory("CommunityHookNoMethods");
            communityHook = await CommunityHookF.deploy();

            await expect(
                CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](communityHook.target,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI)
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
                tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](communityHook.target,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
                rc = await tx.wait(); // 0ms, as tx is already confirmed
                event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
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
                expect(BigInt(executedCountBefore)).to.be.eq(ONE);

                expect(executedCountAfter - executedCountBefore).to.be.eq(ONE); // grant to role1(grantRoles)
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

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')], "ROLE_EXISTS");

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
                tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](communityHook.target,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
                rc = await tx.wait(); // 0ms, as tx is already confirmed
                event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
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

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} Community tests`, function () {
    
        var CommunityInstance;
        

        // consts for manageRole methods
        const canGrantRole = true; //bool
        const canRevokeRole = true; //bool 
        const maxAddresses = 0; //uint256
        const duration = 0; //uint64

        //var CommunityFactory;
        beforeEach("deploying", async() => {

            let tx,rc,event,instance,instancesCount;
            //

            tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](NO_HOOK,NO_INVITED_HOOK,TOKEN_NAME,TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

            if (trustedForwardMode) {
                await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
            }

        });

        it("CONTRACT_URI check", async () => {
            const oldContractURI = await CommunityInstance.contractURI();
            expect(oldContractURI).to.be.eq(CONTRACT_URI);

            const newContractURI = oldContractURI + 'NEW';
            await expect(CommunityInstance.connect(accountFourth).setContractURI(newContractURI)).to.be.revertedWith("MISSING_ROLE '" +rolesTitle.get('owners')+"'");
            await CommunityInstance.connect(owner).setContractURI(newContractURI);

            const contractURI = await CommunityInstance.contractURI();
            expect(newContractURI).to.be.eq(contractURI);
        });

        it("instanceCount check", async () => {
            expect(await CommunityFactory.instancesCount()).to.be.eq(ONE);
        });

        it("can't send ETH", async () => {

            const amountETHSendToContract = ethers.parseEther('2'); // 2ETH
            // send ETH to Contract      
            await expect(
                accountThree.sendTransaction({to: CommunityInstance.target, value: amountETHSendToContract})
            ).to.be.revertedWithCustomError(CommunityInstance,"NOT_SUPPORTED");

        });

        it("creator must be owner", async () => {
            
            var rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([owner.address]));

            expect(rolesList[0].includes(rolesIndex.get('owners'))).to.be.eq(true); // outside OWNERS role

        });

        it("can create new role", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'createRole(string)', [rolesTitle.get('role1')], "MISSING_ROLE '" +rolesTitle.get('owners')+"'");

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('owners')], "ROLE_EXISTS");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('admins')], "ROLE_EXISTS");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('members')], "ROLE_EXISTS");
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('cc_admins')], "ROLE_EXISTS");
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')], "ROLE_EXISTS");
            
        });

        it("can view all roles", async () => {
            var rolesList;
            [rolesList,] = await CommunityInstance.connect(owner)["allRoles()"]();
            
            // here it will be only internal roles
            let rolesExists =[
                rolesIndex.get('owners'),
                rolesIndex.get('admins'),
                rolesIndex.get('members'),
                rolesIndex.get('alumni'),
                rolesIndex.get('visitors')
            ];

            let rolesNotExists =[
                rolesIndex.get('role1'),
                rolesIndex.get('role2'),
                rolesIndex.get('role3'),
                rolesIndex.get('role4')
            ];

            rolesExists.forEach((value, key, map) => {
                 expect(rolesList.includes(value)).to.be.eq(true);
            });

            rolesNotExists.forEach((value, key, map) => {
                 expect(rolesList.includes(value)).to.be.eq(false);
            })

            expect(rolesList.includes(ZERO)).to.be.eq(false);
            
        });

        it("check canGrantRoles/canRevokeRoles when call allRoles()", async () => {
            // create new role "Role1".
            // after creation new role - "admins" still can not be manage 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);

            var rolesList,names, URIs, canGrantRoles, canRevokeRoles;
            [rolesList, names, URIs, canGrantRoles, canRevokeRoles] = await CommunityInstance.connect(owner)["allRoles()"]();

            // roles except owners and admins
            let rolesThatCanBeManagedByAdmins =[
                rolesIndex.get('members'),
                rolesIndex.get('alumni'),
                rolesIndex.get('visitors')
            ];
            
            for(var i = 0; i<rolesList.length; i++) {
                switch (rolesList[i]) {
                    case rolesIndex.get('admins'):
                        rolesThatCanBeManagedByAdmins.forEach((value, key, map) => {
                            expect(canGrantRoles[i].includes(value)).to.be.eq(true);
                        });

                        rolesThatCanBeManagedByAdmins.forEach((value, key, map) => {
                            expect(canRevokeRoles[i].includes(value)).to.be.eq(true);
                        });
                        break;
                    case rolesIndex.get('owners'):
                    case rolesIndex.get('members'):
                    case rolesIndex.get('alumni'):
                    case rolesIndex.get('visitors'):
                        expect(BigInt(canGrantRoles[i].length)).to.be.eq(ZERO);
                        break;
                }
            }

            
            // grant some roles 
            // can grant :
            //  admins->role1 
            //  role1->members 
            // can revoke :
            //  admins->role1 
            //  role1->members 
            //  role1->visitors 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('admins'),rolesIndex.get('role1'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('members'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('visitors'),false, canRevokeRole, maxAddresses, duration]);
            [rolesList, names, URIs, canGrantRoles, canRevokeRoles] = await CommunityInstance.connect(owner)["allRoles()"]();

            rolesThatCanBeManagedByAdmins.push(rolesIndex.get('role1'));
            rolesThatCanBeGrantedByRole1 = [
                rolesIndex.get('members')
            ];
            rolesThatCanBeRevokedByRole1 = [
                rolesIndex.get('members'),
                rolesIndex.get('visitors')
            ];
            
            // lets check
            for(var i = 0; i<rolesList.length; i++) {
                switch (rolesList[i]) {
                    case rolesIndex.get('admins'):
                        rolesThatCanBeManagedByAdmins.forEach((value, key, map) => {
                            expect(canGrantRoles[i].includes(value)).to.be.eq(true);
                        });

                        rolesThatCanBeManagedByAdmins.forEach((value, key, map) => {
                            expect(canRevokeRoles[i].includes(value)).to.be.eq(true);
                        });
                        break;
                    case rolesIndex.get('owners'):
                    case rolesIndex.get('members'):
                    case rolesIndex.get('alumni'):
                    case rolesIndex.get('visitors'):
                        expect(BigInt(canGrantRoles[i].length)).to.be.eq(ZERO);
                        break;
                    case rolesIndex.get('role1'):
                        rolesThatCanBeGrantedByRole1.forEach((value, key, map) => {
                            expect(canGrantRoles[i].includes(value)).to.be.eq(true);
                        });
                        rolesThatCanBeRevokedByRole1.forEach((value, key, map) => {
                            expect(canRevokeRoles[i].includes(value)).to.be.eq(true);
                        });
                        break;
                }
            }
        });

        it("can view all members in role", async () => {
            
            // create roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
           
            // grant role to accounts
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[
                accountTwo.address,
                accountThree.address,
                accountFourth.address,
                accountFive.address,
                accountSix.address
            ], [rolesIndex.get('role1')]]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[
                accountFive.address,
                accountSix.address,
                accountSeven.address
            ], [rolesIndex.get('role2')]]);

            // let allMembers = await CommunityInstance.connect(owner)["getMembers()"]();
            // expect(allMembers.length).to.be.eq(SEVEN); // accounts - One,Two,Three,Four,Five,Six,Seven
            let allMembersCount = await CommunityInstance.connect(owner)["addressesCount()"]();

            expect(allMembersCount).to.be.eq(EIGHT); // accounts - One,Two,Three,Four,Five,Six,Seven and OWNER

            let allMembersInRole1 = await CommunityInstance.connect(owner)["getAddresses(uint8[])"]([rolesIndex.get('role1')]);
            expect(BigInt(allMembersInRole1[0].length)).to.be.eq(FIVE); // accounts - Two,Three,Four,Five,Six

            let allMembersInRole2 = await CommunityInstance.connect(owner)["getAddresses(uint8[])"]([rolesIndex.get('role2')]);
            expect(BigInt(allMembersInRole2[0].length)).to.be.eq(THREE); // accounts - Five,Six,Seven


        }); 

        it("can manage role", async () => {
            
            // create two roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            
            // ownable check
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                accountThree, 
                'manageRole(uint8,uint8,bool,bool,uint256,uint64)', 
                [rolesIndex.get('role1'),rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration],
                "MISSING_ROLE '" +rolesTitle.get('owners')+"'"
            );

            // role exist check
            // byRole invalid
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRole(uint8,uint8,bool,bool,uint256,uint64)', 
                [rolesIndex.get('role4'),rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration],
                "INVALID_ROLE"
            );
            // ofRole invalid
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRole(uint8,uint8,bool,bool,uint256,uint64)', 
                [rolesIndex.get('role1'),rolesIndex.get('role4'),canGrantRole, canRevokeRole, maxAddresses, duration],
                "INVALID_ROLE"
            );

            // manage role
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ], "CANT_GRANT_ROLE '" +rolesTitle.get('role1')+"'");

            // added member to none-exists role 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role4')]
            ], "INVALID_ROLE");
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ]);

            //add role2 to accountFourth by accountTwo
            await mixedCall(CommunityInstance, trustedForwardMode, accountTwo, 'grantRoles(address[],uint8[])', [
                [accountFourth.address], [rolesIndex.get('role2')]
            ]);

        });

        it("can manage roles", async () => {
            
            // create two roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            
            // ownable check
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                accountThree, 
                'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', 
                [[rolesIndex.get('role1')],[rolesIndex.get('role2')],[canGrantRole], [canRevokeRole], [maxAddresses], [duration]],
                "MISSING_ROLE '" +rolesTitle.get('owners')+"'"
            );

            // role exist check
            // byRole invalid
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', 
                [[rolesIndex.get('role4')],[rolesIndex.get('role2')],[canGrantRole], [canRevokeRole], [maxAddresses], [duration]],
                "INVALID_ROLE"
            );
            // ofRole invalid
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', 
                [[rolesIndex.get('role1')],[rolesIndex.get('role4')],[canGrantRole], [canRevokeRole], [maxAddresses], [duration]],
                "INVALID_ROLE"
            );

            // manage role
            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', 
                [
                    [rolesIndex.get('role1')],
                    [rolesIndex.get('role2')],
                    [canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses], 
                    [duration]
                ]
            );
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ], "CANT_GRANT_ROLE '" +rolesTitle.get('role1')+"'");

            // added member to none-exists role 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role4')]
            ], "INVALID_ROLE");
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ]);

            //add role2 to accountFourth by accountTwo
            await mixedCall(CommunityInstance, trustedForwardMode, accountTwo, 'grantRoles(address[],uint8[])', [
                [accountFourth.address], [rolesIndex.get('role2')]
            ]);

        });


        it("shouldn't grant if disable in manageRole", async () => {
            // create two roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountOne.address], [rolesIndex.get('role1')]
            ]);
            // allow grant
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('role2'), canGrantRole, canRevokeRole, maxAddresses, duration]);

            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);

            // denied grant
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('role2'),false, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'grantRoles(address[],uint8[])', [
                [accountThree.address], [rolesIndex.get('role2')]
            ], "CANT_GRANT_ROLE '" +rolesTitle.get('role2')+"'");

        }); 

        it("shouldn't revoke if disable in manageRole", async () => {
            // create two roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountOne.address], [rolesIndex.get('role1')]
            ]);
            // allow grant
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration]);

            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);

            // denied grant
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role1'),rolesIndex.get('role2'),canGrantRole, false, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, accountOne, 'revokeRoles(address[],uint8[])', [
                [accountThree.address], [rolesIndex.get('role2')]
            ], "CANT_REVOKE_ROLE '" +rolesTitle.get('role2')+"'");

        }); 

        it("can remove account from role", async () => {

            var rolesList;
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            // add member to role
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address, accountThree.address], [rolesIndex.get('role1'),rolesIndex.get('role2')]
            ]);
            
            // check that accountTwo got `get('role1')`
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]));
            expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); // 'outside role'
            
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ],"CANT_REVOKE_ROLE '" +rolesTitle.get('role1')+"'");

            // remove
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role1')]
            ]);

            // check removing
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]));
            expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(false); // 'outside role'
            
        });

        it("shouldnt manage owners role by none owners", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);

            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRole(uint8,uint8,bool,bool,uint256,uint64)', 
                [rolesIndex.get('role1'), rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration]
            );

            await mixedCall(
                CommunityInstance, 
                trustedForwardMode, 
                owner, 
                'manageRole(uint8,uint8,bool,bool,uint256,uint64)', 
                [rolesIndex.get('role2'), rolesIndex.get('owners'),canGrantRole, canRevokeRole, maxAddresses, duration],
                "WRONG_OFROLE '" +rolesTitle.get('owners')+"'"
            );
        }); 

        it("possible to grant with cycle.", async () => {
            
            // create roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role5')]);

            // manage roles to cycle 
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role2'), rolesIndex.get('role3'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role3'), rolesIndex.get('role4'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role4'), rolesIndex.get('role5'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role5'), rolesIndex.get('role2'),canGrantRole, canRevokeRole, maxAddresses, duration]);
            
            // account2
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);
            
            // check
            rolesList = await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]);
            expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
            
            // check via hasRole
            expect(await CommunityInstance.connect(owner).hasRole(accountTwo.address, rolesIndex.get('role2'))).to.be.eq(true);
            expect(await CommunityInstance.connect(owner).getRoleIndex(rolesTitle.get('role2'))).to.be.eq(rolesIndex.get('role2'));

            // account 3
            await mixedCall(CommunityInstance, trustedForwardMode, accountTwo, 'grantRoles(address[],uint8[])', [
                [accountThree.address], [rolesIndex.get('role3')]
            ]);
            
            // account 4
            await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'grantRoles(address[],uint8[])', [
                [accountFourth.address], [rolesIndex.get('role4')]
            ]);
            
            // account 5
            await mixedCall(CommunityInstance, trustedForwardMode, accountFourth, 'grantRoles(address[],uint8[])', [
                [accountFive.address], [rolesIndex.get('role5')]
            ]);
            
            // account 5 remove account2 from role2
            await mixedCall(CommunityInstance, trustedForwardMode, accountFive, 'revokeRoles(address[],uint8[])', [
                [accountTwo.address], [rolesIndex.get('role2')]
            ]);
            
            // check again
            rolesList = await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]);
            expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(false); 

            // check via hasRole
            expect(await CommunityInstance.connect(owner).hasRole(accountTwo.address, rolesIndex.get('role2'))).to.be.eq(false);
        });

        it("check params input in `manageRoles`", async () => {
            // create roles
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2'),rolesIndex.get('role2')], 
                    [rolesIndex.get('role3')],
                    [canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses], 
                    [duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2')], 
                    [rolesIndex.get('role3'),rolesIndex.get('role3')],
                    [canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses], 
                    [duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2')], 
                    [rolesIndex.get('role3')],
                    [canGrantRole,canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses], 
                    [duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2')], 
                    [rolesIndex.get('role3')],
                    [canGrantRole], 
                    [canRevokeRole,canRevokeRole], 
                    [maxAddresses], 
                    [duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2')], 
                    [rolesIndex.get('role3')],
                    [canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses,maxAddresses], 
                    [duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRoles(uint8[],uint8[],bool[],bool[],uint256[],uint64[])', [
                    [rolesIndex.get('role2')], 
                    [rolesIndex.get('role3')],
                    [canGrantRole], 
                    [canRevokeRole], 
                    [maxAddresses], 
                    [duration,duration]
                ],
                "WRONG_INPUT_LENGTH"
            );
            
        });

        it("check amount of roles after revoke(empty strings)", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesIndex.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address], [rolesIndex.get('role1')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address], [rolesIndex.get('role1')]
            ]);
            
            var rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFive.address]));

            expect(BigInt(rolesList[0].length)).to.be.eq(ZERO);

        });

        it("check amount of roles after revoke(empty strings)::more roles", async () => {
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role5')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role6')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role1')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role1')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role2')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role2')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role3')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role3')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role4')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role5')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role5')]]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [[accountFive.address], [rolesIndex.get('role4')]]);
            
            var rolesList;

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFive.address]));
            expect(BigInt(rolesList[0].length)).to.be.eq(ZERO);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role1'),rolesIndex.get('role2')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role3'),rolesIndex.get('role4')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role5'),rolesIndex.get('role6')]
            ]);

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFive.address]));
            expect(BigInt(rolesList[0].length)).to.be.eq(SIX); // role#1,role#2,role#3,role#4,role#5,role#6

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role6'),rolesIndex.get('role1')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role2'),rolesIndex.get('role3')]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'revokeRoles(address[],uint8[])', [
                [accountFive.address], 
                [rolesIndex.get('role4'),rolesIndex.get('role5')]
            ]);

            rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFive.address]));
            expect(BigInt(rolesList[0].length)).to.be.eq(ZERO); 
        });

        it("check getRolesInAllCommunities", async () => {
            
            
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);

            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [
                    accountFive.address,
                    accountFive.address,
                    accountFive.address,
                    accountFive.address
                ], [
                    rolesIndex.get('role1'),
                    rolesIndex.get('role2'),
                    rolesIndex.get('role3'),
                    rolesIndex.get('role4'),
                ]
            ]);
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                [
                    accountFourth.address,
                    accountFourth.address
                ], 
                [
                    rolesIndex.get('role2'),
                    rolesIndex.get('role3')
                ]
            ]);

            let t1 = await CommunityFactory.connect(owner).getRolesInAllCommunities(accountFive.address);
            let t2 = await CommunityFactory.connect(owner).getRolesInAllCommunities(accountFourth.address);
            
            expect(t1["communities"][0]).to.be.eq(CommunityInstance.target);
            expect(t2["communities"][0]).to.be.eq(CommunityInstance.target);
            expect(
                t1["roles"][0].join('')
                ).to.be.eq([
                    rolesIndex.get('role1'),
                    rolesIndex.get('role2'),
                    rolesIndex.get('role3'),
                    rolesIndex.get('role4'),
                ].join('')
            );

            expect(
                t2["roles"][0].join('')
                ).to.be.eq([
                    rolesIndex.get('role2'),
                    rolesIndex.get('role3')
                ].join('')
            );

            //console.log(t1);
            
            
        });

        describe("test using params as array", function () {
            beforeEach("prepare", async() => {
                // create roles
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role4')]);

                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        owner.address,
                        accountTwo.address,
                        accountThree.address
                    ], 
                    [
                        rolesIndex.get('role1'),
                        rolesIndex.get('role2'),
                        rolesIndex.get('role3'),
                    ]
                ]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        accountFourth.address,
                        accountFive.address
                    ], 
                    [
                        rolesIndex.get('role2'),
                        rolesIndex.get('role3')
                    ]
                ]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [
                    [
                        accountSix.address,
                        accountSeven.address
                    ], 
                    [
                        rolesIndex.get('role1'),
                        rolesIndex.get('role2')
                    ]
                ]);
            }); 

            it("check getRoles(address)", async () => {

                
                ///// checking by Members
                var rolesList;
                // owner
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([owner.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountTwo
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountTwo.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountThree
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountThree.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountFourth
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFourth.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(false); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountFive
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountFive.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(false); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountSix
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountSix.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(false); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 
                // accountSeven
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountSeven.address]));
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(false); 
                expect(rolesList[0].includes(rolesIndex.get('role4'))).to.be.eq(false); 

            });

            it("check getRoles(address[])", async () => {
                let rolesList;

                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountTwo.address, accountThree.address]));
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role4'))).to.be.eq(false); 

                // 6
                expect(BigInt(rolesList[0].concat(rolesList[1]).length)).to.be.eq(SIX);
                
                rolesList = (await CommunityInstance.connect(accountTen)["getRoles(address[])"]([accountThree.address, accountFive.address]));
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role3'))).to.be.eq(true); 
                expect((rolesList[0].concat(rolesList[1])).includes(rolesIndex.get('role4'))).to.be.eq(false); 

                // 5
                expect(BigInt(rolesList[0].concat(rolesList[1]).length)).to.be.eq(FIVE);
            });

            it("check addressesCount(uint8)", async () => {
                let memberCount;
                // role1
                memberCount = (await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role1')));
                expect(memberCount).to.be.eq(5);
                // role2
                memberCount = (await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role2')));
                expect(memberCount).to.be.eq(7);
                // role3
                memberCount = (await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role3')));
                expect(memberCount).to.be.eq(5);
                // role4
                memberCount = (await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role4')));
                expect(memberCount).to.be.eq(0);
            });

            it("check addressesCount()", async () => {
                let memberCount = (await CommunityInstance.connect(accountTen)["addressesCount()"]());
                // 8 - owner, factory!, accountTwo, accountThree, accountFourth, accountFive, accountSix, accountSeven
                expect(memberCount).to.be.eq(8);
            });

            it("check addressesCount(address[])", async () => {
                let allMembersInRole1 = await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role1'));
                let allMembersInRole2 = await CommunityInstance.connect(accountTen)["addressesCount(uint8)"](rolesIndex.get('role2'));

                // accounts in role1 - One, Two,Three, Six, Seven
                // accounts in role2 - One, Two,Three, Fourth, Five, Six, Seven

                expect(allMembersInRole1 + allMembersInRole2).to.be.eq(12); 
                
            });

            it("check getAddresses()", async () => {
                let arr = await CommunityInstance.connect(accountTen)['getAddresses()']();

                //add some1 user to last created role
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountTwo.address], [rolesIndex.get('role4')]]);

                // owners,admins,members,alumni,visitors,role1,role2,role3,role4
                expect(BigInt(arr.length)).to.be.eq(NINE);

                arr.forEach((addresses, keyAddr, mapAddr) => {
                    var index = keyAddr + 1;

                    switch (index) {
                        case rolesTitle.get('owners'):
                            addresses.forEach((value, key, map) => {
                                expect([
                                    owner.address,
                                    CommunityFactory.target
                                ].includes(value)).to.be.eq(true);
                            });
                            break;
                        case rolesTitle.get('role1'):
                            addresses.forEach((value, key, map) => {
                                expect([
                                    owner.address,
                                    accountTwo.address,
                                    accountThree.address,
                                    accountSix.address,
                                    accountSeven.address
                                ].includes(value)).to.be.eq(true);
                            });
                            break;
                        case rolesTitle.get('role2'):
                            addresses.forEach((value, key, map) => {
                                expect([
                                    owner.address,
                                    accountTwo.address,
                                    accountThree.address,
                                    accountFourth.address,
                                    accountFive.address,
                                    accountSix.address,
                                    accountSeven.address
                                ].includes(value)).to.be.eq(true);
                            });
                            break;
                        case rolesTitle.get('role3'):
                            addresses.forEach((value, key, map) => {
                                expect([
                                    owner.address,
                                    accountTwo.address,
                                    accountThree.address,
                                    accountFourth.address,
                                    accountFive.address
                                ].includes(value)).to.be.eq(true);
                            });
                            break;
                        case rolesTitle.get('role4'):
                            addresses.forEach((value, key, map) => {
                                expect([accountTwo.address].includes(value)).to.be.eq(true);
                            });
                            expect([
                                owner.address,
                                accountThree.address,
                                accountFourth.address,
                                accountFive.address,
                                accountSix.address,
                                accountSeven.address
                            ].includes(value)).to.be.eq(false);
                            break;
                        case rolesTitle.get('members'):
                        case rolesTitle.get('alumni'):
                        case rolesTitle.get('admins'):
                        case rolesTitle.get('visitors'):
                            expect(BigInt(addresses.length)).to.be.eq(ZERO);
                                
                            break;

                    }

                });

            });
            it("check getAddressesByRole(address[])", async () => {
                let arr;

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),0,10);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(SEVEN);
                expect(arr[0][0]).to.be.eq(owner.address);
                expect(arr[0][1]).to.be.eq(accountTwo.address);
                expect(arr[0][2]).to.be.eq(accountThree.address);
                expect(arr[0][3]).to.be.eq(accountFourth.address);
                expect(arr[0][4]).to.be.eq(accountFive.address);
                expect(arr[0][5]).to.be.eq(accountSix.address);
                expect(arr[0][6]).to.be.eq(accountSeven.address);

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),1,10);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(SIX);
                expect(arr[0][0]).to.be.eq(accountTwo.address);
                expect(arr[0][1]).to.be.eq(accountThree.address);
                expect(arr[0][2]).to.be.eq(accountFourth.address);
                expect(arr[0][3]).to.be.eq(accountFive.address);
                expect(arr[0][4]).to.be.eq(accountSix.address);
                expect(arr[0][5]).to.be.eq(accountSeven.address);

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),5,10);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(TWO);
                expect(arr[0][0]).to.be.eq(accountSix.address);
                expect(arr[0][1]).to.be.eq(accountSeven.address);

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),2,3);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(THREE);
                expect(arr[0][0]).to.be.eq(accountThree.address);
                expect(arr[0][1]).to.be.eq(accountFourth.address);
                expect(arr[0][2]).to.be.eq(accountFive.address);
                
                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),5,0);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(ZERO);

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),0,0);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(ZERO);

                arr = await CommunityInstance.connect(accountTen).getAddressesByRole(rolesIndex.get('role2'),100,100);
                expect(BigInt(arr.length)).to.be.eq(ONE);
                expect(BigInt(arr[0].length)).to.be.eq(ZERO);
            });
        }); 

        describe("invites", function () {
            
            const validChainId = hre.network.config.chainId;
            const wrongChainId = 12345678;
            const timestampInThePast = 111111;
            const timestampInTheFuture = 999999999999;
            //var privatekey1, 
            //privatekey2,
            var AuthorizedInviteManagerStartingBalance;
            
            beforeEach("deploying", async() => {
                // privatekey1 = owner._signingKey()["privateKey"];
                // privatekey2 = accountTwo._signingKey()["privateKey"];
               
                const amountETHSendToContract = ethers.parseEther('2'); // 2ETH

                // send ETH to Contract      
                await accountThree.sendTransaction({
                    to: AuthorizedInviteManager.target, 
                    value: amountETHSendToContract
                });

                const AuthorizedInviteManagerStartingBalance = (await ethers.provider.getBalance(AuthorizedInviteManager.target));
             
                // create roles
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'createRole(string)', [rolesTitle.get('role3')]);
                
            });
            it("should wait a timeout if reserved before", async () => {   
                let adminMsg = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await owner.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                //const hash = utils.keccak256(utils.toUtf8Bytes(sSig+rSig));
                
                const hash = ethers.keccak256(
                    AbiCoder.defaultAbiCoder().encode(
                        ["bytes", "bytes"],
                        [ sSig, rSig ]
                    )
                );

                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteReserve(bytes32)', [hash]);

                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteReserve(bytes32)', [hash], 'Already reserved');

                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig], 'Invite still reserved');

                const reserveDelay = await AuthorizedInviteManager.RESERVE_DELAY();

                await time.increase(reserveDelay * BigInt(1000));

                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                let invite = await AuthorizedInviteManager.connect(relayer).inviteView(sSig);
                expect(invite.exists).to.be.true; // 'invite not found';
                expect(invite.exists && invite.used==false).to.be.true; // 'invite not used before'
            });

            it("invites by admins which cant add any role from list", async () => {   
                let adminMsg = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');;
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);
                // imitate inviteAccept
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Can not add no one role");

            }); 

            it("invites by admins which cant add role (1 of 2)", async () => {   
                let adminMsg = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [ [accountThree.address], [rolesIndex.get('role3')]]);
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'manageRole(uint8,uint8,bool,bool,uint256,uint64)', [rolesIndex.get('role3'),rolesIndex.get('role2'),canGrantRole,canRevokeRole,maxAddresses,duration]);
                
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await accountThree.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                // imitate invitePrepare and check it in system
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                // imitate inviteAccept
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig]);
                
                // check roles of accountTwo
                rolesList = await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]);
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(false); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 

            }); 

            it("invites test", async () => { 

                let txTmp;
                // generate messages and signatures
                    
                //let adminMsg = 'invite:'+CommunityInstance.target+':role1,role2,role3:GregMagarshak';
                let adminMsg = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role1'),
                        rolesTitle.get('role2'),
                        rolesTitle.get('role3')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');
                let recipientMsg = ''+accountTwo.address+':John Doe';
                
                let sSig = await owner.signMessage(adminMsg);

                let rSig = await accountTwo.signMessage(recipientMsg);

                var recipientStartingBalance = (await ethers.provider.getBalance(accountTwo.address));
                var relayerStartingBalance = (await ethers.provider.getBalance(relayer.address));
                const AuthorizedInviteManagerStartingBalance = (await ethers.provider.getBalance(AuthorizedInviteManager.target));

                // imitate invitePrepare and check it in system
                txTmp = await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);
                const txInvitePrepare = await txTmp.wait();
                // const relayerMiddleBalance = (await ethers.provider.getBalance(relayer.address));
                // console.log('relayerMiddleBalance     =', relayerMiddleBalance.toString());

                let invite = await AuthorizedInviteManager.connect(relayer).inviteView(sSig);
                expect(invite.exists).to.be.true; // 'invite not found';
                expect(invite.exists && invite.used==false).to.be.true; // 'invite not used before'
                // console.log('(1)invite.gasCost=',invite.gasCost);
 
                // imitate inviteAccept
                txTmp = await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig]);

                const txInviteAccept = await txTmp.wait();   
                let invite2 = await AuthorizedInviteManager.connect(relayer).inviteView(sSig);
                // console.log('(2)invite.gasCost=',invite2.gasCost);

                const relayerEndingBalance = await ethers.provider.getBalance(relayer.address);
                const recipientEndingBalance = await ethers.provider.getBalance(accountTwo.address);
                const AuthorizedInviteManagerEndingBalance = (await ethers.provider.getBalance(AuthorizedInviteManager.target));
                
                // calculate tx cost
                // let txInvitePrepareCost = BigInt(txInvitePrepare.cumulativeGasUsed) * BigInt(txInvitePrepare.effectiveGasPrice)
                // let txInviteAcceptCost = BigInt(txInviteAccept.cumulativeGasUsed) * BigInt(txInviteAccept.effectiveGasPrice)
                

                // check roles of accountTwo
                
                var rolesList = await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]);
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(true); 
                
            });

            it("check first invites test", async () => {   
  
                // Adding another two owners (accountSix) (accountSeven)
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[accountSix.address, accountSeven.address], [rolesIndex.get('owners'), rolesIndex.get('owners')]]);

                let adminMsgFirst = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role1')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');
                let adminMsgSecond = [
                    'invite',
                    CommunityInstance.target,
                    [
                        rolesTitle.get('role2')
                    ].join(','),
                    validChainId,
                    timestampInTheFuture,
                    'GregMagarshak'
                    ].join(':');
                let recipientMsg = ''+accountTwo.address+':John Doe';

                const rSig = await accountTwo.signMessage(recipientMsg);

                const sSigFirst = await owner.signMessage(adminMsgFirst);
                
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSigFirst,rSig]);
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsgFirst, sSigFirst, recipientMsg, rSig]);

                //  make with another owner
                const sSigSecond = await accountSeven.signMessage(adminMsgSecond);
                
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, accountSix, 'invitePrepare(bytes,bytes)', [sSigSecond,rSig]);
                await mixedCall(AuthorizedInviteManager, trustedForwardMode, accountSix, 'inviteAccept(string,bytes,string,bytes)', [adminMsgSecond, sSigSecond, recipientMsg, rSig]);

                // check roles of accountTwo
                rolesList = await CommunityInstance.connect(owner)["getRoles(address[])"]([accountTwo.address]);
                expect(rolesList[0].includes(rolesIndex.get('role1'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role2'))).to.be.eq(true); 
                expect(rolesList[0].includes(rolesIndex.get('role3'))).to.be.eq(false); 
            });

            
            describe("signatures mismatch", function () {
                
                it("when recipient address not equal", async () => {   
                    let adminMsg = [
                        'invite',
                        CommunityInstance.target,
                        [
                            rolesTitle.get('role1'),
                            rolesTitle.get('role2'),
                            rolesTitle.get('role3')
                        ].join(','),
                        validChainId,
                        timestampInTheFuture,
                        'GregMagarshak'
                        ].join(':');
                    let recipientMsg = ''+accountNine.address+':John Doe';
                    
                    let sSig = await accountThree.signMessage(adminMsg);

                    let rSig = await accountTwo.signMessage(recipientMsg);

                    // imitate invitePrepare and check it in system
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                    // imitate inviteAccept
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");

                });

                it("when contract address not equal", async () => {   
                    let adminMsg = [
                        'invite',
                        accountThree.address,
                        [
                            rolesTitle.get('role1'),
                            rolesTitle.get('role2'),
                            rolesTitle.get('role3')
                        ].join(','),
                        validChainId,
                        timestampInTheFuture,
                        'GregMagarshak'
                        ].join(':');
                    let recipientMsg = ''+accountTwo.address+':John Doe';
                    
                    let sSig = await accountThree.signMessage(adminMsg);

                    let rSig = await accountTwo.signMessage(recipientMsg);

                    // imitate invitePrepare and check it in system
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                    // imitate inviteAccept
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");
                    

                });

                it("when generated for another chain(wrong chainId)", async () => {  
                    
                    let adminMsg = [
                        'invite',
                        accountThree.address,
                        [
                            rolesTitle.get('role1'),
                            rolesTitle.get('role2'),
                            rolesTitle.get('role3')
                        ].join(','),
                        wrongChainId,
                        timestampInTheFuture,
                        'GregMagarshak'
                        ].join(':');;
                    let recipientMsg = ''+accountTwo.address+':John Doe';
                    
                    let sSig = await accountThree.signMessage(adminMsg);

                    let rSig = await accountTwo.signMessage(recipientMsg);

                    // imitate invitePrepare and check it in system
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                    // imitate inviteAccept
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");
                    

                });

                it("when invite expired", async () => {  
                    
                    let adminMsg = [
                        'invite',
                        accountThree.address,
                        [
                            rolesTitle.get('role1'),
                            rolesTitle.get('role2'),
                            rolesTitle.get('role3')
                        ].join(','),
                        validChainId,
                        timestampInThePast,
                        'GregMagarshak'
                        ].join(':');;
                    let recipientMsg = ''+accountTwo.address+':John Doe';
                    
                    let sSig = await accountThree.signMessage(adminMsg);

                    let rSig = await accountTwo.signMessage(recipientMsg);

                    // imitate invitePrepare and check it in system
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'invitePrepare(bytes,bytes)', [sSig,rSig]);

                    // imitate inviteAccept
                    await mixedCall(AuthorizedInviteManager, trustedForwardMode, relayer, 'inviteAccept(string,bytes,string,bytes)', [adminMsg, sSig, recipientMsg, rSig],"Signature are mismatch");
                    

                });

            });
          
        });


    });

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''}CommunityERC721 tests`, function () {
        
        var CommunityInstance;
        
        beforeEach("deploying", async() => {
            
            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(accountTen)["produce(address,address,string,string,string)"](NO_HOOK, NO_INVITED_HOOK, TOKEN_NAME, TOKEN_SYMBOL,CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

            if (trustedForwardMode) {
                await CommunityInstance.connect(accountTen).setTrustedForwarder(trustedForwarder.address);
            }

        });

        it("name should be `Community`", async () => {
            var name = await CommunityInstance.connect(accountTen).name();
            await expect(name).to.be.eq(TOKEN_NAME);
        });

        it("symbol should be `Community`", async () => {
            var name = await CommunityInstance.connect(accountTen).symbol();
            await expect(name).to.be.eq(TOKEN_SYMBOL,CONTRACT_URI);
        });
        
        describe("erc721 tokens tests", function () {
            let generateTokenId = function(address, roleIndex) {

                // roleIndex<<160 + address
                let t = BigInt(roleIndex) << BigInt(160);

                let t2 = BigInt(address);

                let ret = (t + t2).toString(16);
                return "0x"+ret.padStart(64, '0');
                
            }
            beforeEach("deploying", async() => {

                // create roles
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role1')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role2')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role3')]);
                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'createRole(string)', [rolesTitle.get('role4')]);

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [owner.address], 
                    [rolesIndex.get('role1')]
                ]);

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [accountTwo.address], 
                    [rolesIndex.get('role2')]
                ]);

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'grantRoles(address[],uint8[])', [
                    [
                        accountThree.address,
                        accountSix.address
                    ], 
                    [
                        rolesIndex.get('role3')
                    ]
                ]);
                
            });
            
            it("should correct balanceOf for holders", async () => {
                
                expect(await CommunityInstance.balanceOf(owner.address)).to.be.eq(ONE);

                expect(await CommunityInstance.balanceOf(accountTwo.address)).to.be.eq(ONE);
                expect(await CommunityInstance.balanceOf(accountThree.address)).to.be.eq(ONE);
                expect(await CommunityInstance.balanceOf(accountFourth.address)).to.be.eq(ZERO);
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
                        "0x"//[]
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

            it("check setRoleURI", async () => {
                let uri = "http://google.com/";
                let extrauri = "http://google.com/extra";

                //Sender can not manage Members with role
                await mixedCall(CommunityInstance, trustedForwardMode, accountNine, 'setRoleURI(uint8,string)', [rolesIndex.get('role3'), uri], "MISSING_ROLE '" +rolesTitle.get('owners')+"'");

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq("");

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
                ).to.be.eq("");

                await mixedCall(CommunityInstance, trustedForwardMode, accountThree, 'setRoleURI(uint8,string)', [rolesIndex.get('role3'),uri], "MISSING_ROLE '" +rolesTitle.get('owners')+"'");

                await mixedCall(CommunityInstance, trustedForwardMode, accountTen, 'setRoleURI(uint8,string)', [rolesIndex.get('role3'),uri]);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountThree.address, rolesIndex.get('role3')))
                ).to.be.eq(uri);

                expect(
                    await CommunityInstance.tokenURI(generateTokenId(accountSix.address, rolesIndex.get('role3')))
                ).to.be.eq(uri);
                
            });

        });
    });

    describe(`${trustedForwardMode ? '[trusted forwarder]' : ''} Ownable with different semantics tests`, function () {
        var CommunityInstance;
        
        beforeEach("deploying", async() => {
            
            let tx,rc,event,instance,instancesCount;
            //
            tx = await CommunityFactory.connect(owner)["produce(address,address,string,string,string)"](NO_HOOK, NO_INVITED_HOOK, TOKEN_NAME, TOKEN_SYMBOL, CONTRACT_URI);
            rc = await tx.wait(); // 0ms, as tx is already confirmed
            event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
            [instance, instancesCount] = event.args;
            CommunityInstance = await ethers.getContractAt("Community",instance);

            if (trustedForwardMode) {
                await CommunityInstance.connect(owner).setTrustedForwarder(trustedForwarder.address);
            }

        });

        it("should renounce ownership", async () => {
            var rolesList;
            const addressesForTest = [accountTwo, accountThree, accountFourth];

            //grant owners role to several users
            for (var i in addressesForTest) {
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[addressesForTest[i].address], [rolesIndex.get('owners')]]);
            };

            // all addresses should have owners role
            for (var i in addressesForTest) {
                rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([addressesForTest[i].address]));
                expect(rolesList[0].includes(rolesIndex.get('owners'))).to.be.eq(true); // else outside OWNERS role            
            };

            // try to renounceownership from last owners on the list
            await mixedCall(CommunityInstance, trustedForwardMode, addressesForTest[addressesForTest.length-1], 'renounceOwnership()', []);    

            // now all addresses shouldn't have owners role.
            for (var i in addressesForTest) {
                rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([addressesForTest[i].address]));
                expect(rolesList[0].includes(rolesIndex.get('owners'))).to.be.eq(false); // else outside OWNERS role            
            };
            // and initial owner too
            rolesList = (await CommunityInstance.connect(owner)["getRoles(address[])"]([owner.address]));
            expect(rolesList[0].includes(rolesIndex.get('owners'))).to.be.eq(false); // else outside OWNERS role            

        });

        it("should transfer ownership", async () => {
            const addressesForTest = [accountTwo.address, accountThree.address, accountFourth.address];

            //grant owners role to several users
            for (var i in addressesForTest) {
                await mixedCall(CommunityInstance, trustedForwardMode, owner, 'grantRoles(address[],uint8[])', [[addressesForTest[i]], [rolesIndex.get('owners')]]);
            };

            // calculate members on the owner role
            let ownersAmountBefore = await CommunityInstance.connect(owner)["getAddresses(uint8[])"]([rolesIndex.get('owners')]);

            // owner should have `owner`role .
            expect(await CommunityInstance.connect(owner).isOwner(owner.address)).to.be.eq(true);
            // accountFive shouldn't have `owner`role. before transfer ownership
            expect(await CommunityInstance.connect(owner).isOwner(accountFive.address)).to.be.eq(false);

            // try to transferOwnership to accountFive
            await mixedCall(CommunityInstance, trustedForwardMode, owner, 'transferOwnership(address)', [accountFive.address]);

            // calculate members on the owner role after transferOwnership
            let ownersAmountAfter = await CommunityInstance.connect(owner)["getAddresses(uint8[])"]([rolesIndex.get('owners')]);

            // owner should loss `owner`role .
            expect(await CommunityInstance.connect(owner).isOwner(owner.address)).to.be.eq(false);
            // accountFive should obtain `owner`role .
            expect(await CommunityInstance.connect(owner).isOwner(accountFive.address)).to.be.eq(true);
            // total amount of `owners` members should left the same
            expect(ownersAmountBefore[0].length).to.be.eq(ownersAmountAfter[0].length);


        });
        
    });

    }

});
