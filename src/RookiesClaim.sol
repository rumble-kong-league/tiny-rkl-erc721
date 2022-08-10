// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "src/Rookies.sol";

contract RookiesClaim is Rookies(10000), ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    uint256 public immutable startClaimTimestamp;
    uint256 public immutable endClaimTimestamp;
    uint256 public constant FOUR_WEEKS = 4 * 7 * 24 * 60 * 60;

    BitMaps.BitMap private claimable;
    address private immutable admin;
    address private expiredRookiesClaimer;
    IERC721 private kongs;

    event Claimed(uint256 indexed kongTokenId);

    constructor(uint256 startClaimTmstp, address kongCollection) {
        startClaimTimestamp = startClaimTmstp;
        endClaimTimestamp = startClaimTmstp + FOUR_WEEKS;
        kongs = IERC721(kongCollection);
        admin = msg.sender;
    }

    function redeem(uint256[] calldata kongTokenIds) external nonReentrant {
        require(block.timestamp >= startClaimTimestamp, "Claim not yet started");
        require(block.timestamp <= endClaimTimestamp, "Claim has expired");
        for (uint256 i; i < kongTokenIds.length; i++) {
            require(canClaim(kongTokenIds[i]), "Cannot claim");
            claimable.set(kongTokenIds[i]);
            emit Claimed(kongTokenIds[i]);
        }
        mint(kongTokenIds.length, _msgSender());
    }

    function canClaim(uint256 kongTokenId) public view returns (bool) {
        bool isOwner = kongs.ownerOf(kongTokenId) == _msgSender();
        bool isClaimed = claimable.get(kongTokenId);
        return isOwner && !isClaimed;
    }

    /// Assumes the owner is valid
    /// Useful for checking whether a connected account can claim rookies
    /// on the frontend.
    function canClaimAll(uint256[] calldata kongTokenIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory _canClaim = new bool[](kongTokenIds.length);
        for (uint256 i; i < kongTokenIds.length; i++) {
            _canClaim[i] = claimable.get(kongTokenIds[i]);
        }
        return _canClaim;
    }

    /// ADMIN ///

    function setExpiredRookiesClaimer(address _expiredRookiesClaimer)
        external
    {
        require(msg.sender == admin, "Only admin can set expiredRookiesClaimer");
        expiredRookiesClaimer = _expiredRookiesClaimer;
    }

    function adminRedeem(uint256[] calldata kongTokenIds, address to)
        external
    {
        require(
            msg.sender == expiredRookiesClaimer,
            "Only expiredRookiesClaimer can redeem"
        );
        require(
            block.timestamp > endClaimTimestamp, "Claim has not expired yet"
        );
        bool isClaimed;
        for (uint256 i; i < kongTokenIds.length; i++) {
            isClaimed = claimable.get(kongTokenIds[i]);
            require(!isClaimed, "Cannot claim");
            claimable.set(kongTokenIds[i]);
            emit Claimed(kongTokenIds[i]);
        }
        mint(kongTokenIds.length, to);
    }
}