#!/usr/bin/env bash
# Path of the script folder (so that the script can be invoked from somewhere else than the project's root)
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
# Execute in the context of the project's root
pushd $SCRIPT_DIR/../.. >/dev/null

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
nc='\033[0m'

# Function to display error message and exit
errorAndExit() {
    printf "${red}$1${nc}\n"
    exit 1
}

# ---------------------------------------------------------------------------- #
#                             Compilation Step                                 #
# ---------------------------------------------------------------------------- #

printf "${blue}Compiling contracts...${nc}\n"
if forge build src; then
    printf "${green}Contracts compiled successfully.${nc}\n"
else
    errorAndExit "Error: Contract compilation failed."
fi

# ---------------------------------------------------------------------------- #
#                                  Deployment                                  #
# ---------------------------------------------------------------------------- #

set -e

# RPC endpoint URLs
URL_ETH_MAINNET="https://eth.drpc.org"
URL_ARBITRUM="https://arbitrum.rpc.subquery.network/public"
URL_BASE="https://base.llamarpc.com"
URL_POLYGON="https://polygon.drpc.org"
URL_BNB="https://bsc.blockrazor.xyz"

echo "🚀 Starting Spro deployment on all chains..."
echo "=============================================="

echo ""
echo "📡 Deploying on Ethereum Mainnet..."
forge script script/SproMainnet.s.sol:Deploy -f "$URL_ETH_MAINNET" --broadcast --verify -vvvv --interactives 1

echo ""
echo "📡 Deploying on Arbitrum Sepolia..."
forge script script/SproArbitrum.s.sol:Deploy -f "$URL_ARBITRUM" --broadcast --verify -vvvv --interactives 1

echo ""
echo "📡 Deploying on Base Sepolia..."
forge script script/SproBase.s.sol:Deploy -f "$URL_BASE" --broadcast --verify -vvvv --interactives 1

echo ""
echo "📡 Deploying on Polygon Amoy..."
forge script script/SproPolygon.s.sol:Deploy -f "$URL_POLYGON" --broadcast --verify -vvvv --interactives 1

echo ""
echo "📡 Deploying on BSC Testnet..."
forge script script/SproBnb.s.sol:Deploy -f "$URL_BNB" --broadcast --verify -vvvv --interactives 1

echo ""
echo "✅ Deployment completed on all chains!"
echo "======================================"
