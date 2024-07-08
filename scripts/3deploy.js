const common = require('./lib/common.js');

async function main() {
	var data = await common.get_data();
    var data_object_root = JSON.parse(data);
	if (typeof data_object_root[hre.network.name] === 'undefined') {
		throw("Arguments file: missed data");
    } else if (typeof data_object_root[hre.network.name] === 'undefined') {
		throw("Arguments file: missed network data");
    }
	data_object = data_object_root[hre.network.name];
	if (
		typeof data_object.implementationCommunity === 'undefined' ||
		typeof data_object.authorizedInviteManager === 'undefined' ||
		typeof data_object.releaseManager === 'undefined' ||
		!data_object.implementationCommunity ||
		!data_object.authorizedInviteManager ||
		!data_object.releaseManager
	) {
		throw("Arguments file: wrong addresses");
	}

	//const [deployer] = await ethers.getSigners();
	// const [
    //     depl_local,
    //     depl_auxiliary,
    //     depl_releasemanager,
    //     depl_invitemanager,
	// 	depl_community
    // ] = await ethers.getSigners();
	
	var depl_local,
        depl_auxiliary,
        depl_releasemanager,
        depl_invitemanager,
		depl_community;

    var signers = await ethers.getSigners();
    if (signers.length == 1) {
        depl_local = signers[0];
        depl_auxiliary = signers[0];
        depl_releasemanager = signers[0];
        depl_invitemanager = signers[0];
		depl_community = signers[0];
    } else {
        [
            depl_local,
            depl_auxiliary,
            depl_releasemanager,
            depl_invitemanager,
			depl_community
        ] = signers;
    }

	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	console.log(
		"Deploying contracts with the account:",
		depl_community.address
	);

	var options = {
		//gasPrice: ethers.utils.parseUnits('50', 'gwei'), 
		//gasLimit: 5e6
	};
	let _params = [
		data_object.implementationCommunity,
		ZERO_ADDRESS, //costmanager
		data_object.releaseManager,
		data_object.authorizedInviteManager, //defaultAuthorizedInviteManager
	]
	let params = [
		..._params,
		options
	]

	const deployerBalanceBefore = await ethers.provider.getBalance(depl_community.address);
	console.log("Account balance:", (deployerBalanceBefore).toString());

	const CommunityF = await ethers.getContractFactory("CommunityFactory");

	this.factory = await common.wrapDeploy('CommunityF', CommunityF, depl_community, {params: params});

	console.log("Factory deployed at:", this.factory.target);
	console.log("with params:", [..._params]);

	console.log("registered with release manager:", data_object.releaseManager);

    const releaseManager = await ethers.getContractAt("ReleaseManager",data_object.releaseManager);
    let txNewRelease = await releaseManager.connect(depl_releasemanager).newRelease(
        [this.factory.target], 
        [
            [
                1,//uint8 factoryIndex; 
                1,//uint16 releaseTag; 
                "0x53696c766572000000000000000000000000000000000000"//bytes24 factoryChangeNotes;
            ]
        ]
    );

    console.log('newRelease - waiting');
    await txNewRelease.wait(3);
    console.log('newRelease - mined');


    
    const deployerBalanceAfter = await ethers.provider.getBalance(depl_community.address);
    console.log("Spent:", ethers.formatEther(deployerBalanceBefore - deployerBalanceAfter));
    console.log("gasPrice:", ethers.formatUnits((await network.provider.send("eth_gasPrice")), "gwei")," gwei");

	console.log("verifying");
    await hre.run("verify:verify", {address: this.factory.target, constructorArguments: _params});
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });