// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bet {
    IERC20 public immutable WBTC;
    IERC20 public immutable USDC;
    AggregatorV3Interface public immutable PRICEFEED;

    address public balaji;
    address public counterparty;
    uint256 public duration = 90 days;
    uint256 public startTimestamp;

    address internal owner;
    address internal winner;

    constructor(address _WBTC, address _USDC, address _PRICEFEED) {
        WBTC = IERC20(_WBTC);
        USDC = IERC20(_USDC);
        PRICEFEED = AggregatorV3Interface(_PRICEFEED);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    function depositWBTC() external {
        require(WBTC.allowance(msg.sender, address(this)) >= 1e8, "Insufficient allowance!");
        require(counterparty == address(0), "Counterparty already initiated!");
        WBTC.transferFrom(msg.sender, address(this), 1e8);
        counterparty = msg.sender;
        if(counterparty != address(0) && balaji != address(0)) {
            startTimestamp = block.timestamp;
        }
    }

    function depositUSDC() external {
        require(USDC.allowance(msg.sender, address(this)) >= 1_000_000e6, "Insufficient allowance!");
        require(balaji == address(0), "Balaji already initiated!");
        USDC.transferFrom(msg.sender, address(this), 1_000_000e6);
        balaji = msg.sender;
        if(counterparty != address(0) && balaji != address(0)) {
            startTimestamp = block.timestamp;
        }
    }

    function getBTCPrice() public view returns (uint256) {
        (, int256 price,,,) = PRICEFEED.latestRoundData();
        return uint256(price) / 10 ** PRICEFEED.decimals();
    }

    function settle() public {
        require(startTimestamp != 0, "Bet not intitated!");
        require(startTimestamp + duration >= block.timestamp, "Bet not complete!");
        winner = getBTCPrice() > 1_000_000 ? balaji : counterparty;
    }

    function terminate() external onlyOwner {
        USDC.transfer(balaji, 1_000_000e6);
        WBTC.transfer(counterparty, 1e8);
    }

    function withdraw() external {
        require(winner == msg.sender, "Not winner!");
        USDC.transfer(winner, 1_000_000e6);
        WBTC.transfer(winner, 1e8);
    }
}