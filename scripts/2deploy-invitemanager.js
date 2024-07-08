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
		typeof data_object.implementationAuthorizedInviteManager === 'undefined' ||
		typeof data_object.releaseManager === 'undefined' ||
		!data_object.implementationAuthorizedInviteManager ||
		!data_object.releaseManager
	) {
		throw("Arguments file: wrong addresses");
	}
        // process.env.private_key,
        // process.env.private_key_auxiliary,
        // process.env.private_key_releasemanager,
        // process.env.private_key_invitemanager
	// const [
    //     depl_local,
    //     depl_auxiliary,
    //     depl_releasemanager,
    //     depl_invitemanager
    // ] = await ethers.getSigners();

    
    var depl_local,
        depl_auxiliary,
        depl_releasemanager,
        depl_invitemanager;

    var signers = await ethers.getSigners();
    if (signers.length == 1) {
        depl_local = signers[0];
        depl_auxiliary = signers[0];
        depl_releasemanager = signers[0];
        depl_invitemanager = signers[0];
    } else {
        [
            depl_local,
            depl_auxiliary,
            depl_releasemanager,
            depl_invitemanager
        ] = signers;
    }

	
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	console.log(
		"Deploying contracts with the account:",
		depl_invitemanager.address
	);

	var options = {
		//gasPrice: ethers.utils.parseUnits('50', 'gwei'), 
		//gasLimit: 5e6
	};
	let _params = [
		data_object.implementationAuthorizedInviteManager,
		ZERO_ADDRESS, //costmanager
		data_object.releaseManager
	]
	let params = [
		..._params,
		options
	]

	const deployerBalanceBefore = await ethers.provider.getBalance(depl_invitemanager.address);
	console.log("Account balance:", (deployerBalanceBefore).toString());

	const AuthorizedInviteManagerF = await ethers.getContractFactory("AuthorizedInviteManagerFactory");

	this.factory = await common.wrapDeploy('AuthorizedInviteManagerF', AuthorizedInviteManagerF, depl_invitemanager, {params: params});

    const ReleaseManagerF = await ethers.getContractFactory("ReleaseManager");
    const releaseManager = await ethers.getContractAt("ReleaseManager",data_object.releaseManager);
    let txNewRelease = await releaseManager.connect(depl_releasemanager).newRelease(
        [this.factory.target], 
        [
            [
                21,//uint8 factoryIndex; 
                21,//uint16 releaseTag; 
                "0x53696c766572000000000000000000000000000000000000"//bytes24 factoryChangeNotes;
            ]
        ]
    );

    console.log('newRelease - waiting');
    await txNewRelease.wait(3);
    console.log('newRelease - mined');

    console.log('this.factory = ', this.factory.target);
    console.log('depl_invitemanager = ', depl_invitemanager.address);


    let tx = await this.factory.connect(depl_invitemanager).produce();
//console.log(tx);    
    console.log('produce - waiting');
    let rc = await tx.wait(3); // 0ms, as tx is already confirmed
    console.log('produce - mined');
    let event = rc.logs.find(event => event.fragment.name === 'InstanceCreated');
    let instance, instancesCount;
    [instance, instancesCount] = event.args;
    
    data_object.authorizedInviteManager   = instance;


	console.log("authorizedInviteManagerFactory deployed at:", this.factory.target);
	console.log("with params:", [..._params]);
    console.log("authorizedInviteManager deployed at:", instance);

	console.log("registered with release manager:", data_object.releaseManager);
    
    const deployerBalanceAfter = await ethers.provider.getBalance(depl_invitemanager.address);
    console.log("Spent:", ethers.formatEther(deployerBalanceBefore - deployerBalanceAfter));
    console.log("gasPrice:", ethers.formatUnits((await network.provider.send("eth_gasPrice")), "gwei")," gwei");

    //---
	const ts_updated = Date.now();
    data_object.time_updated = ts_updated;
    data_object_root[`${hre.network.name}`] = data_object;
    data_object_root.time_updated = ts_updated;
    let data_to_write = JSON.stringify(data_object_root, null, 2);
    await common.write_data(data_to_write);

    console.log("verifying");
    await hre.run("verify:verify", {address: this.factory.target, constructorArguments: _params});
    
    
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });