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
