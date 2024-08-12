# SmarDex fork of PWN Protocol

PWN is a protocol that enables peer-to-peer (P2P) loans using arbitrary collateral. PWN smart contracts support ERC20, ERC721, and ERC1155 standards, making it versatile and adaptable to a wide range of use cases.

Key changes made in this fork include:

- Fees are now taken in the SDEX token, no modification is made to the loan/borrow amount.
- Thresholds added to the partial lending feature which does not allow a lender to match with less than 5% of the requested borrow amount.
- Domain separators updated to ensure no permit reuse with the base PWN protocol is possible.
- A `Sink` trivial contract is prepared to serve as a token burn address.

## Change Details

### Setting fees

Fees are controlled from the `SDConfig` contract, by the contract owner.

A user must have made an SDEX approval of the appropriate amount to the `SDSimpleLoan` contract prior to transacting.

The fixed fee for listed tokens, `listedFee`, and the fixed fee for unlisted tokens, `unlistedFee`, are both in terms of units of SDEX tokens. For example to charge a 1 SDEX fee for unlisted tokens, the owner calls `setUnlistedFee` with an input value of `1000000000000000000` (1e18 units).

A token is implicitly unlisted if a `tokenFactors` value is not set for it.

The variable component of the fee is contained in two quantities, the `variableFactor` conversion quantity, and the `tokenFactors` token-specific quantity. Both of these quantities use 18 decimal precision (1e18 = 1).

The example given in the specification is that if a user wants to borrow 250 ETH, the factor of ETH is 4000, the
VariableFactor is 0.00001 and FixFeeListed = 5 we will have
𝑇𝑜𝑡𝑎𝑙 𝑓𝑒𝑒𝑠 = 𝐹𝑖𝑥𝐹𝑒𝑒𝐿𝑖𝑠𝑡𝑒𝑑 + 𝑉𝑎𝑟𝑖𝑎𝑏𝑙𝑒𝐹𝑎𝑐𝑡𝑜𝑟 ∗ 𝑡𝑜𝑘𝑒𝑛𝐹𝑎𝑐𝑡𝑜𝑟 ∗ 𝑞𝑢𝑎𝑛𝑡𝑖𝑡𝑦
𝑇𝑜𝑡𝑎𝑙 𝑓𝑒𝑒𝑠 = 5 + 0.00001 ∗ 4000 ∗ 250 = 15

The parameters for this works out as follows:

```
listedFee = 5000000000000000000                 // 5 SDEX
variableFactor = 10000000000000                 // 0.00001 * 10**18
ETH borrow amount = 250000000000000000000       // 250 ETH
tokenFactors[WETH] = 4000000000000000000000     // 4000 * 10**18

RESULT: 5000000000000000000 + 10000000000000 * 250000000000000000000 * 4000000000000000000000 / 1e36
        = 5000000000000000000 + 10000000000000000000
        = 15000000000000000000 // 15 SDEX
```

An alternative example using USDC (6 decimals):

```
listedFee = 5000000000000000000                         // 5 SDEX
variableFactor = 10000000000000                         // 0.00001 * 10**18
USDC borrow amount = 1000000000000                      // 1 million USDC
tokenFactors[WETH] = 1000000000000000000000000000000    // 1 * 10**30

RESULT: 5000000000000000000 + 10000000000000 * 1000000000000 * 1e30 / 1e36
        = 5000000000000000000 + 10000000000000000000
        = 15000000000000000000 // 15 SDEX
```

In this case, the desired token factor of 1, which wad-formats to 1e18, is multiplied by 1e12 to account for the decimal difference between USDC and ETH. If a token was used which had more than 18 decimals, the token factor would have to be adjusted down in a similar fashion.

## Deployment

Deployed addresses are read to and written from `deployments/sdLatest.json`. Deployment takes place in the following steps:

1. Populate the configuration parameters. The initial fee and factor settings must be set in `SD.s.sol`. To prepare for deployment, the following fields must be set in the desired chain in `sdLatest.json`. The rest are contracts which will be deployed as part of the protocol deployment step.
   1. `proxyAdmin` - proxy admin address
   2. `protocolAdmin`- protocol admin address
   3. `sdex` - SDEX token on the chain
2. Deploy the deployer contract.
3. Execute the deployment script.
4. Protocol admin accepts ownership of the SDHub and SDConfig contracts.
5. Protocol admin sets Hub tags.
   1. SimpleLoan receives ACTIVE_LOAN, NONCE_MANAGER
   2. SimpleLoanSimpleProposal receives LOAN_PROPOSAL, NONCE_MANAGER
   3. View the `SDSetTags.s.sol` script file for example call.

```sh
# Deploy the deployer
$ forge script script/SDDeployer.s.sol:Deploy -vvvvv --sig "deployDeployer()" --rpc-url $<target_chain> --private-key $PRIVATE_KEY --broadcast

# Then, run the following to deploy the protocol:
$ forge script script/SD.s.sol:Deploy -vvvvv --sig "deployProtocol()" --rpc-url $<target_chain> --private-key $PRIVATE_KEY --broadcast
```

### Local deployment

To deploy a test copy locally:

```sh
# Start local node
$ anvil

# In different terminal
$ forge script script/SDDeployer.s.sol:Deploy -vvvvv --sig "deployDeployer()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast
$ forge script script/SDDeployer.s.sol:Deploy -vvvvv --sig "deploySDEX()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast

# Then, run the following to deploy the protocol:
$ forge script script/SD.s.sol:Deploy -vvvvv --sig "deployProtocol()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast

# Accept the ownership transfer (adjust if private key is not set as local admin)
$ cast send <address> "acceptOwnership()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY

# Set tags via utility script
$ forge script script/SDSetTags.s.sol:SDSetTags -vvvvv --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast
```

## PWN Developer Documentation

You can find in-depth information about the base smart contracts and their usage in the [PWN Developer Docs](https://dev-docs.pwn.xyz/).
