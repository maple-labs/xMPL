#!/usr/bin/env bash

set -e

while getopts p: flag
do
    case "${flag}" in
        p) pk=${OPTARG};;
    esac
done

rpc="https://eth-rinkeby.alchemyapi.io/v2/iixxBCfWsebK8V-7FXTefd3OJwIEO2Wt"
name="xMPL"
owner="0x37789e01a058Bbb079A278C7bA7256d285A262c9"
MPL="0xAeECBaebEEEEF8F55cb7756019F6f8A80BAB657A"
contract="./contracts/xMPL.sol:xMPL"
precision=1000000000000000000000000000000

forge create --rpc-url $rpc \
--constructor-args $name $name $owner $MPL $precision \
--private-key $pk \
$contract



