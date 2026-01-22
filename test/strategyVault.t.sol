//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/vaults/strategyVault.sol";
import "../src/mocks/MockUSDC.sol";
import "../src/strategies/MockInstantStrategy.sol";
import "../src/strategies/MockLockupStrategy.sol";

contract VaultTest is Test {
     event HyperCoreAction(
        uint256 indexed actionId,
        address indexed caller,
        uint256 amount
    );
    MockUSDC usdc;
    MultiStrategyVault vault;
    MockInstantStrategy stratA;
    MockLockupStrategy stratB;

    address user = address(1);

    function setUp() public {
        usdc = new MockUSDC();
        vault = new MultiStrategyVault(usdc);
        stratA = new MockInstantStrategy(usdc);
        stratB = new MockLockupStrategy(usdc);

        vault.addStrategy(address(stratA), 6000);
        vault.addStrategy(address(stratB), 4000);

        usdc.mint(user, 1_000e6);

        vm.startPrank(user);
        usdc.approve(address(vault), type(uint256).max);
        vault.deposit(1_000e6, user);
        vm.stopPrank();

        vault.rebalance();
    }

    function testYieldIncrease() public {
        stratA.mockIncreaseValue(10);

        uint256 value = vault.previewRedeem(vault.balanceOf(user));
        assertApproxEqAbs(value, 1_060e6, 2e6);
    }

    function testWithdrawWithQueue() public {
        vm.prank(user);
        vault.withdraw(1_000e6, user, user);

        assertGt(vault.queuedWithdrawals(user), 0);
    }

    function testClaimAfterUnlock() public {
    vm.prank(user);
    vault.withdraw(1_000e6, user, user);

    uint256 queued = vault.queuedWithdrawals(user);
    assertGt(queued, 0);

    // simulate unlock
    stratB.forceUnlock(address(vault));

    vm.prank(user);
    vault.claim();

    assertEq(vault.queuedWithdrawals(user), 0);
}

function testAllocationCapPreventsConcentration() public {
    MultiStrategyVault v = new MultiStrategyVault(usdc);

    vm.expectRevert("cap exceeded");
    v.addStrategy(address(stratA), 7000); // >60% should fail
}

function testTotalAssetsAggregationExplicit() public {
    uint256 total = vault.totalAssets();
    assertEq(total, 1_000e6);
}


function testWithdrawalQueuesLockedLiquidity() public {
    vm.prank(user);
    vault.withdraw(1_000e6, user, user);

    uint256 queued = vault.queuedWithdrawals(user);
    assertGt(queued, 0);
}

function testPauseBlocksDeposits() public {
    vault.pause();

    vm.prank(user);
    vm.expectRevert();
    vault.deposit(100e6, user);
}


function testPauseBlocksWithdrawals() public {
    vault.pause();

    vm.prank(user);
    vm.expectRevert();
    vault.withdraw(100e6, user, user);
}

function testHyperCoreMockDeposit() public {
    vm.expectEmit(true, true, false, true);
    emit HyperCoreAction(2, address(this), 100e6);

    vault.depositToHLP(100e6);
}

}
