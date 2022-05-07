const private_sale = "0xCb8efc179029d5ad381034A252B616210472f3dd";

const data = [
  {
    saleType: 0,
    totalToken: "50000000000000000000000000",
    tge: 1000,
    lockDays: 60,
    vestingDays: 720,
    monthlyUnlockRate: 375,
    distributedAmount: 0,
  },
  {
    saleType: 1,
    totalToken: "105000000000000000000000000",
    tge: 1000,
    lockDays: 60,
    vestingDays: 540,
    monthlyUnlockRate: 500,
    distributedAmount: 0,
  },
];

require("dotenv").config({ path: ".env" });

const jsonfile = require("jsonfile");
const HDWalletProvider = require("@truffle/hdwallet-provider");

let provider = new HDWalletProvider(
  process.env.MNEMONIC,
  "https://matic-mumbai.chainstacklabs.com"
);
const Web3 = require("web3");
const web3 = new Web3(provider);

const StrategySale = jsonfile.readFileSync(
  "build/contracts/StrategySale.json"
).abi;

async function run() {
  const account = await web3.eth.getAccounts();
  const contract = new web3.eth.Contract(StrategySale, private_sale);
  try {
    var res = await contract.methods
      .whitelistSaleInfo(data)
      .send({ from: account[0] });
    console.log(res);
  } catch (e) {
    console.log(e);
  }
}
run();
