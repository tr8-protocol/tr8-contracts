/** @type import('hardhat/config').HardhatUserConfig */
const dot = require('dotenv').config();

require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-chai-matchers");
const { OPTISCAN_API_KEY, API_URL_OPTIGOERLI, API_URL_BASEGOERLI, API_URL_ZORAGOERLI, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.21',
        settings: {
          evmVersion: 'paris'
        }
      }
    ]
  },
  settings: {
    viaIR: true,
    optimizer: {
      enabled: true,
      runs: 200,
      details: {
        yulDetails: {
          optimizerSteps: "u",
        },
      },
    },
  },
  defaultNetwork: "baseGoerli",
  networks: {
    hardhat: {
      accounts: [{ privateKey: `0x${PRIVATE_KEY}`, balance: "10000000000000000000000"}],
      forking: {
        url: API_URL_OPTIGOERLI,
        blockNumber: 8717392
      },
      loggingEnabled: true,
      gasMultiplier: 10,
      gasPrice: 1000000000 * 500,
      blockGasLimit: 0x1fffffffffffff
    },
    optimisticGoerli: {
      url: API_URL_OPTIGOERLI,
      accounts: [`0x${PRIVATE_KEY}`],
      gasMultiplier: 10,
      gasPrice: 1000000000 * 1,
      blockGasLimit: 0x1fffffffffffff
    },
    baseGoerli: {
      url: API_URL_BASEGOERLI,
      accounts: [`0x${PRIVATE_KEY}`],
      gasPrice: 1000000000 * 10,
    },
    zoraGoerli: {
      url: API_URL_ZORAGOERLI,
      accounts: [`0x${PRIVATE_KEY}`],
      gasMultiplier: 10,
      gasPrice: 1000000000 * 1,
      blockGasLimit: 0x1fffffffffffff
    }
  },
   etherscan: {
    apiKey: {
      optimisticGoerli: OPTISCAN_API_KEY,
      baseGoerli: "PLACEHOLDER_STRING",
      zoraGoerli: "PLACEHOLDER_STRING"
    },
    customChains: [
      {
        network: "baseGoerli",
        chainId: 84531,
        urls: {
         apiURL: "https://api-goerli.basescan.org/api",
         browserURL: "https://goerli.basescan.org"
        }
      },
      {
        network: "zoraGoerli",
        chainId: 999,
        urls: {
          apiURL: "https://testnet.explorer.zora.energy/api",
          browserURL: "https://testnet.explorer.zora.energy"
        }
      }
    ]
  }
};
