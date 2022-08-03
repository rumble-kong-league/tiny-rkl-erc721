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

        rookies.mint(qty);

        assert(rookies.totalSupply() == qty);
    }

    function testMint() public {
        mintRookies(MAX_ROOKIES_SUPPLY);
    }

    function testFailExceedsMaxSupplyMint() public {
        vm.expectRevert("Exceeds max supply");
        mintRookies(MAX_ROOKIES_SUPPLY + 1);
    }

    // function testTransfer(address minter, uint256 qty, address to) public {
    //     vm.assume(minter != address(0));
    //     vm.assume(to != address(0));
    //     vm.assume(minter != to);

    //     testMint(minter, qty);

    //     for (uint256 tokenId; tokenId < rookies.totalSupply(); tokenId++) {
    //         rookies.transferFrom(minter, to, tokenId);
    //         assert(rookies.ownerOf(tokenId) == to);
    //     }
    //     assert(rookies.balanceOf(minter) == 0);
    //     assert(rookies.balanceOf(to) == qty);
    // }
}
