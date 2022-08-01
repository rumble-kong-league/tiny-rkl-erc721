// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import
    "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error TokenDataQueryForNonexistentToken();
error OwnerQueryForNonexistentToken();
error OperatorQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract Rookies is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    struct TokenData {
        address owner;
        bytes12 aux;
    }

    // TODO: set max batch size
    uint256 private constant maxBatchSize = 5;

    mapping(uint256 => TokenData) private tokens;
    uint256 public totalSupply;

    // TODO: you can get getters by overriding. Test this.
    string public override name = "Rookies";
    string public override symbol = "ROOKIES";

    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    uint256 public constant MAX_SUPPLY = 10000;

    constructor() {}

    // function setRoyalty(address receiver, uint96 value) external onlyOwner {
    //     _setDefaultRoyalty(receiver, value);
    // }

    /// EFFECTS ///

    // TODO: need to guard mint
    function mint(uint256 amount) external {
        _mint(_msgSender(), amount);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        TokenData memory token = _tokenData(tokenId);
        address owner = token.owner;
        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }
        _approve(to, tokenId, token);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) {
            revert ApproveToCaller();
        }
        operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
    {
        TokenData memory token = _tokenData(tokenId);
        if (!_isApprovedOrOwner(_msgSender(), tokenId, token.owner)) {
            revert TransferCallerNotOwnerNorApproved();
        }
        _transfer(from, to, tokenId, token);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        virtual
        override
    {
        TokenData memory token = _tokenData(tokenId);
        if (!_isApprovedOrOwner(_msgSender(), tokenId, token.owner)) {
            revert TransferCallerNotOwnerNorApproved();
        }
        _safeTransfer(from, to, tokenId, token, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        TokenData memory token,
        bytes memory data
    )
        internal
        virtual
    {
        _transfer(from, to, tokenId, token);
        if (to.isContract() && !_checkOnERC721Received(from, to, tokenId, data))
        {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    function _safeMint(address to, uint256 quantity, bytes memory data)
        internal
        virtual
    {
        _mint(to, quantity);
        if (to.isContract()) {
            unchecked {
                for (uint256 i; i < quantity; ++i) {
                    if (
                        !_checkOnERC721Received(address(0), to, totalSupply + i, data)
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                }
            }
        }
    }

    function _mint(address to, uint256 quantity) internal virtual {
        if (to == address(0)) {
            revert MintToZeroAddress();
        }
        if (quantity == 0) {
            revert MintZeroQuantity();
        }
        unchecked {
            for (uint256 i; i < quantity; ++i) {
                if (i % maxBatchSize == 0) {
                    TokenData storage token = tokens[totalSupply + i];
                    token.owner = to;
                    token.aux =
                        _calculateAux(address(0), to, totalSupply + i, 0);
                }
                emit Transfer(address(0), to, totalSupply + i);
            }
            totalSupply += quantity;
        }
    }

    // TODO: does not reset ApprovalForAll
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        TokenData memory token
    )
        internal
        virtual
    {
        if (token.owner != from) {
            revert TransferFromIncorrectOwner();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }
        _approve(address(0), tokenId, token);
        unchecked {
            uint256 nextTokenId = tokenId + 1;
            if (_exists(nextTokenId)) {
                TokenData storage nextToken = tokens[nextTokenId];
                if (nextToken.owner == address(0)) {
                    nextToken.owner = token.owner;
                    nextToken.aux = token.aux;
                }
            }
        }
        TokenData storage newToken = tokens[tokenId];
        newToken.owner = to;
        newToken.aux = _calculateAux(from, to, tokenId, token.aux);
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId, TokenData memory token)
        internal
        virtual
    {
        tokenApprovals[tokenId] = to;
        emit Approval(token.owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        private
        returns (bool)
    {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// INTERNAL READ ///

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < totalSupply;
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId,
        address owner
    )
        internal
        view
        virtual
        returns (bool)
    {
        return (
            spender == owner || isApprovedForAll(owner, spender)
                || getApproved(tokenId) == spender
        );
    }

    function _tokenData(uint256 tokenId)
        internal
        view
        returns (TokenData storage)
    {
        if (!_exists(tokenId)) {
            revert TokenDataQueryForNonexistentToken();
        }
        TokenData storage token = tokens[tokenId];
        uint256 currentIndex = tokenId;
        while (token.owner == address(0)) {
            unchecked {
                --currentIndex;
            }
            token = tokens[currentIndex];
        }
        return token;
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
        returns (bytes12)
    {
        return
            from == address(0)
            ? bytes12(
                keccak256(abi.encodePacked(tokenId, to, block.difficulty, block.timestamp))
            )
            : current;
    }

    // TODO: this needs to be settable. Need a var for it
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /// PUBLIC READ ///

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) {
            revert ApprovalQueryForNonexistentToken();
        }
        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) {
            revert BalanceQueryForZeroAddress();
        }
        uint256 count;
        address lastOwner;
        for (uint256 i; i < totalSupply; ++i) {
            address tokenOwner = tokens[i].owner;
            if (tokenOwner != address(0)) {
                lastOwner = tokenOwner;
            }
            if (lastOwner == owner) {
                ++count;
            }
        }
        return count;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) {
            revert OwnerQueryForNonexistentToken();
        }
        return _tokenData(tokenId).owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : "";
    }
}
