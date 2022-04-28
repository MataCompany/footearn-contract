// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Authorization} from "./libraries/Authorization.sol";
import "./Footearn_NFT.sol";
import "./FEN.sol";

contract Footearn_Pack is
    Initializable,
    AccessControlEnumerable,
    ReentrancyGuardUpgradeable
{
    // ONLY ALLOW BUSD
    uint256 public constant secondInDay = 86400;
    using SafeERC20 for ERC20;
    address public BUSD;
    address public FENToken;
    address public FactoryNFT;
    address public owner;

    // EVENT

    event BuyUserPack(uint256 id, address addressWallet);

    event BuyGuildPack(uint256 id, address addressWallet);

    event OpenBoxSuccess(
        uint256 boxIndex,
        uint256 fromTokenId,
        uint256 toTokenId,
        address addressWallet
    );
    event Harvest(address user, uint256 amount);

    event LogChangePack(uint256 _type, uint256 _amount);

    struct History {
        uint8 typePack; // 0 for userpack 1 for guildpack
        address owner;
        bool isOpen;
        uint256 fromId;
        uint256 toId;
    }

    struct HistoryPack {
        uint256 amount;
        uint256 startTime;
    }

    struct PoolFen {
        HistoryPack[] historyPack;
        uint256 receivedAmount;
    }

    mapping(address => PoolFen) public poolFen;
    uint256 public vestingDays;
    uint256 public lockDays;
    uint256 public tge;
    uint256 public mothlyUnlockRate;

    // STATE
    mapping(address => uint256) public poolUser;
    mapping(uint256 => History) public buyHistory;
    mapping(address => bool) public isUserGuild;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public pricePack;
    uint256 public numberOfNFTInOnePack;

    uint256 public totalUserPack;
    uint256 public totalUserPackSold;

    uint256 public totalGuildPack;
    uint256 public totalGuildPackSold;

    uint256 public packIndex;

    uint64 public userGuildIndex;
    address public authorizator;

    uint256 public privateSalePrice;

    uint256 public startDate;
    uint256 public endDate;

    bool public saleEnded;

    function initialize(
        address _BUSD,
        address _Fen,
        uint256 _totalUserPack,
        uint256 _totalGuildPack,
        uint256 _pricePack, // 100 busd
        uint256 _privateSale,
        uint256 amountNft,
        uint256 _vestingMonths,
        uint256 _lockMonths,
        uint256 _tge,
        uint256 _mothlyUnlockRate
    ) public payable initializer {
        BUSD = _BUSD;
        FENToken = _Fen;

        totalUserPack = _totalUserPack;
        totalGuildPack = _totalGuildPack;

        pricePack = _pricePack * 10**uint256(18); // ** uint256(18) when deploy
        privateSalePrice = _privateSale; // ** uint256(18) when deploy
        owner = msg.sender;
        authorizator = msg.sender;

        totalUserPackSold = 0;
        totalGuildPackSold = 0;
        packIndex = 0;
        userGuildIndex = 0;
        startDate = 1641644620;
        endDate = 1791644620;

        vestingDays = _vestingMonths * 30;
        lockDays = _lockMonths * 30;
        tge = _tge;
        mothlyUnlockRate = _mothlyUnlockRate;

        numberOfNFTInOnePack = amountNft;

        __ReentrancyGuard_init();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");

        _;
    }

    function setFactoryNFT(address factory) public onlyOwner {
        FactoryNFT = factory;
    }

    function unsoldUserPack() public view returns (uint256) {
        return uint256(totalUserPack - totalUserPackSold);
    }

    function unsoldGuildPack() public view returns (uint256) {
        return uint256(totalGuildPack - totalGuildPackSold);
    }

    modifier checkSaleRequirements() {
        require(
            block.timestamp >= startDate && block.timestamp < endDate,
            "Sale time passed"
        );
        require(saleEnded == false, "Sale time passed");
        require(unsoldUserPack() > 0, "Insufficient buy amount");
        _;
    }

    modifier checkSalePremiumRequirements() {
        require(
            block.timestamp >= startDate && block.timestamp < endDate,
            "Sale time passed"
        );
        require(saleEnded == false, "Sale time passed");
        require(unsoldGuildPack() > 0, "Insufficient buy amount");
        _;
    }

    modifier checkClaimRequirements(uint256 totalClaim, address addressClaim) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Box Claim: must have minter role to claim"
        );
        require(
            ERC20(BUSD).balanceOf(address(this)) >= totalClaim,
            "Box Payment: Invalid balanceOf"
        );
        require(
            poolUser[addressClaim] >= totalClaim,
            "Box Payment: Invalid balanceOf"
        );
        _;
    }

    modifier checkOpenBox(uint256 index) {
        require(
            buyHistory[index].owner == _msgSender(),
            "Box Open : must have owner role to open"
        );

        require(
            buyHistory[index].isOpen == false,
            "Box Open : have been opened before"
        );
        require(
            Footearn_NFT(FactoryNFT).hasRole(MINTER_ROLE, address(this)) ==
                true,
            "Box Open : is error of Box Contract"
        );
        _;
    }

    function claimPool(uint256 totalClaim, address addressClaim)
        public
        checkClaimRequirements(totalClaim, addressClaim)
        nonReentrant
        returns (uint256)
    {
        poolUser[addressClaim] -= totalClaim;
        ERC20(BUSD).transferFrom(address(this), addressClaim, totalClaim);
        return poolUser[addressClaim];
    }

    function userPack() public checkSaleRequirements {
        // uint256 newItemId = _tokenIds.current();
        // require(!_exists(newItemId), "Box Payment: must have unique tokenId");
        ERC20(BUSD).transferFrom(_msgSender(), address(this), pricePack);
        buyHistory[packIndex] = History(0, _msgSender(), false, 0, 0);
        packIndex++;
        totalUserPackSold++;
        poolUser[_msgSender()] += (pricePack * 60) / 100;
        emit BuyUserPack(packIndex - 1, _msgSender());
    }

    function guildPack() public virtual checkSalePremiumRequirements {
        require(isUserGuild[msg.sender], "no permission");
        ERC20(BUSD).transferFrom(_msgSender(), address(this), pricePack);
        buyHistory[packIndex] = History(1, _msgSender(), false, 0, 0);
        packIndex++;
        totalGuildPackSold++;
        poolUser[_msgSender()] += (pricePack * 60) / 100;

        poolFen[msg.sender].historyPack.push(
            HistoryPack(
                (((pricePack * 40) / 100) * 10**ERC20(BUSD).decimals()) /
                    privateSalePrice,
                block.timestamp
            )
        );

        emit BuyGuildPack(packIndex - 1, _msgSender());
    }

    function _innerMint(address to, uint256 amount) private {
        FEN(FENToken).mint(to, amount);
    }

    function openBox(uint256 boxIndex) public checkOpenBox(boxIndex) {
        uint256 from;
        uint256 to;
        for (uint256 i = 0; i < numberOfNFTInOnePack; i++) {
            if (i == 0) from = Footearn_NFT(FactoryNFT).mint(_msgSender());
            else if (i == numberOfNFTInOnePack - 1)
                to = Footearn_NFT(FactoryNFT).mint(_msgSender());
            else Footearn_NFT(FactoryNFT).mint(_msgSender());
        }
        buyHistory[boxIndex].isOpen = true;
        buyHistory[boxIndex].fromId = from;
        buyHistory[boxIndex].toId = to;
        emit OpenBoxSuccess(
            boxIndex,
            buyHistory[boxIndex].fromId,
            buyHistory[boxIndex].toId,
            _msgSender()
        );
    }

    function registryGuildUser(bytes memory sig) public {
        require(isUserGuild[msg.sender] == false, "user already in guild list");
        (uint8 sigV, bytes32 sigR, bytes32 sigS) = _sigToVRS(sig);
        require(
            Authorization.registryGuildUser(
                authorizator,
                msg.sender,
                userGuildIndex,
                sigV,
                sigR,
                sigS
            ),
            "wrong signature"
        );
        isUserGuild[msg.sender] = true;
        userGuildIndex++;
    }

    function _sigToVRS(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        return (v, r, s);
    }

    function changeAuthorizator(address _user) public onlyOwner {
        authorizator = _user;
    }

    function harvest() public {
        uint256 reward = viewRewardForUser(block.timestamp, msg.sender);
        _innerMint(msg.sender, reward);
        poolFen[msg.sender].receivedAmount += reward;
        emit Harvest(msg.sender, reward);
    }

    function getPoolFen(address user) public view returns (PoolFen memory) {
        return poolFen[user];
    }

    function viewRewardForUser(uint256 toTimeStamp, address user)
        public
        view
        returns (uint256)
    {
        uint256 totalReward;

        for (uint256 i = 0; i < poolFen[user].historyPack.length; i++) {
            if (
                toTimeStamp >
                poolFen[user].historyPack[i].startTime + lockDays * secondInDay
            ) {
                uint256 totalMonthPassed = (toTimeStamp -
                    poolFen[user].historyPack[i].startTime -
                    lockDays *
                    secondInDay) / (secondInDay * 30);
                totalMonthPassed = totalMonthPassed > (vestingDays) / 30
                    ? (vestingDays) / 30
                    : totalMonthPassed;
                totalReward += ((poolFen[user].historyPack[i].amount *
                    (mothlyUnlockRate * totalMonthPassed + tge)) / 10000);
            } else if (toTimeStamp > poolFen[user].historyPack[i].startTime) {
                totalReward +=
                    (poolFen[user].historyPack[i].amount * tge) /
                    10000;
            }
        }

        return (totalReward - poolFen[user].receivedAmount);
    }

    function changeTotalPack(uint8 _type, uint256 _amount) public onlyOwner {
        require(_type == 0 || _type == 1, "must be user pack or guild pack");
        if (_type == 0) {
            require(
                _amount > totalUserPackSold,
                "amount less than sold amount"
            );
            totalUserPack = _amount;
        } else {
            require(
                _amount > totalGuildPackSold,
                "amount less than sold amount"
            );
            totalGuildPack = _amount;
        }
        emit LogChangePack(_type, _amount);
    }
}
