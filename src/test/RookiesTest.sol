// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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
        address tokenDataOwner,
        bytes12 tokenDataAux,
        bytes calldata data
    )
        public
    {
        _safeTransfer(
            from,
            to,
            tokenId,
            TokenData({owner: tokenDataOwner, aux: tokenDataAux}),
            data
        );
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
        address tokenDataOwner,
        bytes12 tokenDataAux
    )
        public
    {
        _transfer(
            from,
            to,
            tokenId,
            TokenData({owner: tokenDataOwner, aux: tokenDataAux})
        );
    }

    function tokenDataWrapped(uint256 tokenId) public view {
        _tokenData(tokenId);
    }
}