
const tokenPO = "0x5568d243796FCb7E952995C7a4d8F4bdD23386A7";


require("dotenv").config({ path: ".env" });

const jsonfile = require("jsonfile");
const HDWalletProvider = require("@truffle/hdwallet-provider");

let provider = new HDWalletProvider(process.env.MNEMONIC, "https://matic-mumbai.chainstacklabs.com");
const Web3 = require("web3");
const web3 = new Web3(provider);

const TokenPO = jsonfile.readFileSync("build/contracts/TokenPO.json").abi;

async function run() {
  const account = await web3.eth.getAccounts();
  const contract = new web3.eth.Contract(TokenPO, tokenPO);
  try {
    var res = await contract.methods
    .swapFENToPO("10000000")
    .send({ from: account[0] });
  console.log(res);
  }catch(e){
      console.log(e)
  }
}
run();
