const chain = hre.network.name;

var addr = {};
if (chain == "optimisticGoerli") {
  addr.AIrtist = "0x6a531B4447fB07b10A39E99Fc25b9c2cA63eAA42";  // AIrtist NFT contract
}

async function main() {
    // TR8HookFaucet
    const TR8HookFaucet = await ethers.getContractFactory("TR8HookFaucet");
    const tr8HookFaucet = await TR8HookFaucet.deploy(); // Instance of the contract 
    console.log("TR8HookFaucet deployed to address:", tr8HookFaucet.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8HookFaucet.address}`);

    // TR8HookNeedEth
    const TR8HookNeedEth = await ethers.getContractFactory("TR8HookNeedEth");
    const tr8HookNeedEth = await TR8HookNeedEth.deploy(); // Instance of the contract 
    console.log("TR8HookNeedEth deployed to address:", tr8HookNeedEth.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8HookNeedEth.address}`);

    // TR8HookNFTClaimer
    const TR8HookNFTClaimer = await ethers.getContractFactory("TR8HookNFTClaimer");
    const tr8HookNFTClaimer = await TR8HookNFTClaimer.deploy(addr.AIrtist); // Instance of the contract 
    console.log("TR8HookNFTClaimer deployed to address:", tr8HookNFTClaimer.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8HookNFTClaimer.address}`);

    // TR8HookNeedEth
    const TR8HookStreamer = await ethers.getContractFactory("TR8HookStreamer");
    const tr8HookStreamer = await TR8HookStreamer.deploy(); // Instance of the contract 
    console.log("TR8HookStreamer deployed to address:", tr8HookStreamer.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8HookStreamer.address}`);

 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });