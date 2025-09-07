# Contracts (Draft)

Components (Planned):
- HorizCoinToken (ERC20Votes + Permit)
- EpochReportRegistry (stores oracle-signed reports)
- RewardDistributor (emission allocation logic)
- Staking / Slashing (oracle collateral)

Testing:
- forge test
- Invariants: add under test/invariants
- Fuzz: forge fuzz (select targets)

Security Notes:
- DO NOT deploy to mainnet before audit.
- Keep emission logic bounded & external parameter changes restricted.