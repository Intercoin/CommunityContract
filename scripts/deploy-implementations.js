async function main() {

	//const [deployer] = await ethers.getSigners();
	const [,deployer] = await ethers.getSigners();
	
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	var options = {
		//gasPrice: ethers.utils.parseUnits('50', 'gwei'), 
		gasLimit: 10e6
	};

	console.log("Account balance:", (await deployer.getBalance()).toString());

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
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });