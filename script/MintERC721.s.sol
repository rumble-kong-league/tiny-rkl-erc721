// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/stubs/OZ.sol";

contract MyScript is Script {
    function run() external {
        vm.startBroadcast();

        OZ nft = OZ(0xfC01aE2764Ca9CD8ABbf10aBf430Ca4661AEAcd9);
        nft.mint(0x56888646DA93b28e92Fe2FED68Dfd082172a4faA, 100);
        nft.mint(0x95AE02bEC1F4306c314F7963d39F0CdA2191b85E, 100);

        vm.stopBroadcast();
    }
}