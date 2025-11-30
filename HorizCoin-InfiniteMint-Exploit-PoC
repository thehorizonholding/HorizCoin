require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["YOUR_PRIVATE_KEY_HERE"],
      chainId: 80001
    },
    sepolia: {
      url: "https://rpc.sepolia.org",
      accounts: ["YOUR_PRIVATE_KEY_HERE"],
      chainId: 11155111
    }
  }
};
