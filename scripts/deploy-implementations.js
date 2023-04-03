const fs = require('fs');
//const HDWalletProvider = require('truffle-hdwallet-provider');

function get_data(_message) {
    return new Promise(function(resolve, reject) {
        fs.readFile('./scripts/arguments.json', (err, data) => {
            if (err) {
				
                if (err.code == 'ENOENT' && err.syscall == 'open' && err.errno == -4058) {
                    fs.writeFile('./scripts/arguments.json', "", (err2) => {
                        if (err2) throw err2;
                        resolve();
                    });
                    data = ""
                } else {
                    throw err;
                }
            }
    
            resolve(data);
        });
    });
}

function write_data(_message) {
    return new Promise(function(resolve, reject) {
        fs.writeFile('./scripts/arguments.json', _message, (err) => {
            if (err) throw err;
            console.log('Data written to file');
            resolve();
        });
    });
}

async function main() {
    
	var data = await get_data();

    var data_object_root = JSON.parse(data);
	var data_object = {};
	if (typeof data_object_root[hre.network.name] === 'undefined') {
        data_object.time_created = Date.now()
    } else {
        data_object = data_object_root[hre.network.name];
    }
	//----------------

	const [deployer] = await ethers.getSigners();
	
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    const RELEASE_MANAGER = hre.network.name == 'mumbai'? process.env.RELEASE_MANAGER_MUMBAI : process.env.RELEASE_MANAGER;
	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	// var options = {
	// 	//gasPrice: ethers.utils.parseUnits('50', 'gwei'), 
	// 	gasLimit: 10e6
	// };
    
    const deployerBalanceBefore = await deployer.getBalance();
	console.log("Account balance:", (deployerBalanceBefore).toString());

	const CommunityF = await ethers.getContractFactory("Community");
	const CommunityStateF = await ethers.getContractFactory("CommunityState");
	const CommunityViewF = await ethers.getContractFactory("CommunityView");
        
	let implementationCommunity         = await CommunityF.connect(deployer).deploy();
	let implementationCommunityState    = await CommunityStateF.connect(deployer).deploy();
	let implementationCommunityView     = await CommunityViewF.connect(deployer).deploy();

	console.log("Implementations:");
	console.log("  Community deployed at:       ", implementationCommunity.address);
	console.log("  CommunityState deployed at:  ", implementationCommunityState.address);
	console.log("  CommunityView deployed at:   ", implementationCommunityView.address);
    console.log("Linked with manager:");
    console.log("  Release manager:", RELEASE_MANAGER);

	data_object.implementationCommunity 	= implementationCommunity.address;
	data_object.implementationCommunityState= implementationCommunityState.address;
	data_object.implementationCommunityView	= implementationCommunityView.address;
    data_object.releaseManager	            = RELEASE_MANAGER;

const deployerBalanceAfter = await deployer.getBalance();
console.log("Spent:", ethers.utils.formatEther(deployerBalanceBefore.sub(deployerBalanceAfter)));
console.log("gasPrice:", ethers.utils.formatUnits((await network.provider.send("eth_gasPrice")), "gwei")," gwei");

	//---
	const ts_updated = Date.now();
    data_object.time_updated = ts_updated;
    data_object_root[`${hre.network.name}`] = data_object;
    data_object_root.time_updated = ts_updated;
    let data_to_write = JSON.stringify(data_object_root, null, 2);
	console.log(data_to_write);
    await write_data(data_to_write);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });