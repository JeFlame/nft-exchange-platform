// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract HoangVuNFT is ERC721 {
	uint public MAX_TOKENS = 10000;

	constructor() ERC721("HoangVuNFT", "HVNFT") {}

	function _baseURI() internal pure override returns (string memory) {
		return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
	}

	function mint(address to, uint tokenId) external {
		require(tokenId >= 0 && tokenId < MAX_TOKENS, "tokenId out of range");
		_mint(to, tokenId);
	}
}
