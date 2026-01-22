// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../strategies/IStrategy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MockLockupStrategy is IStrategy {
    IERC20 public immutable asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    // Deposit USDC into the locked strategy
    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
    }

    // Withdraw is blocked due to lockup
    function withdraw(uint256, address) external pure returns (uint256) {
        revert("locked");
    }

    // Total locked assets (REAL balance)
    function totalAssets() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    // Simulate lockup expiry
    function forceUnlock(address receiver) external {
        uint256 bal = asset.balanceOf(address(this));
        asset.transfer(receiver, bal);
    }

    function hasLockup() external pure returns (bool) {
        return true;
    }
}
