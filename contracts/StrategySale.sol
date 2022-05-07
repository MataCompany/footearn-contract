// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./FEN.sol";

/**
 * @title StrategySale
 * @notice It handles the private sale for tokens (against stable token) and the fee-sharing
 * mechanism for sale participants. It uses a 3-tier system with different
 * costs (in stable token) to participate. The exchange rate is expressed as the price of 1 stable token in LOOKS token.
 * It is the same for all three tiers.
 */
contract StrategySale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 saleType;
        uint256 amount;
        uint256 startTime;
        uint256 receivedAmount;
    }

    struct SaleType {
        uint256 saleType;
        uint256 totalToken;
        uint256 tge; // reward claimed by the sale participant
        uint256 lockDays; // whether the user has participated
        uint256 vestingDays; // vestingPeriod
        uint256 monthlyUnlockRate; // after 30 days with unlock amount of percentage
        uint256 distributedAmount;
    }

    mapping(uint256 => SaleType) public saleInfo;

    // Number of eligible tiers in the private sale
    uint8 public constant NUMBER_SALE_TYPE = 2;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant DAYS_IN_MONTH = 30;

    address public immutable FENToken;

    // Total FEN expected to be distributed
    uint256 public TOTAL_FEN_DISTRIBUTED;

    // Keeps track of user information (e.g., tier, amount collected, participation)
    mapping(uint256 => mapping(address => UserInfo)) public usersInfo;

    event Harvest(address indexed user, uint256 amount);
    event SaleInfoWhitelisted(SaleType[] _saleInfo);
    event UsersWhitelisted(address[] users);

    /**
     * @notice Constructor
     * @param _fenToken address of the Fen token
     * @param _totalFensDistributed total number of FEN tokens to distribute
     * total is Strategic Parter + Private Sale = 155m
     */
    constructor(address _fenToken, uint256 _totalFensDistributed) {
        FENToken = _fenToken;
        TOTAL_FEN_DISTRIBUTED =
            _totalFensDistributed *
            (10**FEN(_fenToken).decimals());
    }

    /**
     * @notice Whitelist a list of user addresses for a given tier
     * It updates the sale phase to staking phase.
     * @param _saleInfo array of user addresses
     */
    function whitelistSaleInfo(SaleType[] memory _saleInfo) external onlyOwner {
        require(
            _saleInfo.length == NUMBER_SALE_TYPE,
            "length sale type not correct"
        );

        uint256 total;

        for (uint256 i = 0; i < _saleInfo.length; i++) {
            saleInfo[i] = _saleInfo[i];
            total += _saleInfo[i].totalToken;
        }

        require(
            total == TOTAL_FEN_DISTRIBUTED,
            "Total distributed not equal to the set before"
        );

        emit SaleInfoWhitelisted(_saleInfo);
    }

    /**
     * @notice Whitelist a list of user addresses for a given tier
     * It updates the sale phase to staking phase.
     * @param _data array of user addresses
     * @param _users array of user addresses
     */
    function whitelistUsers(
        UserInfo[] calldata _data,
        address[] calldata _users
    ) external onlyOwner {
        require(_users.length == _data.length, "Data input incorrect");
        uint256[] memory tokenDistribute = new uint256[](NUMBER_SALE_TYPE);
        for (uint256 i = 0; i < _users.length; i++) {
            UserInfo memory _user = _data[i];
            tokenDistribute[_user.saleType] += _user.amount;
            require(
                saleInfo[_user.saleType].distributedAmount +
                    tokenDistribute[_user.saleType] <=
                    saleInfo[_user.saleType].totalToken,
                "Out of token distributed"
            );
            require(
                usersInfo[_user.saleType][_users[i]].amount == 0,
                "user already in whitelist"
            );
            usersInfo[_user.saleType][_users[i]] = UserInfo(
                _user.saleType,
                _user.amount,
                _user.startTime,
                0
            );
        }
        emit UsersWhitelisted(_users);
    }

    /**
     * @notice Harvest
     */
    function harvest(uint256 _saleType) external nonReentrant {
        uint256 receiveReward = viewRewardForUser(
            block.timestamp,
            msg.sender,
            _saleType
        );

        _innerMint(msg.sender, receiveReward);

        usersInfo[_saleType][msg.sender].receivedAmount += receiveReward;

        emit Harvest(msg.sender, receiveReward);
    }

    function _innerMint(address to, uint256 amount) private {
        FEN(FENToken).mint(to, amount);
    }

    function viewRewardForUser(
        uint256 toTimeStamp,
        address _user,
        uint256 _saleType
    ) public view returns (uint256) {
        uint256 totalReward;

        UserInfo memory userInfo = usersInfo[_saleType][_user];
        SaleType memory saleType = saleInfo[_saleType];

        if (
            toTimeStamp >
            userInfo.startTime + saleType.lockDays * SECONDS_IN_DAY
        ) {
            uint256 totalMonthPassed = (toTimeStamp -
                userInfo.startTime -
                saleType.lockDays *
                SECONDS_IN_DAY) / (SECONDS_IN_DAY * DAYS_IN_MONTH);
            totalMonthPassed = totalMonthPassed >
                (saleType.vestingDays) / DAYS_IN_MONTH
                ? saleType.vestingDays / DAYS_IN_MONTH
                : totalMonthPassed;
            totalReward += ((userInfo.amount *
                (saleType.monthlyUnlockRate *
                    totalMonthPassed +
                    saleType.tge)) / 10000);
        } else if (toTimeStamp > userInfo.startTime) {
            totalReward += (userInfo.amount * saleType.tge) / 10000;
        }

        return (totalReward - usersInfo[_saleType][_user].receivedAmount);
    }
}
