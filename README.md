# xMPL

![Foundry CI](https://github.com/maple-labs/loan/actions/workflows/push-to-main.yml/badge.svg) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**DISCLAIMER: This code has NOT been externally audited and is actively being developed. Please do not use in production without taking the appropriate steps to ensure maximum security.**

This repo contains a set of contracts to facilitate on-chain distribution of protocol revenues denominated in MPL tokens. MPL distributions are made using RevenueDistributionToken (RDT) vesting schedule functionaltiy. This allows for multiple deposits to be made to the same contract on a recurring basis with custom vesting parameters.

## Capabilities

xMPL inherits the core functionality from Maple's [Revenue Distribution Token](https://github.com/maple-labs/revenue-distribution-token), which allows users to lock assets to earn rewards distributions based on a vesting schedule, with the increased functionality to perform a one time asset migration for the underlying token. This migration will interact with the contracts defined in [mpl-migration](https://github.com/maple-labs/mpl-migration).

![One Time xMPL Migration Diagram](https://user-images.githubusercontent.com/44272939/156459811-1a4b623c-932a-4ac4-b9e7-147ccfa1c6ca.png)

### One-Time xMPL Migration
1. Governor address calls `performMigration`. This is only possible after calling `scheduleMigration` and waiting the minimum delay period, 10 days. This timelock mechanism is put in place to ensure that users have the opportunity to exit the contract if they do not agree with the migration contract that is being used (if it is malicious for example).

2. The xMPL contract deposits its entire balance of MPL to the migrator contract.

3. The migrator contract takes the MPL amount and returns the exact same amount of MPLv2.

4. The xMPL contract changes the underlying asset to track the new MPLv2 token.

## Testing and Development
#### Setup
```sh
git clone git@github.com:maple-labs/xMPL.git
cd xMPL
forge update
```
#### Running Tests
- To run all tests: `make test` (runs `./test.sh`)
- To run a specific test function: `./test.sh -t <test_name>` (e.g., `./test.sh -t test_deposit`)
- To run tests with a specified number of fuzz runs: `./test.sh -r <runs>` (e.g., `./test.sh -t test_deposit -r 10000`)

This project was built using [Foundry](https://github.com/gakonst/Foundry).

## About Maple
[Maple Finance](https://maple.finance) is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

For all technical documentation related to the currently deployed Maple protocol, please refer to the maple-core GitHub [wiki](https://github.com/maple-labs/maple-core/wiki).

---

<p align="center">
  <img src="https://user-images.githubusercontent.com/44272939/116272804-33e78d00-a74f-11eb-97ab-77b7e13dc663.png" height="100" />
</p>
