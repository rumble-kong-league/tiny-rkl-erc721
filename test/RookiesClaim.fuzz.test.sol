// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import "src/stubs/OZ.sol";
import "src/RookiesClaim.sol";

contract RookiesClaimFuzzTests is Test {
    RookiesClaim rookies;
    OZ kongs;

    uint256[] tokenIds;

    function setUp() public {
        kongs = new OZ();
        rookies = new RookiesClaim(block.timestamp, address(kongs));
    }

    function testRedeem(address minter, uint256 qty) public {
        // ensures minter is not a contract
        // forge creates contracts that do not support ERC721Receiver
        vm.assume(minter.code.length == 0);
        vm.assume(minter != address(0));
        vm.assume(qty > 0);
        vm.assume(qty < 51);

        vm.startPrank(minter, minter);
        kongs.mint(minter, qty);

        delete tokenIds;
        for (uint256 tokenId; tokenId < qty; tokenId++) {
            tokenIds.push(tokenId);
        }
        rookies.redeem(tokenIds);
        for (uint256 tokenId; tokenId < qty; tokenId++) {
            assert(rookies.ownerOf(tokenId) == minter);
            assert(rookies.canClaim(tokenId) == false);
        }
    }
}