// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../strategies/IStrategy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../mocks/MockUSDC.sol";

contract MockInstantStrategy is IStrategy {
    IERC20 public immutable asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    // Deposit USDC into the strategy
    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
    }

    // Withdraw available USDC (instant liquidity)
    function withdraw(uint256 amount, address receiver)
        external
        returns (uint256)
    {
        uint256 bal = asset.balanceOf(address(this));
        uint256 withdrawn = amount > bal ? bal : amount;

        asset.transfer(receiver, withdrawn);
        return withdrawn;
    }

    // Total strategy value (REAL balance)
    function totalAssets() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function hasLockup() external pure returns (bool) {
        return false;
    }

    // Simulate yield by minting real USDC
    function mockIncreaseValue(uint256 percent) external {
        uint256 bal = asset.balanceOf(address(this));
        uint256 gain = (bal * percent) / 100;

        // mint real USDC to simulate profit
        MockUSDC(address(asset)).mint(address(this), gain);
    }
}
