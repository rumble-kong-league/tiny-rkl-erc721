const { MerkleTree } = require("merkletreejs");
const { soliditySha3 } = require("web3-utils");
const snapshot = require("./snapshot.json");

// * soliditySha3 acts as abi.encodePacked
// * See: https://blog.8bitzen.com/posts/18-03-2019-keccak-abi-encodepacked-with-javascript/
const keccak256 = (...x) => {
  return Buffer.from(soliditySha3(...x).slice(2), "hex");
};

const leaves = snapshot.map((x) => keccak256(x.id, x.numKongsOwned));
const tree = new MerkleTree(leaves, keccak256, { sort: true });

const root = tree.getRoot().toString("hex");
const leaf = keccak256("0x95e555e3f453b8b4a2029fc6ab81010928b0f987", 492);
let proof = tree.getProof(leaf);

console.log("root:", root);
console.log(
  "proof:",
  proof.map((e) => e.data.toString("hex"))
);
console.log("verified:", tree.verify(proof, leaf, root));
