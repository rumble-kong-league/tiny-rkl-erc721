// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";

import "src/test/RookiesTest.sol";

contract BrokenGnosisVault {
    function mintRookies(RookiesTest rookies, uint256 qty) external {
        rookies.mintWrapped(qty);
    }
}

contract GnosisVault is ERC721Holder {
    function mintRookies(RookiesTest rookies, uint256 qty) external {
        rookies.mintWrapped(qty);
    }
}

contract RookiesTests is Test {
    address MINTER = 0x0000000000000000000000000000000000000001;
    address ALICE = 0x0000000000000000000000000000000000000002;
    address BOB = 0x0000000000000000000000000000000000000003;
    address CHARLIE = 0x0000000000000000000000000000000000000004;
    address DAVE = 0x0000000000000000000000000000000000000005;
    address EVE = 0x0000000000000000000000000000000000000006;
    uint256 MAX_ROOKIES_SUPPLY = 50;

    function mintRookies(uint256 qty) public {
        vm.startPrank(MINTER, MINTER);

        RookiesTest rookies = new RookiesTest();
        if (qty > MAX_ROOKIES_SUPPLY) {
            vm.expectRevert("Exceeds max supply");
        }
        rookies.mintWrapped(qty);

        if (qty <= MAX_ROOKIES_SUPPLY) {
            assert(rookies.currentSupply() == qty);
        }
    }

    function testMint() public {
        mintRookies(MAX_ROOKIES_SUPPLY);
    }

    function testMints() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        rookies.mintWrapped(1);
        assert(rookies.currentSupply() == 1);
        assert(rookies.ownerOf(0) == ALICE);
        vm.stopPrank();
        vm.startPrank(BOB, BOB);
        rookies.mintWrapped(1);
        assert(rookies.currentSupply() == 2);
        assert(rookies.ownerOf(1) == BOB);
        vm.stopPrank();
        vm.startPrank(CHARLIE, CHARLIE);
        rookies.mintWrapped(1);
        assert(rookies.currentSupply() == 3);
        assert(rookies.ownerOf(2) == CHARLIE);
        vm.stopPrank();
        vm.startPrank(DAVE, DAVE);
        rookies.mintWrapped(1);
        assert(rookies.currentSupply() == 4);
        assert(rookies.ownerOf(3) == DAVE);
        vm.stopPrank();
        vm.startPrank(EVE, EVE);
        rookies.mintWrapped(1);
        assert(rookies.currentSupply() == 5);
        assert(rookies.ownerOf(4) == EVE);
        assert(rookies.ownerOf(0) == ALICE);
        assert(rookies.ownerOf(1) == BOB);
        assert(rookies.ownerOf(2) == CHARLIE);
        assert(rookies.ownerOf(3) == DAVE);
    }

    function testExceedsMaxSupplyMint() public {
        mintRookies(MAX_ROOKIES_SUPPLY + 1);
    }

    function testStateVars() public {
        RookiesTest rookies = new RookiesTest();
        assertEq(rookies.name(), "RKL Rookies");
        assertEq(rookies.symbol(), "ROOKIES");
    }

    /// Test noone is approved after mint
    /// Test after approve, address is approved
    /// Test after transfer approve gets reset
    function testApprove() public {
        vm.startPrank(MINTER, MINTER);

        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
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
        rookies.mintWrapped(2);
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
        rookies.mintWrapped(1);
        BrokenGnosisVault broken = new BrokenGnosisVault();
        vm.expectRevert(
            abi.encodeWithSignature("TransferToNonERC721ReceiverImplementer()")
        );
        rookies.safeTransferFrom(MINTER, address(broken), 0);
    }

    function testTransferToContract() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        GnosisVault gnosis = new GnosisVault();
        rookies.safeTransferFrom(MINTER, address(gnosis), 0);
        assertEq(rookies.balanceOf(address(gnosis)), 1);
    }

    function testApproveToCallerRevert() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);

        vm.expectRevert(abi.encodeWithSignature("ApproveToCaller()"));
        rookies.setApprovalForAll(MINTER, true);
    }

    function testTransferWithDataRevert() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert(
            abi.encodeWithSignature("TransferCallerNotOwnerNorApproved()")
        );
        rookies.safeTransferFrom(ALICE, BOB, 0, "");
    }

    function testApprovalToCurrentOwner() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        vm.expectRevert(abi.encodeWithSignature("ApprovalToCurrentOwner()"));
        rookies.approve(MINTER, 0);
    }

    function testApprovalRevertSus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert(
            abi.encodeWithSignature("ApprovalCallerNotOwnerNorApproved()")
        );
        rookies.approve(BOB, 0);
    }

    function testCantMintToZeroAddy() public {
        vm.startPrank(address(0), address(0));
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(abi.encodeWithSignature("MintToZeroAddress()"));
        rookies.mintWrapped(1);
    }

    function testCantMintZeroQty() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(abi.encodeWithSignature("MintZeroQuantity()"));
        rookies.mintWrapped(0);
    }

    function testSetBaseURISus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert();
        rookies.setBaseURI("");
    }

    function testSetBaseURI() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.setBaseURI("ipfs://rookies/");
        assertEq(rookies.baseURI(), "ipfs://rookies/");
    }

    function testRenounceOwnershipSus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        vm.stopPrank();
        vm.startPrank(ALICE, ALICE);
        vm.expectRevert();
        rookies.renounceOwnership();
    }

    function testRenounceOwnership() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.renounceOwnership();
        vm.expectRevert();
        rookies.renounceOwnership();
    }

    function testGetApprovedForSus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(
            abi.encodeWithSignature("ApprovalQueryForNonexistentToken()")
        );
        rookies.getApproved(0);
    }

    function testZeroAddyBalanceSus() public {
        vm.startPrank(address(0), address(0));
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(abi.encodeWithSignature("BalanceQueryForZeroAddress()"));
        rookies.balanceOf(address(0));
    }

    function testOwnerForNonExistent() public {
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(
            abi.encodeWithSignature("OwnerQueryForNonexistentToken()")
        );
        rookies.ownerOf(0);
    }

    function testTokenURIForNonExistent() public {
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(
            abi.encodeWithSignature("URIQueryForNonexistentToken()")
        );
        rookies.tokenURI(0);
    }

    function testTokenURI() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        assertEq(rookies.tokenURI(0), "");
        rookies.setBaseURI("ipfs://rookies/");
        assertEq(rookies.tokenURI(0), "ipfs://rookies/0");
    }

    function testTransferToZeroAddressRevert() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        vm.expectRevert(abi.encodeWithSignature("TransferToZeroAddress()"));
        rookies.safeTransferFrom(MINTER, address(0), 0);
    }

    function testTransferFromSus() public {
        vm.startPrank(MINTER, MINTER);
        RookiesTest rookies = new RookiesTest();
        rookies.mintWrapped(1);
        vm.expectRevert(abi.encodeWithSignature("TransferFromIncorrectOwner()"));
        rookies.transferWrapped(ALICE, BOB, 0, MINTER, bytes12(0x0));
    }

    function testTokenDataQueryForNonExistent() public {
        RookiesTest rookies = new RookiesTest();
        vm.expectRevert(
            abi.encodeWithSignature("TokenDataQueryForNonexistentToken()")
        );
        rookies.tokenDataWrapped(0);
    }
}