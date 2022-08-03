// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract RookiesClaim {
    bytes32 public immutable root;

    constructor(bytes32 merkleroot) {
        root = merkleroot;
    }

    function redeem(address account, uint256 tokenId, bytes32[] calldata proof)
        external
    {
        require(_verify(_leaf(account, tokenId), proof), "Invalid merkle proof");
        // _safeMint(account, tokenId);
    }

    function _leaf(address account, uint256 tokenId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
