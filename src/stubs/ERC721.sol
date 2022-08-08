// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract OZ is ERC721("KongsStub", "RKL") {
    uint256 totalMinted = 0;
    function mint(address to, uint256 qty) external {
        for (uint256 i = 0; i < qty; i++) {
            _mint(to, totalMinted + i);
        }
        totalMinted += qty;
    }
}