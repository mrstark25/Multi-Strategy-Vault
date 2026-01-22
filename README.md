# 🏦 Multi-Strategy ERC-4626 Vault

A **production-grade ERC-4626 compliant vault** that accepts USDC deposits, routes capital across multiple underlying strategies, enforces allocation caps, and safely handles locked liquidity via a withdrawal queue.

This repository demonstrates **realistic DeFi vault architecture**, **correct ERC-4626 accounting**, and **high-signal testing practices** using Foundry.

---

## 🚀 Features

- ✅ ERC-4626 compliant vault
- ✅ USDC deposits (6-decimals)
- ✅ Multi-strategy capital allocation (60 / 40 example)
- ✅ Allocation caps to prevent concentration risk
- ✅ Lockup-aware withdrawals with queue & claim
- ✅ Emergency pause (deposits + withdrawals)
- ✅ Balance-based strategy accounting (realistic mocks)
- ✅ Comprehensive Foundry test suite

---

## 🧠 Architecture Overview

User (USDC)
│
▼
┌──────────────────────────┐
│ MultiStrategyVault │ ERC-4626
│ (mVAULT shares) │
└─────────┬────────────────┘
│
┌──────┴─────────┐
▼ ▼
Instant Strategy Lockup Strategy


### Key Principles
- Vault **does not generate yield**
- Strategies generate yield
- Vault aggregates value via `totalAssets()`
- Shares reprice automatically

---

## 📁 Project Structure

src/
├── vaults/
│ └── strategyVault.sol
├── strategies/
│ ├── IStrategy.sol
│ ├── MockInstantStrategy.sol
│ └── MockLockupStrategy.sol
├── mocks/
│ └── MockUSDC.sol
test/
└── strategyVault.t.sol


---

## ⚙️ Setup & Installation

### 1️⃣ Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```
### Verify
forge --version

### Install Dependencies
forge install OpenZeppelin/openzeppelin-contracts

### Build & Run Tests
forge clean
forge test -vv

🏦 Vault Design
ERC-4626 Compliance

deposit, mint, withdraw, redeem

Share pricing derived from totalAssets()

Pause-protected deposits and withdrawals

Multi-Strategy Allocation

Capital is routed based on basis points (BPS)

Example allocation:

Strategy A: 60%

Strategy B: 40%
uint256 public constant MAX_STRATEGY_ALLOCATION = 6_000;

### Asset Agregation(High Signal)
totalAssets =
    idleVaultBalance +
    sum(strategy.totalAssets())

Ensures:

1. Accurate share pricing

2. Automatic yield reflection

3. No manual accounting

Withdrawal Queue (Lockups)
Instant Liquidity

### Withdraws immediately

Locked Liquidity

Funds are queued

User claims later once unlocked
mapping(address => uint256) public queuedWithdrawals;

### Flow

1. User withdraws

2. Instant liquidity paid immediately

3. Locked portion queued

4. User calls claim() after unlock

### Safety & Access Control

1. OpenZeppelin AccessControl

Roles:

    1. DEFAULT_ADMIN_ROLE

    2. MANAGER_ROLE

    3. Emergency pause:

    4. Blocks deposits

    5. Blocks withdrawals

    6.Protects funds

### Test Coverage

The test suite explicitly verifies:

✅ Deposit of 1000 USDC
✅ 60 / 40 strategy allocation
✅ Strategy A gains 10% yield
✅ Shares reprice to ~1060 USDC
✅ Withdrawal queues locked liquidity
✅ Claim after unlock works
✅ Allocation cap enforcement
✅ Emergency pause behavior

### License
MIT