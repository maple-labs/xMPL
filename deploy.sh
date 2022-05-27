#!/usr/bin/env bash
set -e

name="xMPL"
MPL="0xAeECBaebEEEEF8F55cb7756019F6f8A80BAB657A"  # Rinkeby
contract="./contracts/xMPL.sol:xMPL"
precision=1000000000000000000000000000000

forge create --rpc-url $ETH_RPC_URL \
--constructor-args $name $name $ETH_FROM $MPL $precision \
--from $ETH_FROM \
$contract
