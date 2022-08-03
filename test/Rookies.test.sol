// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/test/RookiesTest.sol";


contract RookiesTests is Test {

    address MINTER = 0x0000000000000000000000000000000000000001;
    uint256 MAX_ROOKIES_SUPPLY = 50;

    function mintRookies(uint256 qty) public {
        vm.startPrank(MINTER, MINTER);

        RookiesTest rookies = new RookiesTest();
        if (qty > MAX_ROOKIES_SUPPLY) {
            vm.expectRevert("Exceeds max supply");
        }
        rookies.mint(qty);

        if (qty <= MAX_ROOKIES_SUPPLY) {
            assert(rookies.totalSupply() == qty);
        }
    }

    function testMint() public {
        mintRookies(MAX_ROOKIES_SUPPLY);
    }

    function testExceedsMaxSupplyMint() public {
        mintRookies(MAX_ROOKIES_SUPPLY + 1);
    }

}
