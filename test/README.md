# Tests (`test/`)

Unit tests live in `test/unit/` and cover:

- deposits and withdrawals
- reward accrual over blocks (`pendingReward`)
- claiming rewards (`claimReward`)
- edge cases (zero amounts, insufficient LP, no stakers)

Run:

```bash
forge test -vvv
```

Filter:

```bash
forge test --match-test testDeposit -vvv
```
