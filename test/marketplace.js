const { expectRevert, expectEvent, BN } = require("@openzeppelin/test-helpers");
const ethUtil = require("ethereumjs-util");

const FootEarnMarketPlace = artifacts.require("FootEarnMarketPlace");
const FootEarn = artifacts.require("FootEarn");
const FEN = artifacts.require("FEN");

const MAKER_ORDER_HASH =
  "0x906da0fda061010501a785073449f536fe014de5e9f0800d5b1766814115301f";

const prefix = "0x1901";
function hash_(DOMAIN_SEPARATOR, makerOrder) {
  const encode =
    MAKER_ORDER_HASH +
    makerOrder.signer.toLowerCase().slice(2).padStart(64, "0") +
    BigInt(makerOrder.price.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.tokenId.toString()).toString(16).padStart(64, "0") +
    makerOrder.currency.toLowerCase().slice(2).padStart(64, "0") +
    BigInt(makerOrder.nonce.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.startTime.toString()).toString(16).padStart(64, "0") +
    BigInt(makerOrder.endTime.toString()).toString(16).padStart(64, "0");

  // console.log("encode: ", encode);
  const maker_order_hash = web3.utils.sha3(encode);

  const prefix_hash = web3.utils.sha3(
    prefix + DOMAIN_SEPARATOR.slice(2) + maker_order_hash.slice(2)
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

contract("Market", (accounts) => {
  let market;
  let nft;
  let token;

  let DOMAIN_SEPARATOR;

  const minter = accounts[0];
  const protocol_add = accounts[2];
  const protocol_fee = process.env.PROTOCOL_FEE;
  const tokenId = new BN(1);
  let listingId = new BN(1);
  const price = new BN(1000);

  describe("matched", () => {
    before(async () => {
      nft = await FootEarn.new("FootEarn.com", minter);
      token = await FEN.new();
      market = await FootEarnMarketPlace.new(
        protocol_add,
        token.address,
        nft.address,
        protocol_fee
      );

      //mint nft for acc1
      await nft.mint(accounts[1], tokenId, { from: minter });
      // mint fen for acc3
      await token.setMintFactory(accounts[0], { from: minter });
      await token.mint(accounts[5], "10000000000000000", { from: minter });
      DOMAIN_SEPARATOR = await market.DOMAIN_SEPARATOR();
    });

    it("should prevent listing - erc20 not approved", async () => {
      var makerAsk = {
        signer: accounts[1], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
        currency: token.address, // currency (e.g., WETH)
        nonce: 0, // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        startTime: Math.floor(Date.now() / 1000) - 2000, // startTime in timestamp
        endTime: Math.floor(Date.now() / 1000) + 5000, // endTime in timestamp
        v: "", // v: parameter (27 or 28)
        r: "", // r: parameter
        s: "", // s: parameter
      };
      var takerBid = {
        taker: accounts[5], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
      };

      const hash_data = hash_(DOMAIN_SEPARATOR, makerAsk);
      const sign_data = sign_hash(
        hash_data,
        "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
      );

      makerAsk.v = sign_data.v;
      makerAsk.r = sign_data.r;
      makerAsk.s = sign_data.s;

      return expectRevert(
        market.matchAskWithTakerBid(takerBid, makerAsk, {
          from: accounts[5],
        }),
        "ERC20: transfer amount exceeds allowance"
      );
    });

    it("should prevent listing - erc721 not approved", async () => {
      var makerAsk = {
        signer: accounts[1], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
        currency: token.address, // currency (e.g., WETH)
        nonce: 0, // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        startTime: Math.floor(Date.now() / 1000) - 2000, // startTime in timestamp
        endTime: Math.floor(Date.now() / 1000) + 5000, // endTime in timestamp
        v: "", // v: parameter (27 or 28)
        r: "", // r: parameter
        s: "", // s: parameter
      };
      var takerBid = {
        taker: accounts[5], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
      };

      const hash_data = hash_(DOMAIN_SEPARATOR, makerAsk);
      const sign_data = sign_hash(
        hash_data,
        "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
      );

      makerAsk.v = sign_data.v;
      makerAsk.r = sign_data.r;
      makerAsk.s = sign_data.s;

      //approve erc20
      await token.approve(market.address, "100000000000000000000000000000000", {
        from: accounts[5],
      });

      return expectRevert(
        market.matchAskWithTakerBid(takerBid, makerAsk, {
          from: accounts[5],
        }),
        "ERC721: transfer caller is not owner nor approved"
      );
    });

    it("should execute listing", async () => {
      var makerAsk = {
        signer: accounts[1], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
        currency: token.address, // currency (e.g., WETH)
        nonce: 0, // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        startTime: Math.floor(Date.now() / 1000) - 2000, // startTime in timestamp
        endTime: Math.floor(Date.now() / 1000) + 5000, // endTime in timestamp
        v: "", // v: parameter (27 or 28)
        r: "", // r: parameter
        s: "", // s: parameter
      };
      var takerBid = {
        taker: accounts[5], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
      };

      const hash_data = hash_(DOMAIN_SEPARATOR, makerAsk);
      const sign_data = sign_hash(
        hash_data,
        "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
      );

      makerAsk.v = sign_data.v;
      makerAsk.r = sign_data.r;
      makerAsk.s = sign_data.s;

      //approve erc20
      await token.approve(market.address, "100000000000000000000000000000000", {
        from: accounts[5],
      });
      //approve erc721
      await nft.setApprovalForAll(market.address, true, {
        from: accounts[1],
      });

      const tx = await market.matchAskWithTakerBid(takerBid, makerAsk, {
        from: accounts[5],
      });
      expectEvent(tx, "TakerBid", {
        orderNonce: new BN(0),
        taker: accounts[5],
        maker: accounts[1],
        tokenId: new BN(1),
        price: new BN("10000000000000000"),
      });

      //check data
      assert.equal(await nft.ownerOf(1), accounts[5], "Owner not acc5");

      console.log((await token.balanceOf(accounts[2])).toString());
      assert.equal(
        (await token.balanceOf(accounts[1])).toString(),
        "9550000000000000",
        "the seller balance not correct"
      );

      assert.equal(
        (await token.balanceOf(accounts[2])).toString(),
        "450000000000000",
        "protocol fee"
      );

      assert.equal(
        (await token.balanceOf(accounts[5])).toString(),
        "0",
        "the buyer balance not correct"
      );
    });
  });

  describe("cancel listing", () => {
    before(async () => {
      nft = await FootEarn.new("FootEarn.com", minter);
      token = await FEN.new();
      market = await FootEarnMarketPlace.new(
        protocol_add,
        token.address,
        nft.address,
        protocol_fee
      );

      //mint nft for acc1
      await nft.mint(accounts[1], tokenId, { from: minter });
      // mint fen for acc3
      await token.setMintFactory(accounts[0], { from: minter });
      await token.mint(accounts[5], "10000000000000000", { from: minter });
      DOMAIN_SEPARATOR = await market.DOMAIN_SEPARATOR();
    });

    it("should prevent listing - cancel nonce", async () => {
      var makerAsk = {
        signer: accounts[1], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
        currency: token.address, // currency (e.g., WETH)
        nonce: 0, // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        startTime: Math.floor(Date.now() / 1000) - 2000, // startTime in timestamp
        endTime: Math.floor(Date.now() / 1000) + 5000, // endTime in timestamp
        v: "", // v: parameter (27 or 28)
        r: "", // r: parameter
        s: "", // s: parameter
      };
      var takerBid = {
        taker: accounts[5], // signer of the maker order
        price: "10000000000000000", // price (used as )
        tokenId: "1", // id of the token
      };

      const hash_data = hash_(DOMAIN_SEPARATOR, makerAsk);
      const sign_data = sign_hash(
        hash_data,
        "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
      );

      makerAsk.v = sign_data.v;
      makerAsk.r = sign_data.r;
      makerAsk.s = sign_data.s;

      //approve erc20
      await token.approve(market.address, "100000000000000000000000000000000", {
        from: accounts[5],
      });
      //approve erc721
      await nft.setApprovalForAll(market.address, true, {
        from: accounts[1],
      });
      // cancel listing buy acc1
      await market.cancelMultipleMakerOrders([0], { from: accounts[1] });

      return expectRevert(
        market.matchAskWithTakerBid(takerBid, makerAsk, {
          from: accounts[5],
        }),
        "Order: Matching order expired"
      );
    });
  });
});
