const market_addr = "0x1aE4bf8C55B914e38C6eD16017802e0EcfB9E924";

require("dotenv").config({ path: ".env" });
const ethUtil = require("ethereumjs-util");

const jsonfile = require("jsonfile");
const HDWalletProvider = require("@truffle/hdwallet-provider");

let provider = new HDWalletProvider(
  process.env.MNEMONIC,
  "https://matic-mumbai.chainstacklabs.com"
);
const Web3 = require("web3");
const web3 = new Web3(provider);

const FootEarnMarketPlace = jsonfile.readFileSync(
  "build/contracts/FootEarnMarketPlace.json"
).abi;

function hash_(makerOrder) {
  const encode =
    "0x906da0fda061010501a785073449f536fe014de5e9f0800d5b1766814115301f" +
    makerOrder.signer.toLowerCase().slice(2).padStart(64, "0") +
    BigInt(makerOrder.price.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.tokenId.toString()).toString(16).padStart(64, "0") +
    makerOrder.currency.toLowerCase().slice(2).padStart(64, "0") +
    BigInt(makerOrder.nonce.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.startTime.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.endTime.toString()).toString(16).padStart(64, "0");

  // console.log("encode: ", encode);
  const maker_order_hash = web3.utils.sha3(encode);
  // console.log("make_order_hash", maker_order_hash);
  const prefix_hash = web3.utils.sha3(
    "0x1901077b544ebd7de8469a529702cec2548881ae2c3f71f37210a8a01488e2e796d0" +
      maker_order_hash.slice(2)
  );
  // console.log("prefix_domain", prefix_domain);
  return prefix_hash.slice(2);
}
function sign_hash(inputHash, pkeyConfig) {
  var signature = { v: "", r: "", s: "" };
  // console.log(inputHash)
  const signature_getting = ethUtil.ecsign(
    Buffer.from(inputHash, "hex"),
    Buffer.from(pkeyConfig, "hex")
  );
  (signature.r = ethUtil.bufferToHex(signature_getting.r)),
    (signature.s = ethUtil.bufferToHex(signature_getting.s)),
    (signature.v = ethUtil.bufferToHex(signature_getting.v));
  // console.log(signature);
  return signature;
}

async function run() {
  const account = await web3.eth.getAccounts();
  const market = new web3.eth.Contract(FootEarnMarketPlace, market_addr);
  try {
    var makerAsk = {
      signer: "0xf3e75D0643CAD65B50F54EDa4253F7206692536e", // signer of the maker order
      price: "10000000000000000", // price (used as )
      tokenId: 36, // id of the token
      currency: "0xe91f5a8418d852779d9a0cfa2ea986c301ee90cf", // currency (e.g., WETH)
      nonce: 0, // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
      startTime: Math.floor(Date.now() / 1000) - 2000, // startTime in timestamp
      endTime: Math.floor(Date.now() / 1000) + 5000, // endTime in timestamp
      v: "", // v: parameter (27 or 28)
      r: "", // r: parameter
      s: "", // s: parameter
    };
    var TakerOrder = {
      taker: "0x1bb21FE614cA37A5FA13c2BAAb42465C2E574a46", // signer of the maker order
      price: "10000000000000000", // price (used as )
      tokenId: 36, // id of the token
    };

    const hash_data = hash_(makerAsk);
    const sign_data = sign_hash(
      hash_data,
      "c9167063efd34f761ac7acacaa41279cca82dd01f0abbdf69eb9cf2b544ba915"
    );
    makerAsk.v = sign_data.v;
    makerAsk.r = sign_data.r;
    makerAsk.s = sign_data.s;
    var res = await market.methods
      .matchAskWithTakerBid(TakerOrder, makerAsk)
      .send({ from: account[0] });
    console.log(res);
  } catch (e) {
    console.log(e);
  }
}
run();
