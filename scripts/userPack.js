const start_pack_addr = "0x619eC4525B13586fD95Efc0989010E73163eae0A";


require("dotenv").config({ path: ".env" });

const jsonfile = require("jsonfile");
const HDWalletProvider = require("@truffle/hdwallet-provider");

let provider = new HDWalletProvider(process.env.MNEMONIC, "https://matic-mumbai.chainstacklabs.com");
const Web3 = require("web3");
const web3 = new Web3(provider);

const StarterPack = jsonfile.readFileSync("build/contracts/StarterPack.json").abi;

async function run() {
  const account = await web3.eth.getAccounts();
  const start_pack = new web3.eth.Contract(StarterPack, start_pack_addr);
  try {
    var res = await start_pack.methods
    .openBox2(0)
    .send({ from: account[0] });
  console.log(res);
  }catch(e){
      console.log(e)
  }
}
run();
