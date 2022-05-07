const private_sale = "0xCb8efc179029d5ad381034A252B616210472f3dd";

const users = [
  "0xF5BD6484AD0CaFD0cF42409d30094fBC3EB1F3e6",
  "0x256628a73776058Da1673dFC0315039e40DD30Eb",
  "0x1bb21FE614cA37A5FA13c2BAAb42465C2E574a46",
  "0xf3e75D0643CAD65B50F54EDa4253F7206692536e",
  "0x9b8e671580649BaD470f63064EE9505632948f4D",
];
const data = [
  {
    saleType: 0,
    amount: "500000000000",
    startTime: 0,
    receivedAmount: 0,
  },
  {
    saleType: 0,
    amount: "500000000000000000",
    startTime: 165189505,
    receivedAmount: 0,
  },
  {
    saleType: 0,
    amount: "500000000000000000",
    startTime: 1634614957,
    receivedAmount: 0,
  },
  {
    saleType: 0,
    amount: "500000000000000000",
    startTime: 1608694957,
    receivedAmount: 0,
  },
  {
    saleType: 0,
    amount: "1000000000000000000",
    startTime: 1608694957,
    receivedAmount: 0,
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
      .whitelistUsers(data, users, 0)
      .send({ from: account[0] });
    console.log(res);
  } catch (e) {
    console.log(e);
  }
}
run();
