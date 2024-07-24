// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTExchangePlatform is IERC721Receiver {
	struct Order {
		address owner;
		uint256 price;
	}

	mapping(address => mapping(uint256 => Order)) public nftList;

	event List(
		address indexed seller,
		address indexed nftAddr,
		uint256 indexed tokenId,
		uint256 price
	);
	event Purchase(
		address indexed buyer,
		address indexed nftAddr,
		uint256 indexed tokenId,
		uint256 price
	);
	event Revoke(
		address indexed seller,
		address indexed nftAddr,
		uint256 indexed tokenId
	);
	event Update(
		address indexed seller,
		address indexed nftAddr,
		uint256 indexed tokenId,
		uint256 newPrice
	);

	error NeedApproval();
	error InvalidPrice();
	error TransferFailed();
	error IncreasePrice();
	error InvalidOrder();
	error NotOwner();

	receive() external payable {}

	fallback() external payable {}

	function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
		IERC721 _nft = IERC721(_nftAddr);
		if (_nft.getApproved(_tokenId) != address(this)) {
			revert NeedApproval();
		}
		if (_price <= 0) {
			revert InvalidPrice();
		}

		Order storage _order = nftList[_nftAddr][_tokenId];
		_order.owner = msg.sender;
		_order.price = _price;

		_nft.safeTransferFrom(msg.sender, address(this), _tokenId);

		emit List(msg.sender, _nftAddr, _tokenId, _price);
	}

	function purchase(address _nftAddr, uint256 _tokenId) public payable {
		Order storage _order = nftList[_nftAddr][_tokenId];
		if (_order.price <= 0) {
			revert InvalidPrice();
		}
		if (msg.value < _order.price) {
			revert IncreasePrice();
		}

		IERC721 _nft = IERC721(_nftAddr);
		if (_nft.ownerOf(_tokenId) != address(this)) {
			revert InvalidOrder();
		}

		_nft.safeTransferFrom(address(this), msg.sender, _tokenId);

		(bool success, ) = payable(_order.owner).call{ value: _order.price }(
			""
		);
		if (!success) {
			revert TransferFailed();
		}

		(bool successRefund, ) = payable(msg.sender).call{
			value: msg.value - _order.price
		}("");
		if (!successRefund) {
			revert TransferFailed();
		}

		delete nftList[_nftAddr][_tokenId];

		emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
	}

	function revoke(address _nftAddr, uint256 _tokenId) public {
		Order storage _order = nftList[_nftAddr][_tokenId];
		if (_order.owner != msg.sender) {
			revert NotOwner();
		}

		IERC721 _nft = IERC721(_nftAddr);
		if (_nft.ownerOf(_tokenId) != address(this)) {
			revert InvalidOrder();
		}

		_nft.safeTransferFrom(address(this), msg.sender, _tokenId);
		delete nftList[_nftAddr][_tokenId];

		emit Revoke(msg.sender, _nftAddr, _tokenId);
	}

	function update(
		address _nftAddr,
		uint256 _tokenId,
		uint256 _newPrice
	) public {
		if (_newPrice <= 0) {
			revert InvalidPrice();
		}
		Order storage _order = nftList[_nftAddr][_tokenId];
		if (_order.owner != msg.sender) {
			revert NotOwner();
		}

		IERC721 _nft = IERC721(_nftAddr);
		if (_nft.ownerOf(_tokenId) != address(this)) {
			revert InvalidOrder();
		}

		_order.price = _newPrice;

		emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public virtual override returns (bytes4) {
		return this.onERC721Received.selector;
	}
}
