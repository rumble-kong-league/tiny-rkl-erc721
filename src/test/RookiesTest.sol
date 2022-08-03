// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/Rookies.sol";

contract RookiesTest is Rookies(50) {

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

}