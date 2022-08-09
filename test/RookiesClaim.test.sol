// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import "src/stubs/OZ.sol";
import "src/RookiesClaim.sol";

contract RookiesTests is Test {
    address MINTER = 0x0000000000000000000000000000000000000001;
    address ALICE = 0x0000000000000000000000000000000000000002;
    address BOB = 0x0000000000000000000000000000000000000003;

    uint256[] tokenIds;

    function testRedeem() public {
        vm.startPrank(MINTER, MINTER);

        OZ kongs = new OZ();
        RookiesClaim rookies = new RookiesClaim(block.timestamp, address(kongs));
        vm.stopPrank();

        vm.startPrank(ALICE, ALICE);
        uint256 qty = 10;
        kongs.mint(ALICE, qty);

        delete tokenIds;
        for (uint256 tokenId; tokenId < qty; tokenId++) {
            tokenIds.push(tokenId);
        }
        rookies.redeem(tokenIds);
        for (uint256 tokenId; tokenId < qty; tokenId++) {
            assert(rookies.ownerOf(tokenId) == ALICE);
            assert(rookies.canClaim(tokenId) == false);
        }
    }
}