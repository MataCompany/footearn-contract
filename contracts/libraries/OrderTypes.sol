// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the Helixmeta exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(address signer,uint256 price,uint256 tokenId,address currency,uint256 nonce,uint256 startTime,uint256 endTime)")
    bytes32 internal constant MAKER_ORDER_HASH =
        0x906da0fda061010501a785073449f536fe014de5e9f0800d5b1766814115301f;

    struct MakerOrder {
        address signer; // signer of the maker order
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
    }

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.signer,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime
                )
            );
    }
}
