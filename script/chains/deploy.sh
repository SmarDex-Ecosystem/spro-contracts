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
#                                  Deployment                                  #
# ---------------------------------------------------------------------------- #

read -s -p $'\n'"Enter the private key : " privateKey
deployerPrivateKey=$privateKey

# RPC endpoint URLs
URL_ARBITRUM="https://arbitrum.gateway.tenderly.co"
URL_BASE="https://base.llamarpc.com"
URL_POLYGON="https://polygon.gateway.tenderly.co"
URL_BSC="https://binance.llamarpc.com"

echo "🚀 Starting Spro deployment on all chains..."
echo "=============================================="

echo ""
echo "📡 Deploying on Arbitrum..."
forge script ./script/chains/SproArbitrum.s.sol:DeployArbitrum -s "run()" -f "$URL_ARBITRUM" --broadcast --verify --slow --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on Base..."
forge script ./script/chains/SproBase.s.sol:DeployBase -s "run()" -f "$URL_BASE" --broadcast --verify --slow --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on Polygon..."
forge script ./script/chains/SproPolygon.s.sol:DeployPolygon -s "run()" -f "$URL_POLYGON" --broadcast --verify --slow --private-key $deployerPrivateKey

echo ""
echo "📡 Deploying on BSC..."
forge script ./script/chains/SproBsc.s.sol:DeployBsc -s "run()" -f "$URL_BSC" --broadcast --verify --slow --private-key $deployerPrivateKey

echo ""
echo "✅ Deployment completed on all chains!"
echo "======================================"
