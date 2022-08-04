// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/test/RookiesTest.sol";

contract RookiesFuzzTests is Test {
    RookiesTest rookies;

    function setUp() public {
        rookies = new RookiesTest();
    }

    function testMint(address minter, uint256 qty) public {
        vm.assume(minter.code.length == 0); // ensures minter is not a contract
        vm.assume(minter != address(0));
        vm.assume(qty > 0);
        vm.assume(qty < 51);

        vm.startPrank(minter, minter);

        rookies.mint(qty);

        for (uint256 tokenId = 1; tokenId < rookies.totalSupply(); tokenId++) {
            assert(rookies.ownerOf(tokenId) == minter);
        }
        assert(rookies.balanceOf(minter) == qty);
        assert(rookies.exists(rookies.totalSupply()) == false);
    }

    function testTransfer(address minter, uint256 qty, address to) public {
        vm.assume(minter.code.length == 0); // ensures minter is not a contract
        vm.assume(minter != address(0));
        vm.assume(to != address(0));
        vm.assume(minter != to);

        testMint(minter, qty);

        for (uint256 tokenId; tokenId < rookies.totalSupply(); tokenId++) {
            rookies.transferFrom(minter, to, tokenId);
            assert(rookies.ownerOf(tokenId) == to);
        }
        assert(rookies.balanceOf(minter) == 0);
        assert(rookies.balanceOf(to) == qty);
    }
}
