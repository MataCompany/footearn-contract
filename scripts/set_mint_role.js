const fen = "0xF9b5E56a7ac086fB96d5a56F99a0725F883DCc41";
const footearn_pack = "0x3986a585F579795e2F91D556C92f956C508613d8";
const nft_factory = "0xAc3D0106199e02f404805851bF2CE1176b8225d8"

require("dotenv").config({ path: ".env" });

const jsonfile = require("jsonfile");
const HDWalletProvider = require("@truffle/hdwallet-provider");

let provider = new HDWalletProvider(process.env.MNEMONIC, process.env.PROVIDER);
const Web3 = require("web3");
const web3 = new Web3(provider);

const FEN = jsonfile.readFileSync("build/contracts/FEN.json").abi;
const Footearn_Pack = jsonfile.readFileSync("build/contracts/Footearn_Pack.json").abi;

async function run() {
  const account = await web3.eth.getAccounts();
  const fen_contract = new web3.eth.Contract(FEN, fen);
  const pack_contract = new web3.eth.Contract(Footearn_Pack, footearn_pack);
  try {
    var res = await fen_contract.methods
      .setMintFactory(footearn_pack)
      .send({ from: account[0] });
    console.log(res);
    res = await pack_contract.methods
      .setFactoryNFT(nft_factory)
      .send({ from: account[0] });
    console.log(res);
  } catch (e) {
    console.log(e);
  }
}
run();
