# xMPL

![Foundry CI](https://github.com/maple-labs/loan/actions/workflows/push-to-main.yml/badge.svg) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**DISCLAIMER: This code has NOT been externally audited and is actively being developed. Please do not use in production without taking the appropriate steps to ensure maximum security.**

This repo contains a set of contracts to facilitate on-chain distribution of protocol revenues denominated in MPL tokens. MPL distributions are made using RevenueDistributionToken (RDT) vesting schedule functionaltiy. This allows for multiple deposits to be made to the same contract on a recurring basis with custom vesting parameters.

## Capabilities

xMPL inherits the core functionality from Maple's [Revenue Distribution Token](https://github.com/maple-labs/revenue-distribution-token), which allows users to lock assets to earn rewards distributions based on a vesting schedule, with the increased functionality to perform a one time asset migration for the underlying token. This migration will interact with the contracts defined in [mpl-migration](https://github.com/maple-labs/mpl-migration).

This mechanism is present in case a MPL migration is ever needed, which would need to go through Maple's governance process for the community approval, which includes a time delay, which allows for interested parties to act before the changes take effect.

![One Time xMPL Migration Diagram](https://user-images.githubusercontent.com/44272939/156459811-1a4b623c-932a-4ac4-b9e7-147ccfa1c6ca.png)

### One-Time xMPL Migration

This allows a seamless and safe migration for all users that have staked their MPL into the xMPL contract. 

1. The first step to trigger a migration is for the contract governor to call `scheduleMigration`, which sets a execution to occur at least 10 days from the transaction time. In the meantime, all operations in the xMPL contract remain operational.

2. During this period, any party that disagrees with the scheduled migration can withdraw their funds from the contract. 

3. After the time delay, anyone can call `performMigration`, which executes the migration with the parameters set 10 days prior

4. During this migration,the xMPL contract deposits its entire balance of MPL to the migrator contract, which includes non vested and vested funds. 

5. The migrator contract takes the MPL amount and returns the exact same amount of MPLv2, with a 1:1 ratio. The MPL tokens will remain locked in the migrator contract so they can't be migrated twice.

6. In the last step, the address defined as `asset` in xMPL contract is switched MPL v1 to the newly migrated MPL v2 address. From that point on, all subsequent operations will be in relative to the new migrated token. 

Holders of the xMPL token do not to perform any action to have their balance migrated, however, holder that do not interact with xMPL would need to perform a migration by themselves.

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
