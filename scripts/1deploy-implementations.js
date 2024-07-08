const common = require('./lib/common.js');

async function main() {
    
	var data = await common.get_data();

    var data_object_root = JSON.parse(data);
	var data_object = {};

    data_object.time_created = Date.now();
	// if (typeof data_object_root[hre.network.name] === 'undefined') {
    //     data_object.time_created = Date.now()
    // } else {
    //     data_object = data_object_root[hre.network.name];
    // }
	//----------------

	//const [deployer] = await ethers.getSigners();
    // const [
    //     /*depl_local*/,
    //     deployer,
    //     /*depl_releasemanager*/,
    //     /*depl_invitemanager*/
    // ] = await ethers.getSigners();
    var signers = await ethers.getSigners();
    const provider = ethers.provider;
    var deployer;
    if (signers.length == 1) {
        deployer = signers[0];
        
    } else {
        [
            /*depl_local*/,
            deployer,
            /*depl_releasemanager*/,
            /*depl_invitemanager*/
        ] = signers;
    }

	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const RELEASE_MANAGER = hre.network.name == 'polygonMumbai'? process.env.RELEASE_MANAGER_MUMBAI : process.env.RELEASE_MANAGER;
	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	// var options = {
	// 	//gasPrice: ethers.utils.parseUnits('50', 'gwei'), 
	// 	gasLimit: 10e6
	// };

    const deployerBalanceBefore = await provider.getBalance(deployer.address);
	console.log("Account balance:", (deployerBalanceBefore).toString());

	const CommunityF = await ethers.getContractFactory("Community");
    const AuthorizedInviteManagerF = await ethers.getContractFactory("AuthorizedInviteManager");

	//let implementationCommunity                 = await CommunityF.connect(deployer).deploy();
    let implementationCommunity = await common.wrapDeploy('CommunityF', CommunityF, deployer);

    let implementationAuthorizedInviteManager   = await common.wrapDeploy('AuthorizedInviteManagerF', AuthorizedInviteManagerF, deployer);

	console.log("Implementations:");
	console.log("  Community deployed at:               ", implementationCommunity.target);
    console.log("  AuthorizedInviteManager deployed at: ", implementationAuthorizedInviteManager.target);
    console.log("Linked with manager:");
    console.log("  Release manager:", RELEASE_MANAGER);

	data_object.implementationCommunity 	            = implementationCommunity.target;
    data_object.implementationAuthorizedInviteManager   = implementationAuthorizedInviteManager.target;

    data_object.releaseManager	                        = RELEASE_MANAGER;

    const deployerBalanceAfter = await provider.getBalance(deployer.address);
    console.log("Spent:", ethers.formatEther(deployerBalanceBefore - deployerBalanceAfter));
    console.log("gasPrice:", ethers.formatUnits((await network.provider.send("eth_gasPrice")), "gwei")," gwei");

	//---
	const ts_updated = Date.now();
    data_object.time_updated = ts_updated;
    data_object_root[`${hre.network.name}`] = data_object;
    data_object_root.time_updated = ts_updated;
    let data_to_write = JSON.stringify(data_object_root, null, 2);
	console.log(data_to_write);
    await common.write_data(data_to_write);

    console.log('verifying');
    await hre.run("verify:verify", {address: data_object.implementationCommunity, constructorArguments: []});
    await hre.run("verify:verify", {address: data_object.implementationAuthorizedInviteManager, constructorArguments: []});
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });