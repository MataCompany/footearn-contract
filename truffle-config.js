require("dotenv").config({ path: ".env" });
const HDWalletProvider = require("@truffle/hdwallet-provider");

var privateKeys = process.env.MNEMONIC.split(" ");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8546,
      network_id: "*",
    },
    mumbai: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://matic-mumbai.chainstacklabs.com`
        ),

      network_id: 80001,
      confirmations: 2,
      networkCheckTimeout: 1000000,
      timeoutBlocks: 500,
      skipDryRun: true,
    },
  },

  compilers: {
    solc: {
      version: "0.8.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },

  plugins: ["truffle-plugin-verify", "truffle-contract-size"],

  api_keys: {
    polygonscan: process.env.POLYGONSCAN_API_KEY,
  },
};
