# LP Farming (Foundry / Solidity)

Educational Foundry project that implements a minimal **liquidity pool + farming** flow:
deposit two ERC20 tokens, receive LP tokens, and accrue a mintable reward token per block using the
`accRewardPerShare` / `rewardDebt` accounting pattern.

This repo is intended for learning and showcasing Solidity + Foundry skills (tests, scripts, CI).

## Tech stack

- Solidity `^0.8.20`
- Foundry (Forge/Anvil)
- OpenZeppelin Contracts (ERC20 + `Math.sqrt`)

## What’s inside

- `src/LPContract.sol`: pool + rewards logic (`deposit`, `withdraw`, `claimReward`, `pendingReward`)
- `src/LPToken.sol`: LP token (mint/burn controlled by the pool contract)
- `src/TokenA.sol`, `src/TokenB.sol`: simple ERC20s used for testing/demo
- `src/RewardToken.sol`: reward ERC20 minted as emissions
- `script/DeployScript.s.sol`: deploys demo tokens + pool (see `script/README.md`)
- `test/unit/LPContractTest.sol`: unit tests for deposits/withdrawals/reward accrual

## Quickstart

Clone with submodules (OpenZeppelin + forge-std are included as git submodules):

```bash
git clone --recurse-submodules <repo-url>
cd lp-farming
```

Build + test:

```bash
forge build
forge test -vvv
```

## Mechanics (high level)

- Initial liquidity: `sqrt(amountA * amountB)`
- Later deposits: liquidity minted is proportional to existing reserves (min of the two ratios)
- Rewards: `rewardPerBlock` distributed pro-rata to “staked” LP, accounted via `accRewardPerShare` + `rewardDebt`

## Local deployment (Anvil)

Terminal 1:

```bash
anvil
```

Terminal 2:

```bash
forge script script/DeployScript.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast
```

## Notes / limitations (important)

This is a **toy / learning implementation** and is **not audited**. In particular:

- `RewardToken.mint()` is permissionless (anyone can mint) — do not use as-is in production.
- The pool does not implement production-grade AMM mechanics (pricing, fees, swaps, slippage).
- No hardening against malicious ERC20 behavior (reentrancy/fee-on-transfer hooks, etc.).

## Repo structure

- `src/README.md`: contract-level notes
- `script/README.md`: scripts + configuration notes
- `test/README.md`: testing notes

## CI

GitHub Actions runs `forge fmt --check`, `forge build --sizes`, and `forge test -vvv` on pushes/PRs.
Workflow: `.github/workflows/test.yml`.

## References

- Foundry book: https://book.getfoundry.sh/
