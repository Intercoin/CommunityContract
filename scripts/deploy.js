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
		gasLimit: 5e6
	};

	let params = [
		"0x29F393A1663e23b159bEd0dc1eE27B7Ded8D2400",
  		"0x1eCE0E8B5cD7eDEeD8DA1fC24Cd082A6Be8F2A77",
  		"0xEb5959A1D8E7e02aadF60B1a758B5607e4939C93",
		options
	]

	console.log("Account balance:", (await deployer.getBalance()).toString());

	const CommunityF = await ethers.getContractFactory("CommunityFactory");

	this.factory = await CommunityF.connect(deployer).deploy(...params);

	console.log("Factory deployed at:", this.factory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });