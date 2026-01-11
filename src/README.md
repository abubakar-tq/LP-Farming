# Contracts (`src/`)

This folder contains a minimal liquidity + farming implementation used for Foundry testing and scripting.

## Overview

- `LPContract.sol`: accepts deposits of `TokenA` + `TokenB`, mints LP tokens, and tracks staked LP for rewards.
- `LPToken.sol`: ERC20 LP token; mint/burn is restricted to a single `minter` (the pool contract).
- `RewardToken.sol`: ERC20 reward token minted as emissions.
- `TokenA.sol`, `TokenB.sol`: demo ERC20s (mintable; also pre-mint in constructor).

## Reward accounting (high level)

The pool uses the common MasterChef-style pattern:

- `accRewardPerShare`: accumulated rewards per staked LP (scaled by `1e12`)
- `rewardDebt`: per-user bookkeeping to avoid overpaying rewards

On each `deposit`, `withdraw`, or `claimReward`, the pool updates global state (`updatePool`) and pays any
pending rewards before updating the user’s `rewardDebt`.

## Important limitations (do not use in production)

- `RewardToken.mint()` is permissionless.
- LP is treated as “staked” as soon as it’s minted; transferring LP tokens away can break the user’s ability to withdraw.
- No production security hardening (reentrancy protections, safe ERC20 handling, access controls, etc.).
