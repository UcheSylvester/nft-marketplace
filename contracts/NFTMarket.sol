// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NTFMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;
  address payable owner;
  uint256 listingPrice = 0.025 ether;

  constructor() {
    owner = payable (msg.sender);
  }

  struct MarketItem {
    uint256 itemId;
    uint256 tokenId;
    uint256 price;
    address payable seller;
    address owner;
    address nftContract;
    bool sold;
  }

  mapping (uint256 => MarketItem) private _marketItems;

  event MarketItemCreated (
    uint256 indexed itemId,
    uint256 indexed tokenId,
    uint256 price,
    address seller,
    address owner,
    address indexed nftContract,
    bool sold
  );

  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
    require(price > 0, "Price must be greater than 0");
    require(price >= listingPrice, "Price must be greater than or equal to listing price");

    // increase items in the nft market
    _itemIds.increment();

    uint256 newItemId = _itemIds.current();

    // create new market item
    _marketItems[newItemId] = MarketItem(
      newItemId,
      tokenId,
      price,
      payable(msg.sender),
      payable(address(0)),
      nftContract,
      false
    );

    // transfer ownership of token to this marketplace/contract
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(newItemId, tokenId, price, payable(msg.sender), payable(address(0)), nftContract, false);
  }


  function createMarketSale (address nftContract, uint256 itemId) public payable nonReentrant {
    require(_marketItems[itemId].price == msg.value, "You must pay the exact item price");
    require(_marketItems[itemId].sold == false, "Item is already sold");

    // pay the seller
    _marketItems[itemId].seller.transfer(msg.value);

    // transfer ownership of token to buyer
    IERC721(nftContract).transferFrom(address(this), msg.sender, _marketItems[itemId].tokenId);

    // set owner of token to buyer
    _marketItems[itemId].owner = payable(msg.sender);

    // increase items sold
    _itemsSold.increment();

    // set item as sold
    _marketItems[itemId].sold = true;

    // pay the contract owner the listing price
    owner.transfer(listingPrice);
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint256 totalItemsCount = _itemIds.current();
    uint256 totalItemsSold = _itemsSold.current();
    uint256 unsoldItems = totalItemsCount - totalItemsSold;

    MarketItem[] memory marketItems = new MarketItem[](unsoldItems);

    uint currentIndex = 0;
    for (uint i = 0; i < totalItemsCount; i++) {
      if(_marketItems[i + 1].owner == address(0) && _marketItems[i + 1].sold == false) {
        uint currentId = _marketItems[i + 1].itemId;

        MarketItem memory currentItem = _marketItems[currentId];
        marketItems[currentIndex] = currentItem;
        
        currentIndex += 1;
      }
    }
    return marketItems;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint myNFTsCount = 0;

    MarketItem[] memory myNFTs = new MarketItem[](myNFTsCount);

    for(uint i = 0; i < totalItemsCount; i++) {
      if(_marketItems[i + 1].owner == msg.sender) {
        uint currentId = _marketItems[i + 1].itemId;
        
        MarketItem memory currentItem = _marketItems[currentId];
        myNFTs[myNFTsCount] = currentItem;

        myNFTsCount += 1;
      }
    }
    return myNFTs;
  }

    function fetchItemsICreated() public view returns (MarketItem[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint myNFTsCount = 0;

    MarketItem[] memory itemICreated = new MarketItem[](myNFTsCount);

    for(uint i = 0; i < totalItemsCount; i++) {
      if(_marketItems[i + 1].seller == msg.sender) {
        uint currentId = _marketItems[i + 1].itemId;
        
        MarketItem memory currentItem = _marketItems[currentId];
        itemICreated[myNFTsCount] = currentItem;

        myNFTsCount += 1;
      }
    }
    return itemICreated;
  }
}