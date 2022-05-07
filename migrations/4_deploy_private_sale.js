const StrategySale = artifacts.require("StrategySale");
const FEN = artifacts.require("FEN");

module.exports = async function (deployer) {
  await deployer.deploy(
    StrategySale,
    FEN.address,
    process.env.DISTRIBUTED_TOKEN_FOR_STRATEGY_SALE
  );
};
