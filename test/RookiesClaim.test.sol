// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/RookiesClaim.sol";

contract RookiesClaimTests is Test {
    address MINTER = 0x0000000000000000000000000000000000000001;
    address ALICE = 0x0000000000000000000000000000000000000002;
    address BOB = 0x0000000000000000000000000000000000000003;
    address NFTAPE = 0x95E555e3f453b8B4A2029Fc6aB81010928b0f987;

    // taken from: https://stackoverflow.com/questions/54480589/
    // can-not-declare-a-bytes32-fixed-array-or-bytes32-unfixed-array-in-a-contract
    // You need to explicitly cast the first element of the array literal to indicate
    // the type. The Solidity compiler isn't smart enough to infer the right-hand side type for you:
    bytes32[] proof = [
        bytes32(0xf5d92087e437d0a287fb393e68350f6a3a663a58e62d20485746a18fc1c42e22),
        0x3627c740886c39ee1754cb98a0281e29c0dfbb651b74076480c114b52cc1e9e1,
        0x0291d4f58fed2322ffe7c9ee422180fff067c5a929f64428b1c80e47efa20c61,
        0xbd3c20fdab0cf92feacb6b90ba4249b4d7015c7850dca7b2c9d224235980464a,
        0xed6ac32e97ccc2446c1d48ce77466d5d19167781d9e9c9e6ac86848b447ceba4,
        0x1771adc35f2bf6efbe5647cb2a9c0712f5615f3f452b12fbb58f3da65e4ad599,
        0x463c24e148c7930bea9cbd2359c708bdefa82efb8dc64bbed7728255aef5d039,
        0xdff3f04e0d6bdda97e7e2ee2ecf4d80244e8ad8e6bef60f3298cf666c25b8a06,
        0xcba5699d2e0f37cbfb665162f987e2625ace0f604a9fd1f575179c507404e5f7,
        0x1056f37887b7ec664db806f29858db70f24e6228ce9a1f7eaa6ccfb9f6a47b13,
        0xef7c9ea7120d44164082914bbd5c3b67b17fedffe3733b1f82de504c4f8e90b8,
        0xdea44fa80b545436b1746c22b0ec5412686fba6b24b54c653104af8e8845c161
    ];
    bytes32[] invalidProof = [bytes32(0)];

    bytes32 merkleroot =
        0x73fa4003ea9979b7742accaa673571db9032c06944c41ed218f5930021609fa3;

    function testFromEOA() public {
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.startPrank(NFTAPE, NFTAPE);
        rookies.redeem(NFTAPE, 492, proof, 1);
        assertEq(rookies.balanceOf(NFTAPE), 1);
        rookies.redeem(NFTAPE, 492, proof, 491);
        assertEq(rookies.balanceOf(NFTAPE), 492);
    }

    function testThrowsIfExceedFromEOA() public {
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.startPrank(NFTAPE, NFTAPE);
        rookies.redeem(NFTAPE, 492, proof, 1);
        assertEq(rookies.balanceOf(NFTAPE), 1);
        vm.expectRevert("Exceeds eligible qty");
        rookies.redeem(NFTAPE, 492, proof, 492);
    }

    function testInvalifProofFromEOA() public {
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.startPrank(NFTAPE, NFTAPE);
        vm.expectRevert("Invalid merkle proof");
        rookies.redeem(NFTAPE, 492, invalidProof, 1);
    }

    function testClaimExpired() public {
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.startPrank(NFTAPE, NFTAPE);
        vm.warp(block.timestamp + 4 * 7 * 24 * 3600 + 1);
        vm.expectRevert("Claim has expired");
        rookies.redeem(NFTAPE, 492, proof, 1);
    }

    function testClaimRevertsBeforeStart() public {
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp + 1
        );
        vm.startPrank(NFTAPE, NFTAPE);
        vm.expectRevert("Claim not yet started");
        rookies.redeem(NFTAPE, 492, proof, 1);
    }

    function testSetExpiredRookiesClaim() public {
        vm.startPrank(MINTER, MINTER);
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        rookies.setExpiredRookiesClaimer(ALICE);
        // TODO: load ALICE from storage slot
    }

    function testSetExpiredRookiesClaimSus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert(
            "Only admin can set expiredRookiesClaimer"
        );
        rookies.setExpiredRookiesClaimer(ALICE);
    }

    function testAdminRedeem() public {
        vm.startPrank(MINTER, MINTER);
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.warp(block.timestamp + 4 * 7 * 24 * 3600 + 1);
        rookies.setExpiredRookiesClaimer(ALICE);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        rookies.adminRedeem(10, BOB);
        assertEq(rookies.balanceOf(BOB), 10);   
    }

    function testNonAdminRedeemRevert() public {
        vm.startPrank(MINTER, MINTER);
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        vm.warp(block.timestamp + 4 * 7 * 24 * 3600 + 1);
        rookies.setExpiredRookiesClaimer(ALICE);
        vm.expectRevert("Only expiredRookiesClaimer can redeem");
        rookies.adminRedeem(10, BOB);
    }

    function testCantRedeemBeforeEndClaim() public {
        vm.startPrank(MINTER, MINTER);
        RookiesClaim rookies = new RookiesClaim(
            merkleroot,
            block.timestamp
        );
        rookies.setExpiredRookiesClaimer(ALICE);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert("Claim has not expired yet");
        rookies.adminRedeem(10, BOB);     
    }
}
