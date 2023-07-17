#!/usr/bin/env bash

set -euxo pipefail

# Ensure dasel is installed
if ! command -v dasel &>/dev/null; then
  echo "dasel could not be found"
  exit
fi

# Default configuration file
DEFAULT_FILE='lz-oft-deployment-config.json'
file=''
DRY_RUN=false

# Function to log messages with a timestamp
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | trusted-remotes - $*"
}

# Function to display help
display_help() {
  echo "Usage: $0 [option...]" >&2
  echo
  echo "   This script deploys contracts by reading a config file (default: $DEFAULT_FILE)"
  echo
  echo "   -f, --file        specify a configuration file"
  echo "   -h, --help        display this help and exit"
  echo "   -d, --dry-run     perform a dry run (do not execute commands)"
  echo
  exit 1
}

# Function to validate environment variables
validate_env() {
  local missing=false
  for var in ETH_MAINNET_RPC_URL BSC_MAINNET_RPC_URL AVALANCHE_RPC_URL POLYGON_MAINNET_RPC_URL ARBITRUM_MAINNET_RPC_URL OPTIMISM_RPC_URL PRIVATE_KEY; do
    if [[ -z ${!var} ]]; then
      log "Error: Missing environment variable $var" >&2
      missing=true
    fi
  done
  $missing && exit 1
}

# Function to set chain id and RPC URL
set_chain_rpc() {
  case $1 in
  101)
    CHAIN_ID=1
    RPC_URL=$ETH_MAINNET_RPC_URL
    ;;
  102)
    CHAIN_ID=56
    RPC_URL=$BSC_MAINNET_RPC_URL
    ;;
  106)
    CHAIN_ID=43114
    RPC_URL=$AVALANCHE_RPC_URL
    ;;
  109)
    CHAIN_ID=137
    RPC_URL=$POLYGON_MAINNET_RPC_URL
    ;;
  110)
    CHAIN_ID=42161
    RPC_URL=$ARBITRUM_MAINNET_RPC_URL
    ;;
  111)
    CHAIN_ID=10
    RPC_URL=$OPTIMISM_RPC_URL
    ;;
  *)
    log "Error: Invalid id - $1"
    exit 1
    ;;
  esac
}

main() {
  while getopts ":hdf:" opt; do
    case ${opt} in
    h)
      display_help
      ;;
    f)
      file=$OPTARG
      ;;
    d)
      DRY_RUN=true
      ;;
    \?)
      log "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    esac
  done

  validate_env

  # If no file is specified, use the default
  if [[ -z $file ]]; then
    file=$DEFAULT_FILE
  fi

  if [[ ! -r $file ]]; then
    log "Error: File $file not found or not readable" >&2
    exit 1
  fi

  lzIds=($(dasel select -r json -p "$file" -m '.keys' -p))
  ofts=($(dasel select -r json -p "$file" -m '.values' -p))

  for ((i = 0; i < ${#lzIds[@]}; i++)); do
    id=${lzIds[i]}
    oft=${ofts[i]}
    log "Processing id $id, oft $oft"

    set_chain_rpc $id

    log "CHAIN_ID $CHAIN_ID, RPC_URL $RPC_URL"

    ids=("${lzIds[@]}")
    unset "ids[$i]"
    ids=$(
      IFS=,
      echo "[${ids[*]}]"
    )

    addresses=("${ofts[@]}")
    unset "addresses[$i]"
    addresses=$(
      IFS=,
      echo "[${addresses[*]}]"
    )

    args="2 $oft $ids $addresses"
    log "args $args"

    if $DRY_RUN; then
      echo "Dry run: forge script script/WireUpOFT.s.sol:WireUpOFTScript --sig \"run(uint16,address,uint16[],address[])\" $args --chain-id $CHAIN_ID --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvvv"
    else
      forge script script/WireUpOFT.s.sol:WireUpOFTScript \
        --sig "run(uint16,address,uint16[],address[])" $args \
        --chain-id $CHAIN_ID \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        -vvvvv
    fi
  done
}

# Call the main function
main "$@"
