require("@openzeppelin/hardhat-upgrades");
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
      url: "https://rpc-devnet.monadinfra.com/rpc/3fe540e310bbb6ef0b9f16cd23073b0a",
      chainId: 20143,
      accounts: [PRIVATE_KEY],
      gasPrice: "auto",
      gas: "auto",
      gasMultiplier: 1
    },

    monadTestnet: {
      url: "https://rpc.monad-testnet.category.xyz/rpc/k1e4ki8vesb3xik9kh9vflrtne7wzfl0egbezayc",
      chainId: 10143,
      accounts: [PRIVATE_KEY],
      gasPrice: "auto",
      gas: "auto",
      gasMultiplier: 1
    },

    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      chainId: 11124,
      accounts: [PRIVATE_KEY]
    },

    beraBartio: {
      url: "https://bera-testnet.nodeinfra.com",
      chainId: 80084,
      accounts: [PRIVATE_KEY],
      gasPrice: "auto",
      gas: "auto",
      gasMultiplier: 1
    },

    sepolia: {
      url: "https://sepolia.gateway.tenderly.co",
      chainId: 11155111,
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
    target: "ethers-v5"
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
