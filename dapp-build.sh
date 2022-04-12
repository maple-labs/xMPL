#!/usr/bin/env bash
set -e

export DAPP_SOLC_VERSION=0.8.7
export DAPP_SRC="contracts"
export DAPP_LINK_TEST_LIBRARIES=0
export DAPP_STANDARD_JSON="./dapp-config.json"

dapp --use solc:0.8.7 build
