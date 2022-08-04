// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "src/Rookies.sol";

contract RookiesClaim is Rookies(10000), ReentrancyGuard {
    bytes32 public immutable root;

    uint256 public immutable startClaimTimestamp;
    uint256 public immutable endClaimTimestamp;
    uint256 public constant FOUR_WEEKS = 4 * 7 * 24 * 3600;
    address private immutable admin;
    address private expiredRookiesClaimer;

    mapping(address => uint256) private claimedRookies;

    constructor(bytes32 merkleroot, uint256 startClaimTmstp) {
        root = merkleroot;
        startClaimTimestamp = startClaimTmstp;
        endClaimTimestamp = startClaimTmstp + FOUR_WEEKS;
        admin = msg.sender;
    }

    function redeem(
        address account,
        uint256 eligibleQty,
        bytes32[] calldata proof,
        uint256 mintQty
    )
        external
        nonReentrant
    {
        require(block.timestamp >= startClaimTimestamp, "Claim not yet started");
        require(block.timestamp <= endClaimTimestamp, "Claim has expired");
        require(
            _verify(_leaf(account, eligibleQty), proof), "Invalid merkle proof"
        );

        uint256 claimedSoFar = claimedRookies[account];
        require(claimedSoFar + mintQty <= eligibleQty, "Exceeds eligible qty");
        claimedRookies[account] += mintQty;

        mint(mintQty, account);
    }

    function _leaf(address account, uint256 eligibleQty)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(eligibleQty, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// ADMIN ///

    function setExpiredRookiesClaimer(address _expiredRookiesClaimer)
        external
    {
        require(msg.sender == admin, "Only admin can set expiredRookiesClaimer");
        expiredRookiesClaimer = _expiredRookiesClaimer;
    }

    function adminRedeem(uint256 qty, address to) external {
        require(
            msg.sender == expiredRookiesClaimer,
            "Only expiredRookiesClaimer can redeem"
        );
        require(
            block.timestamp > endClaimTimestamp, "Claim has not expired yet"
        );

        mint(qty, to);
    }
}
