// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "../strategies/IStrategy.sol";

contract MultiStrategyVault is ERC4626, AccessControl, Pausable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public constant MAX_BPS = 10_000;
    uint256 public constant MAX_STRATEGY_ALLOCATION = 6_000;

    struct StrategyInfo {
        address strategy;
        uint16 bps;
        bool active;
    }

    StrategyInfo[] public strategies;
    mapping(address => uint256) public queuedWithdrawals;

    constructor(IERC20 asset_)
        ERC20("Multi Strategy Vault", "mVAULT")
        ERC4626(asset_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

event HyperCoreAction(
    uint256 indexed actionId,
    address indexed caller,
    uint256 amount
);

/**
 * @notice Mock deposit to Hyperliquid HLP
 * @dev Action ID 2 = deposit to HLP
 */
function depositToHLP(uint256 amount)
    external
    onlyRole(MANAGER_ROLE)
{
    require(amount > 0, "amount=0");

    emit HyperCoreAction(2, msg.sender, amount);
}


    function deposit(uint256 assets, address receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        return super.mint(shares, receiver);
    }

    function addStrategy(address strat, uint16 bps)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(bps <= MAX_STRATEGY_ALLOCATION, "cap exceeded");
        strategies.push(StrategyInfo(strat, bps, true));
    }

    function totalAssets() public view override returns (uint256 total) {
        // ✅ include idle assets in vault
        total = IERC20(asset()).balanceOf(address(this));

        // ✅ include assets deployed to strategies
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].active) {
                total += IStrategy(strategies[i].strategy).totalAssets();
            }
        }
    }

    function rebalance() external onlyRole(MANAGER_ROLE) {
        uint256 assets = totalAssets();

        for (uint256 i = 0; i < strategies.length; i++) {
            StrategyInfo memory s = strategies[i];

            uint256 target = (assets * s.bps) / MAX_BPS;
            uint256 current = IStrategy(s.strategy).totalAssets();

            if (current < target) {
                uint256 delta = target - current;
                IERC20(asset()).approve(s.strategy, delta);
                IStrategy(s.strategy).deposit(delta);
            }
        }
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused returns (uint256 shares) {
        shares = previewWithdraw(assets);
        _burn(owner, shares);

        uint256 remaining = assets;

        // withdraw from instant-liquidity strategies
        for (uint256 i = 0; i < strategies.length && remaining > 0; i++) {
            IStrategy strat = IStrategy(strategies[i].strategy);

            if (!strat.hasLockup()) {
                uint256 w = strat.withdraw(remaining, address(this));
                remaining -= w;
            }
        }

        // send what we have immediately
        uint256 bal = IERC20(asset()).balanceOf(address(this));
        uint256 payout = bal >= assets ? assets : bal;
        if (payout > 0) {
            IERC20(asset()).transfer(receiver, payout);
        }

        // queue the rest
        if (assets > payout) {
            queuedWithdrawals[receiver] += (assets - payout);
        }
    }

    function claim() external {
        uint256 amount = queuedWithdrawals[msg.sender];
        require(amount > 0, "nothing queued");

        queuedWithdrawals[msg.sender] = 0;

        // assume locked strategy has already force-unlocked to vault
        uint256 bal = IERC20(asset()).balanceOf(address(this));
        require(bal >= amount, "insufficient unlocked funds");

        IERC20(asset()).transfer(msg.sender, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
