// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "./FEN.sol";

// /**
//  * @title StrategySale
//  * @notice It handles the private sale for LOOKS tokens (against stable token) and the fee-sharing
//  * mechanism for sale participants. It uses a 3-tier system with different
//  * costs (in stable token) to participate. The exchange rate is expressed as the price of 1 stable token in LOOKS token.
//  * It is the same for all three tiers.
//  */
// contract StrategySale is Ownable, ReentrancyGuard {
//     using SafeERC20 for IERC20;

//     enum SalePhase {
//         Pending, // Pending (owner sets up parameters)
//         Claim
//     }

//     struct BuyHistory {
//         uint256 amount;
//         uint256 starttime;
//         uint256 receivedAmount;
//     }

//     struct UserInfo {
//         uint256 amount;
//         uint256 startTime;
//         uint256 receivedAmount;
//     }

//     struct SaleType {
//         mapping(address => UserInfo) users;
//         uint256 saleType;
//         uint256 totalToken;
//         uint256 tge; // reward claimed by the sale participant
//         uint256 lockDays; // whether the user has participated
//         uint256 vestingDays; // vestingPeriod
//         uint256 monthlyUnlockRate; // after 30 days with unlock amount of percentage
//         uint256 distributedAmount;
//     }

//     bool private _addWhiteList;

//     SaleType[] public saleInfo;

//     // Number of eligible tiers in the private sale
//     uint8 public constant NUMBER_SALE_TYPE = 2;
//     uint256 public constant SECONDS_IN_DAY = 86400;
//     uint256 public constant DAYS_IN_MONTH = 30;

//     address public immutable FENToken;

//     // Total FEN expected to be distributed
//     uint256 public TOTAL_FEN_DISTRIBUTED;

//     // Current sale phase (uint8)
//     SalePhase public currentPhase;

//     uint256 public priceOfFENInBUSD;

//     // Total amount committed in the sale
//     uint256 public totalAmountCommitted;

//     uint256 public totalRewardTokensDistributedToUsers;

//     // Keeps track of the cost to join the sale for a given tier
//     mapping(uint8 => uint256) public allocationCostPerTier;

//     // Keeps track of the number of whitelisted participants for each tier
//     mapping(uint8 => uint256) public numberOfParticipantsForATier;

//     // Keeps track of user information (e.g., tier, amount collected, participation)
//     mapping(uint8 => mapping(address => UserInfo)) public saleType;

//     event Buy(address indexed user, uint8 tier, uint256 amount);
//     event Harvest(address indexed user, uint256 amount);
//     event NewSalePhase(SalePhase newSalePhase);
//     event NewAllocationCostPerTier(uint8 tier, uint256 allocationCostInETH);
//     event NewBlockForWithdrawal(uint256 blockForWithdrawal);
//     event NewPriceOfETHInLOOKS(uint256 price);
//     event SaleInfoWhitelisted();
//     event UsersWhitelisted(UserInfo[] users, uint256 _saleType);
//     event UserRemoved(address user, uint256 tier);
//     event Withdraw(address indexed user, uint8 tier, uint256 amount);

//     /**
//      * @notice Constructor
//      * @param _fenToken address of the Fen token
//      * @param _busd address of the token receive
//      * @param _totalFensDistributed total number of FEN tokens to distribute
//      * total is Strategic Parter + Private Sale = 155m
//      */
//     constructor(
//         address _fenToken,
//         address _busd,
//         uint256 _totalFensDistributed
//     ) {
//         FENToken = _fenToken;
//         TOTAL_FEN_DISTRIBUTED = _totalFensDistributed;
//     }

//     //Pending phase

//     /**
//      * @notice Whitelist a list of user addresses for a given tier
//      * It updates the sale phase to staking phase.
//      * @param _saleType array of user addresses
//      * @param _totalToken array of user addresses
//      */
//     function whitelistSaleInfo(
//         uint8[] calldata _saleType,
//         uint256[] calldata _totalToken,
//         uint256[] calldata _tge,
//         uint256[] calldata _lockDays,
//         uint256[] calldata _vestingDays,
//         uint256[] calldata _monthlyUnlockRate
//     ) external onlyOwner {
//         require(
//             _saleType.length == _totalToken.length &&
//                 _saleType.length == _tge.length &&
//                 _saleType.length == _lockDays.length &&
//                 _saleType.length == _vestingDays.length &&
//                 _saleType.length == _monthlyUnlockRate.length &&
//                 _saleType.length == NUMBER_SALE_TYPE,
//             "length sale type not correct"
//         );

//         uint256 total;

//         for (uint256 i = 0; i < _saleType.length; i++) {
//             saleInfo[i].saleType = _saleType[i];
//             saleInfo[i].totalToken = _saleType[i];
//             saleInfo[i].tge = _saleType[i];
//             saleInfo[i].lockDays = _saleType[i];
//             saleInfo[i].vestingDays = _saleType[i];
//             saleInfo[i].monthlyUnlockRate = _saleType[i];
//             saleInfo[i].distributedAmount = _saleType[i];
//             total += _totalToken[i];
//         }

//         require(
//             total == TOTAL_FEN_DISTRIBUTED,
//             "Total distributed not equal to the set before"
//         );

//         emit SaleInfoWhitelisted();
//     }

//     /**
//      * @notice Whitelist a list of user addresses for a given tier
//      * It updates the sale phase to staking phase.
//      * @param _data array of user addresses
//      * @param _users array of user addresses
//      * @param _saleType tier for the array of users
//      */
//     function whitelistUsers(
//         UserInfo[] calldata _data,
//         address[] calldata _users,
//         uint256 _saleType
//     ) external onlyOwner {
//         require(_users.length == _data.length, "Data input incorrect");
//         for (uint256 i = 0; i < _users.length; i++) {
//             saleInfo[_saleType].users[_users] = UserInfo(
//                 _data[i].amount,
//                 _data[i].startTime
//             );
//         }
//         emit UsersWhitelisted(_users, _saleType);
//     }

//     /**
//      * @notice Harvest
//      */
//     function harvest(uint256 _saleType) external nonReentrant {
//         require(
//             currentPhase == SalePhase.Staking,
//             "Harvest: Phase must be Staking"
//         );

//         uint256 receiveReward = viewRewardForUser(
//             block.timestamp,
//             msg.sender,
//             _saleType
//         );

//         _innerMint(msg.sender, receiveReward);

//         saleInfo[_saleType].users[msg.sender].receivedAmount += receiveReward;

//         emit Harvest(msg.sender, receiveReward);
//     }

//     function _innerMint(address to, uint256 amount) private {
//         FEN(FENToken).mint(to, amount);
//     }

//     function viewRewardForUser(
//         uint256 toTimeStamp,
//         address user,
//         uint256 _saleType
//     ) public view returns (uint256) {
//         uint256 totalReward;

//         if (
//             toTimeStamp >
//             saleInfo[_saleType].users[user].startTime +
//                 saleInfo[_saleType].lockDays *
//                 SECONDS_IN_DAY
//         ) {
//             uint256 totalMonthPassed = (toTimeStamp -
//                 saleInfo[_saleType].users[user].startTime -
//                 saleInfo[_saleType].lockDays *
//                 SECONDS_IN_DAY) / (SECONDS_IN_DAY * DAYS_IN_MONTH);
//             totalMonthPassed = totalMonthPassed >
//                 (saleInfo[_saleType].vestingDays) / DAYS_IN_MONTH
//                 ? (saleInfo[_saleType].vestingDays) / DAYS_IN_MONTH
//                 : totalMonthPassed;
//             totalReward += ((saleInfo[_saleType].users[user].amount *
//                 (saleInfo[_saleType].mothlyUnlockRate *
//                     totalMonthPassed +
//                     saleInfo[_saleType].tge)) / 10000);
//         } else if (toTimeStamp > saleInfo[_saleType].users[user].startTime) {
//             totalReward +=
//                 (saleInfo[_saleType].users[user].amount *
//                     saleInfo[_saleType].tge) /
//                 10000;
//         }

//         return (totalReward - saleInfo[_saleType].users[user].receivedAmount);
//     }
// }
