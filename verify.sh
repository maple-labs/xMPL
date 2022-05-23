set -e

while getopts e: flag
do
    case "${flag}" in
        e) etherscan_key=${OPTARG};;
    esac
done

rpc="https://eth-rinkeby.alchemyapi.io/v2/iixxBCfWsebK8V-7FXTefd3OJwIEO2Wt"
name="xMPL"
owner="0x37789e01a058Bbb079A278C7bA7256d285A262c9"
MPL="0xAeECBaebEEEEF8F55cb7756019F6f8A80BAB657A"
contract="contracts/xMPL.sol:xMPL"
precision=1000000000000000000000000000000

# change this to deploy script output address
contract_address="0xc0f6e5181b927315612da87d90ff8e080b6ce45f"

forge verify-contract --chain-id 4 \
--num-of-optimizations 200 \
--constructor-args $(cast abi-encode "constructor(string,string,address,address,uint256)" $name $name $owner $MPL $precision) \
--compiler-version v0.8.7+commit.e28d00a7 \
$contract_address \
$contract \
$etherscan_key