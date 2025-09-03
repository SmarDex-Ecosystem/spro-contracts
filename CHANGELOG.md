# Changelog

## [1.1.0](https://github.com/SmarDex-Ecosystem/spro-contracts/compare/v1.0.0...v1.1.0) (2025-09-03)


### Features

* add deployment script for other chains ([#126](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/126)) ([45658db](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/45658dbc2fa538f9780543790a854e997f154e7e))
* release 0.2.1 with fixed addresses ([#128](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/128)) ([34ed25d](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/34ed25d6a51d0edb7b7e67565d5748030db8a56c))


### Bug Fixes

* add package.json entrypoint ([#124](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/124)) ([176243f](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/176243fe104dd6427e97aabf6da546622d3a048b))

## [1.0.0](https://github.com/SmarDex-Ecosystem/spro-contracts/compare/v0.2.0...v1.0.0) (2025-05-22)


### Features

* change naming ([#117](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/117)) ([e9424df](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/e9424df3c9ceea2bce2b1d02b8e35ba53d55be13))
* clean interface ([#114](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/114)) ([7cb009f](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/7cb009facbc6a9a13fd584f8e8aa38b37aa2ac00))
* move nftrenderer in an external contract ([#112](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/112)) ([516dded](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/516dded408cc166eb059db6ed51425dad5c90d36))
* release 1.0 ([#120](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/120)) ([4a684cc](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/4a684ccdd506cab3662b1dd9af9a446abeadef83))
* simplify deployment ([#105](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/105)) ([fd3b511](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/fd3b5113e5bc4490da1ff5f533a5729069d80ee1))
* use directly safe wallet to be the owner ([#107](https://github.com/SmarDex-Ecosystem/spro-contracts/issues/107)) ([1cb7b48](https://github.com/SmarDex-Ecosystem/spro-contracts/commit/1cb7b489a5b6125d099a9b033230100776c84271))

## [0.2.0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/compare/v0.1.4...v0.2.0) (2025-04-10)


### ⚠ BREAKING CHANGES

* event updated
* events

### Features

* improving events ([#88](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/88)) ([02c8aab](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/02c8aab3ed3891623ac2500b95ebb6b1eba3a36c))
* nft svg rendering ([#89](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/89)) ([668f0d0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/668f0d0151fa0d6cad0fbd18b293483606f13ba5))


### Bug Fixes

* build and tests ([#93](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/93)) ([644d1ec](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/644d1ec91cbf2c9330331713d18af7b5767171b3))


### Performance Improvements

* remove unused events ([#92](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/92)) ([bee7cbb](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/bee7cbbed62b75341fc3f53a6b1b70aac194154b))

## [0.1.4](https://github.com/SmarDex-Ecosystem/SPRO_contracts/compare/v0.1.3...v0.1.4) (2025-03-28)


### Features

* **_makeProposal:** reverts when the start timestamp is in the past ([#77](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/77)) ([dd45d4a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/dd45d4a81abeec68b70b5845114f19d0b491add4))
* add check on erc20 transfer ([#82](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/82)) ([a0ff54c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/a0ff54cc4b779c22de622b7ee83fa1d4e5a9cfcd))
* add reentrancy protection ([#80](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/80)) ([f87b985](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f87b98511f1627086043af1d906b9ca39a8b7e29))
* adding fee check in constructor ([#72](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/72)) ([74beb00](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/74beb0085903b3a3987584f6d91eff105b6ac7d1))
* adding recipient in repay function ([#76](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/76)) ([0cb109d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/0cb109df776050d60fb0229c8969d1447f547801))
* **createProposal:** add a nonce for proposals ([#79](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/79)) ([5078edd](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/5078edd0643836195599f92d08a2e4e5a9e9272f))
* improving clarity ([#70](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/70)) ([d6e3532](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/d6e35320654e1907f0fb1e38bcaf0d0c55382491))
* improving totalLoanRepaymentAmount ([#85](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/85)) ([3edde85](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/3edde85056b793901e7d3aa12c8ec9872ae1a307))
* pre calculation of minAmount ([#81](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/81)) ([9bd3ebd](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/9bd3ebd3a2cc3baf6e19dd94bd08b310b9c83f8a))
* prevent permit2 griefing ([#83](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/83)) ([70f52b1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/70f52b1a31bbf16a2bad6f2819e0afaf216a1c66))
* revert if try to cancel a non existent proposal ([#75](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/75)) ([5891377](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/5891377292b5f3e8af82cfca206587ab5413477d))
* **SproLoan:** remove safemint ([#74](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/74)) ([21f7f88](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/21f7f88a297d4c9f55c67e04586b582c38da2ddc))


### Bug Fixes

* permit2 transfer ([#78](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/78)) ([aab3ffa](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/aab3ffa99d38c4de07b3cfe63a3dd39cdd295012))
* **totalLoanRepaymentAmount:** continue instead of returning when loan status is none ([#73](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/73)) ([965bfdd](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/965bfdd7f63475b4a79babb9b6a50e0e05dc4e12))


### Performance Improvements

* **_acceptProposal:** merge both functions ([#86](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/86)) ([38615ea](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/38615ea6d61774bca4583cde706768778ed2d355))

## [0.1.3](https://github.com/SmarDex-Ecosystem/SPRO_contracts/compare/v0.1.2...v0.1.3) (2025-03-13)


### Features

* add an equal on a check ([#27](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/27)) ([b9f5ef4](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/b9f5ef4c92a8e10670a84765b29d16c23da4ac31))
* adding nonReentrant guard ([#26](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/26)) ([8c3f12f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8c3f12f949be56886103f06df6b468891591507f))
* improve and add event ([#42](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/42)) ([2e55d36](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/2e55d36461ef0bb64837c73e80a3bc057873da2e))
* incorporate partialPositionBps in proposal struct during proposal creation ([#24](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/24)) ([a8465d1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/a8465d1b095a6355e1140a1a674d5f34f863c2c2))
* remove _getLoanStatus function ([#65](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/65)) ([b04675f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/b04675f0b740f41768f9f8331f855bc6bdf82290))
* remove metadataUri mapping and improve logic ([#43](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/43)) ([492b820](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/492b820270ecefb1fa7d4e836e28dcda259a445c))
* remove permit ([#36](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/36)) ([f1f7492](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f1f74929f58c99a6b2ac2c5e2d9e63e7afdf1df8))
* remove pool adapter functionality ([#35](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/35)) ([15d9342](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/15d93427702be4a072510be6b8a74f13bd5f2004))
* remove unnecessary returns variables ([#67](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/67)) ([c422df5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c422df548a8896943a4038ddc0f49553fdc1dfab))
* removing unnecessary code ([#51](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/51)) ([450138e](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/450138ea7720d7581fdada8189f5b99c47688623))
* simplify _checkLoanCanBeRepaid ([#25](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/25)) ([cf3942c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/cf3942c0becf476ad834a745b329cd3c43220247))
* simplify getter ([#60](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/60)) ([0c22287](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/0c22287ff46a12d83bba3c0403c428349c45a262))
* **SproLoan:** use _safeMint() ([#68](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/68)) ([bac190d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/bac190d1d325a7b05758b456e00d156dde47c091))
* use DEAD_ADDRESS ([#57](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/57)) ([38c22f1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/38c22f14c8941fab2cd4f079bdd3236cdcd1928d))
* use permissive solidity version for interfaces ([#41](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/41)) ([26a07e9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/26a07e92c048340ef47c0027b9a70588ebf22b90))
* use revert instead of require ([#34](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/34)) ([9944aea](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/9944aea79856eb87c52e8c5e07a325f101c450ed))


### Bug Fixes

* ci with lintspec and natspec fix ([#64](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/64)) ([d12461d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/d12461d05571ec52ea9e3fcea9cb3d96e6f288f2))
* maximum credit ([#40](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/40)) ([19649d7](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/19649d7735870ea06493d05230aab50330ca5c2b))
* repayMultipleLoans against griefing ([#38](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/38)) ([538a13a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/538a13a47ee0998a98b6177ca5b66130da59a72f))


### Performance Improvements

* reduce gas cost in claimLoan ([#62](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/62)) ([caa77c6](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/caa77c6f07edcee1af6d240912f2755d264348ca))
* remove unused variable ([#33](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/33)) ([cb69faf](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/cb69fafae125205ba15921a788c3bec9c03f4417))

## [0.1.2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/compare/v0.1.1...v0.1.2) (2025-02-25)


### Features

* add all interfaces ([682b454](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/682b454be0f0a3b5338fc8f39904fd430d384448))
* add interfaces ([11560b4](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/11560b4f8044a460d3c69e3ffe9d9da1c35a7c32))
* add ISproLOAN ([c61a42f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c61a42f4ed1ee5a7032fe0d09fc697bfffabf004))
* add ISproStorage ([e6e474b](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/e6e474bf16babf2dfee16298e91e8e21ae6b671f))
* add max set fee ([#19](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/19)) ([f37335d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f37335d67004f79020cce49af5b7467236fe15bd))
* add pool adapter in loan ([#29](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/29)) ([b51487d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/b51487de7498aefb2eb33e1ad399e6ae93ef8ecb))
* change visibility function ([6cae5c2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/6cae5c25453455383438c2d99d09d767a93ea5f4))
* fix fees logic ([#16](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/16)) ([818b6a2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/818b6a269c61c885c2b760c292e2b63b26272344))
* fix fingerprint ([3d46cc0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/3d46cc08c168c58c3664ba85d7c80db1fbd4b2c2))
* merge pull request [#12](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/12) from SmarDex-Ecosystem/feature/remove-fingerprint ([c3e785f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c3e785f49e7d49a2617838d7a0c5f748f41e22e6))
* merge pull request [#13](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/13) from SmarDex-Ecosystem/feature/add-interfaces ([11560b4](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/11560b4f8044a460d3c69e3ffe9d9da1c35a7c32))
* move availableCreditLimit check ([d60b918](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/d60b91879b6338b593d9296f637236dfcaa38cf7))
* move availableCreditLimit check ([#20](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/20)) ([64b1136](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/64b1136a7aba1e916aecb0e1b03852174bedd689))
* move loanTerms checks in proposal creation ([#23](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/23)) ([6e659f5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/6e659f5ee7d26c2b1764017c348dbd987274fe05))
* remove  _pull ([93888cb](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/93888cbc2e81accbd17921461168f5f0d3a2bfee))
* remove _checkCompleteLoan ([#22](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/22)) ([29caf7f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/29caf7f5d13325f2af3f34412091ad28ad09d62c))
* remove deployments ([f1aceaf](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f1aceaf544f9372eb6e12acea5777338d3954a1c))
* remove domain and typehash ([#18](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/18)) ([bad440b](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/bad440b19c11944b3f3cb4f67778517a9662f109))
* remove encode and decode ([c836808](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c836808388896782a233021558a167afa6405981))
* remove fingerprint ([c3e785f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c3e785f49e7d49a2617838d7a0c5f748f41e22e6))
* remove fingerprint ([795492c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/795492c91378743fb09779c91d3804028acdcec3))
* remove IPWNDeployer ([69aa24a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/69aa24a03e7b11e5ada10eba6a16b88fc6e0a6bf))
* remove library ([51cf363](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/51cf363493defdcbbdd8eb35de53964251703d88))
* remove LOAN caps ([86c79c5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/86c79c5f91032be670a2559d3827550b28dce059))
* remove nonce ([#15](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/15)) ([851ee23](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/851ee23956fa57d74057390a047c97a540d6b394))
* remove pool check ([8b86ac9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8b86ac9f161e6c35dcb3e2d7470e9ec9defd291c))
* remove private ([3671522](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/3671522a686fed393e8ddcf0d98638277e1b0950))
* remove storage to memory ([2ff5846](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/2ff5846bd1d5b16b63e1bd617d9087a97928f31a))
* remove unused file ([14c3a1c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/14c3a1c17a8924eb45d13ee41f4ce7881b7f662f))
* remove unused file ([1c21baa](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/1c21baaa8078bf95422306b8be9c82ec89fcc65e))
* remove unused function ([239c488](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/239c4888bf1593664a30dfbd468bb55ff8360c4a))
* remove unused import ([bd9ab15](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/bd9ab15332b9ecf27ce8d7981fa5ccc4eba94f09))
* remove version ([ff8c1ad](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/ff8c1ad27f47e8732aebdef71ebff1b32c29225f))
* rename loanExpiration ([91567e8](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/91567e8062bc17229890b56e2a1a4699a886f995))
* rename with bps ([f378cdf](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f378cdf2c504f5d3cc5e70be166108df60343d67))
* reorder functions ([f563aa5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f563aa53a545715be6f7f6447ad6257ee2fa556c))
* return directly Proposal ([3c625f1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/3c625f189d13f7b3ec8778bab9a70d9554052312))
* simplify arguments ([82c7bc1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/82c7bc17952ac0ac6f5a523aaeebcc7a961971d3))
* simplify loan ([980e0cd](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/980e0cd900600613c7cab2a125cc927a43c91d5f))
* use directly address(0xdead) ([493e325](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/493e325913c423539e55f9efe7c5e692e7fe1819))
* use DOMAIN_SEPARATOR_PROPOSAL in parameter ([8200e9e](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8200e9e2df4dfbca9c97d6d16ea8d6fbc1741166))
* use enum for loanStatus ([25cb600](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/25cb600ed855da8c97e1621f6dbb9ccadb50828e))
* use internal function ([a275c57](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/a275c57a20248eeef2512dfb4416f0ad91a89f6c))
* use msg.sender ([597d69d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/597d69d6c21b7fcae027bff5a852ecc7ea645cfc))
* use only fixedInterestAmount by remove accruingInterestAPR ([#30](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/30)) ([ea98e11](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/ea98e11d8b612942036eba974113c7ff10913dac))
* use permit2 ([#17](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/17)) ([80b4c3c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/80b4c3cb534595e1fdc40a7da058d8ca8146ec98))
* use the return function directly instead of executing two functions to calculate interest ([#28](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/28)) ([8f3258e](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8f3258e29a0f5846002ce7b37852443d985e6e97))


### Performance Improvements

* remove unused variables ([#32](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/32)) ([68b3031](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/68b3031ffbd93fdd4cbc20b01f9ded03d0388f41))

## [0.1.1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/compare/v0.1.0...v0.1.1) (2024-10-09)


### Features

* add amount in events ([8c572d3](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8c572d3179ed70a4006b7a1a527762120b6e9d31))
* add exportAbi ([d362d6e](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/d362d6eea2068ac831a3fb1a9febc1668f8f6815))
* add feature and tests ([6ef62fc](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/6ef62fc2ff8dbdc2c537a770bf446ee021ee6706))
* add natspec ([566572c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/566572cf74d87c399e15e998e139faeadd43883d))
* add natspec ([c985b8f](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c985b8faf4b9d1dc594b6e2a9c19760e242af0c4))
* add new-timeline-system ([9837946](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/98379463d5c2ab9983c5a859fb8c65480deb5b89))
* add onlyOwner on revokedNonce ([4f96df2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4f96df2406814fdad888218d07745ca5654f3fd4))
* add PWN contracts ([2cd7bc7](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/2cd7bc7b1e3fd111555c99b102384d547f3a3f64))
* add release please ([4923944](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4923944d9e51ffcf6ca1af1f9df90644cd2c9d59))
* add release please ([f34cbe8](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/f34cbe86858e7f1a25c1a7699367a93fce7043c7))
* add Rounding ([75972b5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/75972b57a17e3804bf5b1f911475fcd9131f1145))
* add script ([8a39d38](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8a39d383cf19fcff6a3e4091f30aa2f5c6a0bb9d))
* add script ([bf3a0f3](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/bf3a0f36d37d92c59f98128de2880e69b4d11585))
* add snapshot ([24d461c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/24d461c46b829c394e8f4270661223eb5bcefe14))
* add snapshot ([226b1d3](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/226b1d3b15a38a3f08577defbc3f5d02dfb9ad3c))
* change variable ([761c08a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/761c08afd7383e4bba77d14325935083137f506d))
* code provided by dev ([46effb9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/46effb9dbe86193d7fac8eb71e2720dd4590b550))
* fix loan ([d879a6a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/d879a6a53fefffa868a0b837df444cf975d84c96))
* fix merge ([63d3fe0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/63d3fe0bff6ec93e98a4d59afa233102b36c4e30))
* fix snapshot ([79f1922](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/79f1922cd7f5accf09c92c15b9675cba63b032d1))
* fix some natspec ([9975d37](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/9975d37f6abe76c935a8ee44336ab96ece165541))
* fix test ([46f6d44](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/46f6d44520a25309025397445467ddbc95bb4829))
* init template ([36b8746](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/36b87462d1342c91056901274e06d3fc8025779b))
* init template ([980a105](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/980a105da90fc7e0ee1fabaee2bc3a5f6f240e5f))
* merge contracts ([fe34bb0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/fe34bb02e30408126ffb2d437bcf19a7c1e70b9e))
* Merge pull request [#4](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/4) from SmarDex-Ecosystem/feature/use-template ([36b8746](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/36b87462d1342c91056901274e06d3fc8025779b))
* merge pull request [#5](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/5) from SmarDex-Ecosystem/feature/new-timeline-system ([9837946](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/98379463d5c2ab9983c5a859fb8c65480deb5b89))
* merge pull request [#7](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/7) from SmarDex-Ecosystem/feature/merge-contracts ([fe34bb0](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/fe34bb02e30408126ffb2d437bcf19a7c1e70b9e))
* merge pull request [#8](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/8) from SmarDex-Ecosystem/feature/add-script-file ([8a39d38](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/8a39d383cf19fcff6a3e4091f30aa2f5c6a0bb9d))
* merge pull request [#9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/issues/9) from SmarDex-Ecosystem/feature/add-release-please ([4923944](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4923944d9e51ffcf6ca1af1f9df90644cd2c9d59))
* name project ([7b436a9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/7b436a91ba695dccca30d1f249375c6eaa70492a))
* remove console ([addd9b1](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/addd9b1072bc10dd1273cc9b70e76abd002958af))
* remove copy file ([63b077c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/63b077ce199096a016783f1b141ddc7087ba7155))
* remove hub ([4dfd56d](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4dfd56df96c7e26b4ed5bd148f6f22e9394c3946))
* rename ([aa748ba](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/aa748ba7273dca133c01a001e7653be9bea09b37))
* rename ([acc43dc](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/acc43dcc75a9ead0bea9d000773665727f24d813))
* rename files ([796b399](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/796b39999bf4e8dff5ce264a8474b871bb32d5b2))
* rename package ([fe77777](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/fe7777721021218b0b7e1e4c42a329103cceaca7))
* test refacto ([4275ec9](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4275ec9ddcbf342b64deb0724403f1a184eb40ff))
* timelines and fees ([c924ba2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c924ba2c1d0c4e9d601832e7b2b75a9f08758af4))
* timelines and fees ([c924ba2](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c924ba2c1d0c4e9d601832e7b2b75a9f08758af4))
* timelines and fees ([7e16d9e](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/7e16d9e88d8ed40a894ed9029ad31f1fde6052ce))
* use constants ([253e96c](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/253e96c6010454e427a844eded74462a989c177a))
* use custom coverage ([14646ab](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/14646ab60f51266564f59a283e2407c763630344))
* use IEvent and IError ([4badc6a](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/4badc6a5c79917d24d5575c624b45ada9d9390b2))
* use same code ([aaf2587](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/aaf2587a737c55bfc22d93d016454059c09b9435))
* use type and errors ([65cda24](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/65cda24a455ae82b5dd02cde47ddf26d1789dfa5))


### Bug Fixes

* gas snapshot ([c9d4e63](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/c9d4e63a150fee89b9ab90b365cec1003da88dac))
* remove CI ([10bd583](https://github.com/SmarDex-Ecosystem/SPRO_contracts/commit/10bd583fe87c6692fea67087392f9e0755c01427))
