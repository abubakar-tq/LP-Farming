# Scripts (`script/`)

## Deploy

- `DeployScript.s.sol`: deploys `TokenA`, `TokenB`, `LPToken`, `RewardToken`, and `LPContract`, then sets the LP token minter to the pool contract.
- `HelperConfig.s.sol`: stores a simple per-chain config (used by tests and scripts).

### Local (Anvil)

```bash
anvil
forge script script/DeployScript.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast
```

### Testnets / mainnet

This repo’s scripting config is intentionally minimal. For real deployments, prefer reading a `PRIVATE_KEY`
and RPC URL from environment variables (and avoid hardcoding broadcaster addresses).
