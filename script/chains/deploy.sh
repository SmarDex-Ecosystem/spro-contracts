#!/usr/bin/env bash
# Path of the script folder (so that the script can be invoked from somewhere else than the project's root)
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
# Execute in the context of the project's root
pushd $SCRIPT_DIR/../.. >/dev/null

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
nc='\033[0m'

# ---------------------------------------------------------------------------- #
#                             Compilation Step                                 #
# ---------------------------------------------------------------------------- #

printf "${blue}Compiling contracts...${nc}\n"
if forge build src; then
    printf "${green}Contracts compiled successfully.${nc}\n"
else
    printf "${red}Error: Contract compilation failed.${nc}\n"
fi

# ---------------------------------------------------------------------------- #
#                                  Deployment                                  #
# ---------------------------------------------------------------------------- #

set -e

read -s -p $'\n'"Enter the private key : " privateKey
deployerPrivateKey=$privateKey

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
forge script ./script/chains/SproMainnet.s.sol:Deploy -f "$URL_ETH_MAINNET" --broadcast --verify --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on Arbitrum..."
forge script ./script/chains/SproArbitrum.s.sol:Deploy -f "$URL_ARBITRUM" --broadcast --verify --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on Base..."
forge script ./script/chains/SproBase.s.sol:Deploy -f "$URL_BASE" --broadcast --verify --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on Polygon..."
forge script ./script/chains/SproPolygon.s.sol:Deploy -f "$URL_POLYGON" --broadcast --verify --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on BSC..."
forge script ./script/chains/SproBnb.s.sol:Deploy -f "$URL_BNB" --broadcast --verify --private-key $deployerPrivateKey

echo ""
echo "✅ Deployment completed on all chains!"
echo "======================================"
