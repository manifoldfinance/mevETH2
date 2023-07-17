#!/bin/bash

set -euxo pipefail

# Define a log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - deployer | $1"
}

# Function to display help
display_help() {
  echo "Usage: $0 [network] [option...]" >&2
  echo
  echo "   network               Specify the network: MAINNET, GOERLI, AVALANCHE etc."
  echo
  echo "   Optional arguments:"
  echo "   -a,  action           Specify the action to perform: Deploy, DeployOFT"
  echo "   -c,  chain-id         Specify the chain-id environment variable name"
  echo "   -r,  rpc-url          Specify the rpc-url environment variable name"
  echo "   -e,  etherscan-api    Specify the etherscan-api environment variable name"
  echo
  exit 1
}

main() {
  # Load the configuration file
  if [ -f config.json ]; then
    NETWORK=$1
    shift # Shift command-line arguments to ignore the first one (network) in the upcoming getopts

    ACTION=$(dasel select -p json ".$NETWORK.ACTION" <config.json)
    CHAIN_ID=$(dasel select -p json ".$NETWORK.CHAIN_ID" <config.json)
    RPC_ENDPOINT=$(dasel select -p json ".$NETWORK.RPC_ENDPOINT" <config.json)
    ETHERSCAN_API_KEY=$(dasel select -p json ".$NETWORK.ETHERSCAN_API_KEY" <config.json)
    EXTRA_FOUNDRY_ARGS=$(dasel select -p json ".$NETWORK.EXTRA_FOUNDRY_ARGS" <config.json)
  else
    log "Configuration file (config.json) not found!"
    exit 1
  fi

  # Decrypt the private key using Sops
  PRIVATE_KEY=$(sops -d --input-type yaml --output-type json keys.yaml | dasel select -p json ".keys.${CHAIN_ID}")

  # Check if mandatory parameters are empty
  if [ -z "$CHAIN_ID" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$RPC_ENDPOINT" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
    log "One or more mandatory parameters are not set in the configuration file!"
    exit 1
  fi

  # Parse command-line arguments
  while getopts ":a:c:r:e:" opt; do
    case $opt in
    a) ACTION=$OPTARG ;;
    c) CHAIN_ID=$(dasel select -p json ".$NETWORK.$OPTARG" <config.json) ;;
    r) RPC_URL=$(dasel select -p json ".$NETWORK.$OPTARG" <config.json) ;;
    e) ETHERSCAN_API_KEY=$(dasel select -p json ".$NETWORK.$OPTARG" <config.json) ;;
    \?)
      echo "Invalid option -$OPTARG" >&2
      display_help
      ;;
    esac
  done

  # Validate the provided options
  if [ -z "$ACTION" ] || [ -z "$CHAIN_ID" ] || [ -z "$RPC_URL" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
    log "One or more required options are missing!"
    display_help
  fi

  # Call the Forge script with the appropriate parameters
  log "Starting the $ACTION script with chain-id $CHAIN_ID..."
  forge script $PRJ_ROOT/script/${ACTION}.s.sol:${ACTION}Script \
    --chain-id $CHAIN_ID \
    --rpc-url $RPC_URL \
    --broadcast \
    --private-key $PRIVATE_KEY \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvvv \
    $EXTRA_FOUNDRY_ARGS
  log "$ACTION script completed."
}

main "$@"
