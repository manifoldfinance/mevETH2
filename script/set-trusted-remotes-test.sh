#!/usr/bin/env bash
# sudo apt install jq

source .envrc.local

file='lz-oft-deployment-config-example.json'

mapfile -t lzIds < <(jq -r 'to_entries[] | .key' "$file")
mapfile -t ofts < <(jq -r 'to_entries[] | .value' "$file")

for i in "${!lzIds[@]}"
do
    id=${lzIds[i]}
    oft=${ofts[i]}
    echo "$id $oft"
    if [[ $id == 101 ]]
    then
        chain=1
        rpc=$ETH_MAINNET_RPC_URL
    elif [[ $id == 102 ]]
    then
        chain=56
        rpc=$BSC_MAINNET_RPC_URL
    elif [[ $id == 106 ]]
    then
        chain=43114
        rpc=$AVALANCHE_RPC_URL
    elif [[ $id == 109 ]]
    then
        chain=137
        rpc=$POLYGON_MAINNET_RPC_URL
    elif [[ $id == 110 ]]
    then
        chain=42161
        rpc=$ARBITRUM_MAINNET_RPC_URL
    elif [[ $id == 111 ]]
    then
        chain=10
        rpc=$OPTIMISM_RPC_URL
    elif [[ $id == 10121 ]]
    then
        chain=5
        rpc=$GOERLI_RPC_URL
    elif [[ $id == 10102 ]]
    then
        chain=97
        rpc=$BSC_TESTNET_RPC_URL
    elif [[ $id == 10109 ]]
    then
        chain=80001
        rpc=$POLYGON_TESTNET_RPC_URL
    fi
    echo "$chain $rpc"
    # strip out current chain and contract from args
    ids=("${lzIds[@]}")
    unset ids[i] 
    ids=$(IFS=,; echo "[${ids[*]}]")
    addresses=("${ofts[@]}")
    unset addresses[i]
    addresses=$(IFS=,; echo "[${addresses[*]}]")
    args="2 $oft $ids $addresses"
    echo $args
    forge script script/WireUpOFT.s.sol:WireUpOFTScript \
        --sig "run(uint16,address,uint16[],address[])" $args \
        --chain-id $chain \
        --fork-url $rpc \
        -vvvvv
done