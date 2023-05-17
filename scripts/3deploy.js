const fs = require('fs');
//const HDWalletProvider = require('truffle-hdwallet-provider');

function get_data(_message) {
    return new Promise(function(resolve, reject) {
        fs.readFile('./scripts/arguments.json', (err, data) => {
            if (err) {
                if (err.code == 'ENOENT' && err.syscall == 'open' && err.errno == -4058) {
					let obj = {};
					data = JSON.stringify(obj, null, "");
                    fs.writeFile('./scripts/arguments.json', data, (err) => {
                        if (err) throw err;
                        resolve(data);
                    });
                } else {
                    throw err;
                }
            } else {
            	resolve(data);
			}
        });
    });
}

async function main() {
	var data = await get_data();
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

	const deployerBalanceBefore = await depl_community.getBalance();
	console.log("Account balance:", (deployerBalanceBefore).toString());

	const CommunityF = await ethers.getContractFactory("CommunityFactory");

	this.factory = await CommunityF.connect(depl_community).deploy(...params);

	console.log("Factory deployed at:", this.factory.address);
	console.log("with params:", [..._params]);

	console.log("registered with release manager:", data_object.releaseManager);
    
    const deployerBalanceAfter = await depl_community.getBalance();
    console.log("Spent:", ethers.utils.formatEther(deployerBalanceBefore.sub(deployerBalanceAfter)));
    console.log("gasPrice:", ethers.utils.formatUnits((await network.provider.send("eth_gasPrice")), "gwei")," gwei");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });