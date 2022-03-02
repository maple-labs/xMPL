# xMPL

![Foundry CI](https://github.com/maple-labs/loan/actions/workflows/push-to-main.yml/badge.svg) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**DISCLAIMER: This code has NOT been externally audited and is actively being developed. Please do not use in production without taking the appropriate steps to ensure maximum security.**

This repo contains a set of contracts to facilitate on-chain distribution of vesting earnings on an aggregated schedule. This allows for multiple deposits to be made to the same contract on a recurring basis with custom vesting parameters.

## Capabilities

xMPL inherits the core functionality from Maple's [Revenue Distribution Token](https://github.com/maple-labs/revenue-distribution-token), which allows users to lock assets to earn rewards distributions based on a vesting schedule, with the increased functionality to perform a one time asset migration for the underlying token. This migration will interact with the contracts defined in [mpl-migration](https://github.com/maple-labs/mpl-migration).


![Diagram](https://user-images.githubusercontent.com/16119563/156415169-75b2d7b4-8466-447c-b9ad-f9b94d3f6546.jpeg)

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
