// require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("@typechain/hardhat");
require("@xyrusworx/hardhat-solidity-json");

const { PRIVATE_KEY, MONAD_API_KEY } = require("./env.js");

/**
 * @type {import("hardhat/types").HardhatUserConfig}
 */
const config = {
  // latest Solidity version
  solidity: {
    compilers: [
      {
        version: "0.8.21",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.7.0",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },

  networks: {
    bsc: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: [PRIVATE_KEY]
    },

    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [PRIVATE_KEY]
    },

    op: {
      url: "https://mainnet.optimism.io",
      chainId: 10,
      accounts: [PRIVATE_KEY]
    },

    monadDevnet: {
      url: "https://devnet1.monad.xyz/rpc/8XQAiNSsPCrIdVttyeFLC6StgvRNTdf",
      chainId: 41454,
      accounts: [PRIVATE_KEY]
    },

    hardhat: {
      forking: {
        url: "https://bsc-dataseed1.binance.org",
        chainId: 56
      }
      //accounts: []
    }
  },
  typechain: {
    outDir: "./artifacts/types",
    target: "ethers-v6"
  },
  // etherscan: {
  //   // Your API key for Etherscan
  //   // Obtain one at https://etherscan.io/
  //   apiKey: APIKEY
  // },

  mocha: {
    timeout: 100000000
  }
};

/**
 * {@import("hardhat/config").HardhatUserConfig}
 */
module.exports = config;
