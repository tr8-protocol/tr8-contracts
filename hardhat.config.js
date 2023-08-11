/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  settings: {
    optimizer: {
      enabled: true,
      runs: 800,
      details: {
        yul: false,
      },
    },
    viaIR : true,
  }
};
