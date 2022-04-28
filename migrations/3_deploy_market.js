const TokenPO = artifacts.require("TokenPO");
const Footearn_NFT = artifacts.require("Footearn_NFT");
const Footearn_Marketplace = artifacts.require("FootEarn_Marketplace");

module.exports = async function (deployer) {
  await deployer.deploy(
    Footearn_Marketplace,
    process.env.PROTOCOL_RECEIVER,
    TokenPO.address,
    Footearn_NFT.address,
    process.env.PRE_PAID,
    process.env.PROTOCOL_FEE // *100 4,5% ->450
  );
};
