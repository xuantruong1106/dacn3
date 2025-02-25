require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      gas: 12000000,  // Giới hạn gas
      blockGasLimit: 12000000,  // Giới hạn gas của block
    },
  }
};
