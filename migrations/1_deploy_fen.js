const FEN = artifacts.require("FEN");
const Footearn_Pack = artifacts.require("Footearn_Pack");
const Footearn_NFT = artifacts.require("Footearn_NFT");

const {
  deployProxy,
} = require("../node_modules/@openzeppelin/truffle-upgrades");

module.exports = async function (deployer) {
  await deployer.deploy(FEN, process.env.PRE_MINT);

  // await deployer.deploy(
  //   StarterPack,
  // process.env.STABLE_TOKEN,
  // FEN.address,
  // process.env.TOTAL_USER_PACK,
  // process.env.TOTAL_GUILD_PACK,
  // process.env.PRICE_PACK,
  // process.env.PRIVATE_SALE
  // );

  await deployProxy(
    Footearn_Pack,
    [
      process.env.STABLE_TOKEN,
      FEN.address,
      process.env.TOTAL_USER_PACK,
      process.env.TOTAL_GUILD_PACK,
      process.env.PRICE_PACK,
      process.env.PRIVATE_SALE,
      process.env.NUMBER_OF_NFT,
      process.env.VESTING_MONTHS,
      process.env.LOCK_MONTHS,
      process.env.TGE,
      process.env.MONTHLY_UNLOCK_RATE,
    ],
    {
      deployer,
      initializer: "initialize",
      unsafeAllow: ["delegatecall", "state-variable-immutable"],
    }
  );
  await deployer.deploy(Footearn_NFT, process.env.BASE_URI, Footearn_Pack.address);
};
