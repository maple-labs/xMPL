import subprocess
import os
import argparse

def clean():
    command = ['forge', 'clean']
    result = subprocess.run(command, capture_output=True, text=True)

def build():
    command = ['forge', 'build']
    result = subprocess.run(command, capture_output=True, text=True)

def flatten(contract_path: str):
    output_dir: str = "./flattened"
    is_exist = os.path.exists(output_dir)
    if not is_exist:
        # Create a new directory because it does not exist 
        os.makedirs(output_dir)
        
    contract_name = os.path.split(contract_path)[-1]
    output_path = os.path.join(output_dir, contract_name)
    command = ['forge', 'flatten', contract_path, '-o', output_path]
    subprocess.run(command, capture_output=True, text=True)

    return output_path

def deploy(rpc_url: str, deployer_private_key: str, constructor_args: list, contract_path: str, contract_name: str):
    # EXAMPLE:
    # forge create --rpc-url $rpc \
    # --constructor-args $name $name $owner $MPL $precision \
    # --private-key $pk \
    # $contract

    base_command: list[str] = ["forge", "create"]
    rpc_flag: list[str] = ["--rpc-url", rpc_url]
    constructor_args_flag = ["--constructor-args"] + constructor_args
    private_key_flag: list[str] = ["--private-key", deployer_private_key]
    contract: str = f"{contract_path}:{contract_name}"
    script_args = [contract]

    command = base_command + rpc_flag + constructor_args_flag + private_key_flag + script_args

    result = subprocess.run(command, capture_output=True, text=True)

    # Example: 'No files changed, compilation skipped\nDeployer: 0x37789e01a058bbb079a278c7ba7256d285a262c9\nDeployed to: 0xcd38f7e582b7d50a4fb0ff34eba70ee6e792c03c\nTransaction hash: 0xeed9ac78a8b931ee1966df47bd946c9bdc97e038f2952b5bb0094a01b18e6aef\n'
    output_address = result.stdout.split('\n')[2].split()[2]
    
    return output_address

def encode_constructor_args(constructor_signature: str, constructor_args: list):
    base_command: list[str] = ["cast", "abi-encode"]
    command = base_command + [constructor_signature] + constructor_args
    result = subprocess.run(command, capture_output=True)
    return result.stdout

def verify(contract_address: str, contract_path: str, contract_name: str, etherscan_key: str, constructor_signature: str, constructor_args: list = [], chain_id: int = 1, optimization_runs: int = 200, compiler_version: str = "v0.8.7+commit.e28d00a7"):
    # EXAMPLE:
    # forge verify-contract --chain-id 4 \
    # --num-of-optimizations 200 \
    # --constructor-args $(cast abi-encode "constructor(string,string,address,address,uint256)" $name $name $owner $MPL $precision) \
    # --compiler-version v0.8.7+commit.e28d00a7 \
    # $contract_address \
    # $contract \
    # $etherscan_key

    base_command: list[str] = ["forge", "verify-contract"]
    chain_id_flag: list[str] = ["--chain-id", f"{chain_id}"]
    optimization_runs_flag: list[str] = ["--num-of-optimizations", f"{optimization_runs}"]
    constructor_args_flag = []
    if len(constructor_args) > 0 and len(constructor_signature) > 0:
        constructor_args_flag = ['--constructor-args', encode_constructor_args(constructor_signature, constructor_args)]
    
    compiler_version_flag = ["--compiler-version", compiler_version]
    script_args = [contract_address, f"{contract_path}:{contract_name}", etherscan_key]
   
    command = base_command + chain_id_flag + optimization_runs_flag + constructor_args_flag + compiler_version_flag + script_args
    result = subprocess.run(command, capture_output=True)
    print(result.stdout)

def parse_command_line():
    # Initialize parser
    parser = argparse.ArgumentParser()
    
    # Adding optional argument
    parser.add_argument("--rpc-url")
    parser.add_argument("--private-key")
    parser.add_argument("--etherscan-key")
    
    # Read arguments from command line
    args = parser.parse_args()
    return args


def main():
    # get cli args
    args = parse_command_line()

    clean()
    build()
    
    # flatten
    contract_path = './contracts/xMPL.sol'
    # contract_path = flatten(contract_path) # Don't flatten for now as its broken.
    
    # deploy
    owner_address = '0x37789e01a058Bbb079A278C7bA7256d285A262c9'
    MPL_address = '0xAeECBaebEEEEF8F55cb7756019F6f8A80BAB657A'
    constructor_args = ['"x Maple Token"', '"xMPL"', owner_address, MPL_address, f"{1000000000000000000000000000000}"]
    contract_name = 'xMPL'

    xMPL_address = deploy(args.rpc_url, args.private_key, constructor_args, contract_path, contract_name)

    # verify
    constructor_signature = "constructor(string,string,address,address,uint256)"
    verify(xMPL_address, contract_path, contract_name, args.etherscan_key, constructor_signature, constructor_args, chain_id=4, optimization_runs=100000, compiler_version="v0.8.7+commit.e28d00a7")

main()