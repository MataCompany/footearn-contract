pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

contract TokenPO is
    AccessControlEnumerable,
    ERC20,
    ERC20Burnable,
    Ownable,
    Pausable
{
    using SafeMath for uint256;

    address public footEarn;
    address public stableToken;
    address public WMATIC;
    address public uniswapV2Router02;

    address public recipient_fen;

    uint256 public amountStableTokenInPO;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event LogSwapFenToPO(address user, uint256 amountIn, uint256 amountOut);

    event NewPOPrice(uint256 amountStableTokenInPO);

    constructor(
        address _footearn_token,
        address _stable_token,
        address _wmatic,
        address _uniswapV2Router02,
        address _recipient_fen,
        uint256 _amount_stable_token_in_po
    ) ERC20("PO Token", "PO") {
        uniswapV2Router02 = _uniswapV2Router02;
        footEarn = _footearn_token;
        stableToken = _stable_token;
        recipient_fen = _recipient_fen;
        amountStableTokenInPO = _amount_stable_token_in_po;
        WMATIC = _wmatic;
    }

    function updateAmountStableTokenInPO(uint256 amountPO) public onlyOwner {
        amountStableTokenInPO = amountPO;

        emit NewPOPrice(amountStableTokenInPO);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Add factory to mint item
     */
    function setMintFactory(address factory) public onlyOwner {
        _setupRole(MINTER_ROLE, factory);
    }

    function swapFENToPO(uint256 _amount) public {
        address[] memory path = new address[](2);

        path[0] = footEarn;
        path[1] = WMATIC;

        // get _amount FEN = ? MATIC
        uint256 getMatic = getExactTokenForToken(_amount, path);

        //get busd
        path[0] = WMATIC;
        path[1] = stableToken;
        uint256 getStableToken = getExactTokenForToken(getMatic, path);

        IERC20(footEarn).transferFrom(msg.sender, recipient_fen, _amount);

        _mint(msg.sender, getStableToken * amountStableTokenInPO);

        emit LogSwapFenToPO(
            msg.sender,
            _amount,
            getStableToken * amountStableTokenInPO
        );
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        _mint(to, amount);
    }

    function getExactTokenForToken(
        uint256 _amountTokenIn,
        address[] memory path
    ) public view returns (uint256) {
        return
            IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
                _amountTokenIn,
                path
            )[1];
    }
}
