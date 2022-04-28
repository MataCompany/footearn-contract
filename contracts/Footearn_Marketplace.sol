// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Footearn_NFT} from "./Footearn_NFT.sol";

contract Footearn_Marketplace is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public immutable PO_ADDRESS;
    address public FACTORY_NFT;

    address public protocolFeeRecipient;
    uint256 public itemIds = 0;

    uint256 public min_amount_token;

    // 1% -> 100
    uint256 public pre_paid_percent;
    uint256 public paid_percent;

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 pre_paid_fee;
        bool isSelling;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;

    event CancelOrder(address user, uint256 itemId, uint256 tokenId);

    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);

    event NewPrePaidPercent(uint256 pre_paid_percent);

    event NewPaidPercent(uint256 paid_percent);

    event BuyNFT(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address newOwner,
        uint256 price,
        uint256 fee,
        bool sold
    );

    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        bool sold
    );

    /**
     * @notice Constructor
     * @param _protocolFeeRecipient protocol fee recipient
     */
    constructor(
        address _protocolFeeRecipient,
        address _PO_addr,
        address factory_nft,
        uint256 _pre_paid_percent,
        uint256 _paid_percent
    ) {
        require(
            _pre_paid_percent <= _paid_percent,
            "prepaid must be less than or equal paid "
        );
        // Calculate the domain separator
        PO_ADDRESS = _PO_addr;
        FACTORY_NFT = factory_nft;
        protocolFeeRecipient = _protocolFeeRecipient;
        pre_paid_percent = _pre_paid_percent;
        paid_percent = _paid_percent;

        // min_amount_token = 10**IERC20(_PO_addr).decimals();
    }

    /**
     * @dev Set NFT Factory
     */
    function updateFactory(address _Factory) public onlyOwner {
        FACTORY_NFT = _Factory;
    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param tokenId taker bid order
     * @param priceItem maker ask order
     * @param priceItem maker ask order
     */
    function createSale(uint256 tokenId, uint256 priceItem)
        public
        nonReentrant
    {
        uint256 pre_paid_fee = (priceItem * pre_paid_percent) / 10000;

        idToMarketItem[tokenId] = MarketItem(
            itemIds,
            tokenId,
            msg.sender,
            priceItem,
            pre_paid_fee,
            true
        );

        Footearn_NFT(FACTORY_NFT).transferFrom(msg.sender, address(this), tokenId);

        IERC20(PO_ADDRESS).safeTransferFrom(
            msg.sender,
            protocolFeeRecipient,
            pre_paid_fee
        );

        emit MarketItemCreated(itemIds, tokenId, msg.sender, priceItem, true);
        itemIds++;
    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param tokenId tokenId
     */
    function buyNFT(uint256 tokenId) public nonReentrant {
        require(
            idToMarketItem[tokenId].isSelling == true,
            "Buy NFT : Unavailable"
        );

        uint256 fee = (idToMarketItem[tokenId].price * paid_percent) / 10000;

        IERC20(PO_ADDRESS).safeTransferFrom(
            msg.sender,
            idToMarketItem[tokenId].seller,
            idToMarketItem[tokenId].price -
                fee +
                idToMarketItem[tokenId].pre_paid_fee
        );

        IERC20(PO_ADDRESS).safeTransferFrom(
            msg.sender,
            protocolFeeRecipient,
            fee - idToMarketItem[tokenId].pre_paid_fee
        );

        Footearn_NFT(FACTORY_NFT).transferFrom(address(this), msg.sender, tokenId);

        emit BuyNFT(
            idToMarketItem[tokenId].itemId,
            tokenId,
            idToMarketItem[tokenId].seller,
            msg.sender,
            idToMarketItem[tokenId].price,
            fee,
            true
        );

        delete idToMarketItem[tokenId];
    }

    /**
     * @notice Match a takerBid with a matchAsk
     * @param tokenId tokenId
     */
    function cancelSell(uint256 tokenId) public nonReentrant {
        require(
            msg.sender == idToMarketItem[tokenId].seller,
            "Buy NFT : Is not Seller"
        );
        require(
            idToMarketItem[tokenId].isSelling == true,
            "Buy NFT : Unavailable"
        );
        Footearn_NFT(FACTORY_NFT).transferFrom(address(this), msg.sender, tokenId);

        emit CancelOrder(msg.sender, idToMarketItem[tokenId].itemId, tokenId);
        delete idToMarketItem[tokenId];
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _protocolFeeRecipient new recipient for protocol fees
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _pre_paid_percent new recipient for protocol fees
     */
    function updatePrePaidPercent(uint256 _pre_paid_percent)
        external
        onlyOwner
    {
        require(
            _pre_paid_percent <= paid_percent,
            "prepaid must be less than or equal paid "
        );
        pre_paid_percent = _pre_paid_percent;

        emit NewPrePaidPercent(_pre_paid_percent);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param _paid_percent new recipient for protocol fees
     */
    function updatePaidPercent(uint256 _paid_percent) external onlyOwner {
        require(
            pre_paid_percent <= _paid_percent,
            "prepaid must be less than or equal paid "
        );
        paid_percent = _paid_percent;

        emit NewPrePaidPercent(paid_percent);
    }
}
