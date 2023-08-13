const chain = hre.network.name;
console.log("chain: ", chain);

const DEPLOYER_ADDR = process.env.DEPLOYER_ADDR;

const dropSchemaString = `(string,string,string,string,string) metadata, address hook , address[] claimers, address[] admins, string secret, (string,string)[] attributes, string[] tags, bool allowTransfers`;

var addr = {};
if (chain == "optimisticGoerli") {
  addr.lzEndpoint = "0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1";
  addr.chainId = 10132;
  addr.eas = "0x4200000000000000000000000000000000000021";
}
if (chain == "baseGoerli") {
  addr.lzEndpoint = "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab";
  addr.chainId = 10160;
  addr.eas = "0xAcfE09Fd03f7812F022FBf636700AdEA18Fd2A7A"
}
if (chain == "zoraGoerli") {
    addr.lzEndpoint = "";
    addr.chainId = 999; // evm chainId, as Zora not supported on LayerZero
    addr.eas = "0x29C691bb067Ab73B2280062AF4401ED36E860CD4";
}

async function main() {
    const accounts = await ethers.getSigners();
    const signer = accounts[0];
    var transporterAddress = await signer.getAddress();  // default to signer address
    //console.log("transporterAddress: ", transporterAddress);

    // tr8
    const TR8 = await ethers.getContractFactory("TR8");
    const tr8 = await TR8.deploy(); // Instance of the contract 
    await tr8.deployed();
    console.log("TR8 deployed to address:", tr8.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8.address}`);

    // nft implementation
    const TR8Nft = await ethers.getContractFactory("TR8Nft");
    const tr8Nft = await TR8Nft.deploy(); // Instance of the contract 
    await tr8Nft.deployed();
    console.log("NFT implementation deployed to address:", tr8Nft.address);
    console.log(`npx hardhat verify --network ${chain} ${tr8Nft.address}`);

    if (chain != "zoraGoerli") {
        // transporter
        const TR8Transporter = await ethers.getContractFactory("TR8Transporter");
        const tr8Transporter = await TR8Transporter.deploy(); // Instance of the contract 
        await tr8Transporter.deployed();
        transporterAddress = tr8Transporter.address;
        console.log("Transporter deployed to address:", tr8Transporter.address);
        console.log(`npx hardhat verify --network ${chain} ${tr8Transporter.address}`);

        // initialize transporter
        await (await tr8Transporter.initialize(tr8.address, addr.lzEndpoint, [10132, 10160])).wait();
    }

    // initialize tr8
    await (await tr8.initialize(addr.eas, tr8Nft.address, transporterAddress)).wait();

 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });