const TokenPO = artifacts.require("TokenPO");
const FEN = artifacts.require("FEN");

module.exports = async function (deployer) {
  await deployer.deploy(
    TokenPO,
    FEN.address,
    process.env.STABLE_TOKEN,
    process.env.WMATIC,
    process.env.UNISWAP_V2,
    process.env.PROTOCOL_RECEIVER,
    process.env.AMOUNT_PO
  );
};
