// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/Rookies.sol";

contract RookiesTest is Rookies(50) {
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mintWrapped(uint256 amount) public {
        mint(amount, _msgSender());
    }

    function safeTransferWrapped(
        address from,
        address to,
        uint256 tokenId,
        TokenData calldata token,
        bytes calldata data
    )
        public
    {
        _safeTransfer(from, to, tokenId, token, data);
    }

    function safeMintWrapped(address to, uint256 quantity, bytes memory data)
        public
    {
        _safeMint(to, quantity, data);
    }

    function transferWrapped(
        address from,
        address to,
        uint256 tokenId,
        TokenData calldata token
    )
        public
    {
        _transfer(from, to, tokenId, token);
    }

    function tokenDataWrapped(uint256 tokenId) public view {
        _tokenData(tokenId);
    }
}
