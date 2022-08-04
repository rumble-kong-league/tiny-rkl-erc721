// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/test/RookiesTest.sol";

contract RookiesClaimTests is Test {
    address MINTER = 0x0000000000000000000000000000000000000001;
    address ALICE = 0x0000000000000000000000000000000000000002;
    address BOB = 0x0000000000000000000000000000000000000003;
    uint256 MAX_ROOKIES_SUPPLY = 50;

}
// TODO: test claim expired
// TODO: test claiming
