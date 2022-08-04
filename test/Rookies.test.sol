// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";

import "src/test/RookiesTest.sol";

contract BrokenGnosisVault {
    function mintRookies(RookiesTest rookies, uint256 qty) external {
        rookies.mint(qty);
    }
}

contract GnosisVault is ERC721Holder {
    function mintRookies(RookiesTest rookies, uint256 qty) external {
        rookies.mint(qty);
    }
}

contract RookiesTests is Test {
    address MINTER = 0x0000000000000000000000000000000000000001;
    address ALICE = 0x0000000000000000000000000000000000000002;
    address BOB = 0x0000000000000000000000000000000000000003;
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

    function testStateVars() public {
        RookiesTest rookies = new RookiesTest();
        assertEq(rookies.name(), "Rookies");
        assertEq(rookies.symbol(), "ROOKIES");
    }

    /// Test noone is approved after mint
    /// Test after approve, address is approved
    /// Test after transfer approve gets reset
    function testApprove() public {
        vm.startPrank(MINTER, MINTER);

        RookiesTest rookies = new RookiesTest();
        rookies.mint(1);
        assertEq(rookies.getApproved(0), address(0));
        rookies.approve(ALICE, 0);
        assertEq(rookies.getApproved(0), ALICE);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        rookies.safeTransferFrom(MINTER, BOB, 0);
        assertEq(rookies.getApproved(0), address(0));
        assertEq(rookies.balanceOf(MINTER), 0);
        assertEq(rookies.balanceOf(ALICE), 0);
        assertEq(rookies.balanceOf(BOB), 1);
        assertEq(rookies.ownerOf(0), BOB);
    }

    function testApproveForAll() public {
        vm.startPrank(MINTER, MINTER);

        RookiesTest rookies = new RookiesTest();
        rookies.mint(2);
        rookies.setApprovalForAll(ALICE, true);

        assertEq(rookies.isApprovedForAll(MINTER, ALICE), true);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        rookies.transferFrom(MINTER, BOB, 0);
        assertEq(rookies.balanceOf(ALICE), 0);
        assertEq(rookies.balanceOf(MINTER), 1);
        assertEq(rookies.balanceOf(BOB), 1);

        vm.stopPrank();
        vm.startPrank(MINTER, MINTER);
        rookies.transferFrom(MINTER, BOB, 1);
        assertEq(rookies.balanceOf(ALICE), 0);
        assertEq(rookies.balanceOf(MINTER), 0);
        assertEq(rookies.balanceOf(BOB), 2);

        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        // * selector should work as well
        // https://github.com/AztecProtocol/aztec-connect-bridges/blob/6388b08be07ebd4d86a2de8e6bf2ca3c2cc8ac5b/src/test/bridges/liquity/StakingBridgeUnit.t.sol#L43
        vm.expectRevert(
            abi.encodeWithSignature("TransferCallerNotOwnerNorApproved()")
        );
        rookies.transferFrom(BOB, MINTER, 1);
    }

    function testMintFromBrokenContract() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        BrokenGnosisVault broken = new BrokenGnosisVault();
        vm.expectRevert(
            abi.encodeWithSignature("TransferToNonERC721ReceiverImplementer()")
        );
        broken.mintRookies(rookies, 1);
    }

    function testMintFromContract() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        GnosisVault gnosis = new GnosisVault();
        gnosis.mintRookies(rookies, 1);
        assertEq(rookies.balanceOf(address(gnosis)), 1);
    }

    function testTransferFailsToBrokenContract() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mint(1);
        BrokenGnosisVault broken = new BrokenGnosisVault();
        vm.expectRevert(
            abi.encodeWithSignature("TransferToNonERC721ReceiverImplementer()")
        );
        rookies.safeTransferFrom(MINTER, address(broken), 0);
    }

    function testTransferToContract() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mint(1);
        GnosisVault gnosis = new GnosisVault();
        rookies.safeTransferFrom(MINTER, address(gnosis), 0);
        assertEq(rookies.balanceOf(address(gnosis)), 1);
    }
}

// TODO: test supports intefaces
