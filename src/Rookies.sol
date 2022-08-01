// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import
    "openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";

import "./TinyERC721.sol";
import "./TokenSale.sol";

contract Rookies is TinyERC721, ERC2981, Ownable, TokenSale {
    uint256 public constant MAX_SUPPLY = 10000;

    constructor() TinyERC721("Rookies", "ROOKIES", 5) {
        _safeMint(_msgSender(), 1);
    }

    function _calculateAux(
        address from,
        address to,
        uint256 tokenId,
        bytes12 current
    )
        internal
        view
        virtual
        override
        returns (bytes12)
    {
        return
            from == address(0)
            ? bytes12(
                keccak256(abi.encodePacked(tokenId, to, block.difficulty, block.timestamp))
            )
            : current;
    }

    function soulHash(uint256 tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, _tokenData(tokenId).aux));
    }

    // TODO: implement
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return "";
        // _rendererAddress != address(0) ? ITokenRenderer(_rendererAddress).tokenURI(tokenId, soulHash(tokenId)) : "";
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function _guardMint(address, uint256 quantity)
        internal
        view
        virtual
        override
    {
        unchecked {
            require(tx.origin == msg.sender, "Can't mint from contract");
            require(
                totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply"
            );
        }
    }

    function _mintTokens(address to, uint256 quantity)
        internal
        virtual
        override
    {
        _mint(to, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (TinyERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}