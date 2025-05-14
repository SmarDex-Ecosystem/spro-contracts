# <h1 align="center">P2P_Lending_contracts</h1>

[![Main workflow](https://github.com/SmarDex-Ecosystem/SPRO_contracts/actions/workflows/ci.yml/badge.svg)](https://github.com/SmarDex-Ecosystem/SPRO_contracts/actions/workflows/ci.yml)
[![Release Workflow](https://github.com/SmarDex-Ecosystem/SPRO_contracts/actions/workflows/release.yml/badge.svg)](https://github.com/SmarDex-Ecosystem/SPRO_contracts/actions/workflows/release.yml)

# SmarDex fork of PWN Protocol

This SMARDEX P2P Lending Protocol enables the use of arbitrary ERC-20 tokens as collateral. It is designed to provide a secure, flexible, and decentralized approach to on-chain lending.

Key features and custom logic include:

- Fees are collected in SDEX tokens and are burned, without modifying the loan or borrow amounts.
- All proposals must be created on-chain.
- Borrowers must transfer collateral to the vault when creating a loan request.
- Lenders cannot initiate lending proposals; they can only match existing on-chain borrow requests.
- A borrow request can be partially funded by multiple lenders, up to the specified borrow amount.
- Partial funding requires a minimum threshold: a lender must contribute at least x% of the requested amount.
- All lenders participating in the same loan share a unified loan expiration date.

note: "P2P_Lending" is the new name for the protocol previously referred to as "SPRO". The core functionality remains unchanged. Please note that the smart contracts and tests still use the original name "SPRO" in their naming and structure.

## Installation

### Foundry

To install Foundry, run the following commands in your terminal:

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

### Dependencies

To install existing dependencies, run the following commands:

```bash
forge soldeer install
npm install
```

The `forge soldeer install` command is only used to add libraries for the smart contracts. Other dependencies should be managed with
npm.

In order to add a new dependency, use the `forge soldeer install [packagename]~[version]` command with any package from the
[soldeer registry](https://soldeer.xyz/).

For instance, to add [OpenZeppelin library](https://github.com/OpenZeppelin/openzeppelin-contracts) version 5.0.2:

```bash
forge soldeer install @openzeppelin-contracts~5.0.2
```

The last step is to update the remappings array in the `foundry.toml` config file.

### Nix

If using [`nix`](https://nixos.org/), the repository provides a development shell in the form of a flake.

The devshell can be activated with the `nix develop` command.

To automatically activate the dev shell when opening the workspace, install [`direnv`](https://direnv.net/)
(available on nixpkgs) and run the following command inside this folder:

```console
$ direnv allow
```

The environment provides the following tools:

- load `.env` file as environment variables
- foundry
- solc v0.8.26
- lcov
- Node 20 + Typescript
- Rust toolchain
- `test_utils` dependencies

## Usage

### Tests

To run tests, use `forge test -vvv` or `npm run test`.

### Snapshots

The CI checks that there was no unintended regression in gas usage. To do so, it relies on the `.gas-snapshot` file
which records gas usage for all tests. When tests have changed, a new snapshot should be generated with the
`npm run snapshot` command and commited to the repo.

### Deployment scripts

## Foundry Documentation

For comprehensive details on Foundry, refer to the [Foundry book](https://book.getfoundry.sh/).

### Helpful Resources

- [Forge Cheat Codes](https://book.getfoundry.sh/cheatcodes/)
- [Forge Commands](https://book.getfoundry.sh/reference/forge/)
- [Cast Commands](https://book.getfoundry.sh/reference/cast/)

## Code Standards and Tools

### Forge Formatter

Foundry comes with a built-in code formatter that we configured like this (default values were omitted):

```toml
[profile.default.fmt]
line_length = 120 # Max line length
bracket_spacing = true # Spacing the brackets in the code
wrap_comments = true # use max line length for comments as well
number_underscore = "thousands" # add underscore separators in large numbers
```

### Husky

The pre-commit configuration for Husky runs `forge fmt --check` to check the code formatting before each commit. It also
checks the gas snapshot and prevents committing if it has changed.

In order to setup the git pre-commit hook, run `npm install`.

## Scripts

### Deploy protocol

For a mainnet deployment, you can use the `Spro.s.sol` script with:

```bash
forge script -f RPC_URL script/Spro.s.sol --broadcast -i 1
```

You can use `-t` or `-l` options instead of `-i 1` for trezor or ledger hardware wallet.