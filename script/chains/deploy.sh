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

# RPC endpoint URLs
URL_ARBITRUM="https://arbitrum.gateway.tenderly.co"
URL_BASE="https://base.llamarpc.com"
URL_POLYGON="https://polygon.gateway.tenderly.co"
URL_BSC="https://bsc-rpc.publicnode.com"

printf "🚀 Starting Spro deployment on all chains...\n"
printf "==============================================\n"

failed_chains=""

printf "\n"
printf "📡 Deploying on Arbitrum...\n"
if forge script ./script/chains/SproArbitrum.s.sol:DeployArbitrum -s "run()" -f "$URL_ARBITRUM" --broadcast --verify --slow --private-key $privateKey; then
    printf "${green}✅ Arbitrum deployment successful!${nc}\n"
else
    printf "${red}❌ Arbitrum deployment failed!${nc}\n"
    failed_chains="$failed_chains Arbitrum"
fi

printf "\n"
printf "📡 Deploying on Base...\n"
if forge script ./script/chains/SproBase.s.sol:DeployBase -s "run()" -f "$URL_BASE" --broadcast --verify --slow --private-key $privateKey; then
    printf "${green}✅ Base deployment successful!${nc}\n"
else
    printf "${red}❌ Base deployment failed!${nc}\n"
    failed_chains="$failed_chains Base"
fi

printf "\n"
printf "📡 Deploying on Polygon...\n"
if forge script ./script/chains/SproPolygon.s.sol:DeployPolygon -s "run()" -f "$URL_POLYGON" --broadcast --verify --slow --private-key $privateKey; then
    printf "${green}✅ Polygon deployment successful!${nc}\n"
else
    printf "${red}❌ Polygon deployment failed!${nc}\n"
    failed_chains="$failed_chains Polygon"
fi

printf "\n"
printf "📡 Deploying on BSC...\n"
if forge script ./script/chains/SproBsc.s.sol:DeployBsc -s "run()" -f "$URL_BSC" --broadcast --verify --slow --private-key $privateKey; then
    printf "${green}✅ BSC deployment successful!${nc}\n"
else
    printf "${red}❌ BSC deployment failed!${nc}\n"
    failed_chains="$failed_chains BSC"
fi

printf "\n"
printf "==============================================\n"
if [ "$failed_chains" = "" ]; then
    printf "${green}✅ All deployments completed successfully!${nc}\n"
else
    printf "${red}❌ Deployment completed with errors!${nc}\n"
    printf "${red}Failed chains:$failed_chains${nc}\n"
    exit 1
fi
