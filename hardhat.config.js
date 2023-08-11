/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.21",
  settings: {
    viaIR: true,
    optimizer: {
      enabled: true,
      runs: 1,
      details: {
        yulDetails: {
          optimizerSteps: "u",
        },
      },
    },
  },
};
