# Optimised ERC721 implemention

Based on Citizens of Tajigen's [implementation](https://mirror.xyz/tajigen.eth/fraoPkDEYf1U5yOmke3SdFny5EnA6fZwiupaWMX3Yeg).

Our personal tests showed the above contract to be superior among all the implementations we were aware of:
https://twitter.com/AlgorithmicBot/status/1552722851345702913

## Dev

To generate coverage report run

`forge coverage --report lcov && genhtml lcov.info -o report --branch-coverage`

To run the tests run

`forge test`

There is also an argument for different levels of verbosity:

`forge test -v`

All the way up to `-vvvvv`

## Goerli Test Deploy

Rumble Kong League OG stub collection deployed at: `0xfC01aE2764Ca9CD8ABbf10aBf430Ca4661AEAcd9`. You can arbitrarily mint kongs with the following function `mint(address to, uint256 qty)`.

Test Rookies Claim contract was deployed to: `0xaBb95Abfb3D79DAF27558E5Aff8bf714922bA8dB`.
