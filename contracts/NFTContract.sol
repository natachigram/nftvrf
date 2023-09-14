// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract NftContract is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_fee;
    uint256 private i_tokenCounter;

    // Mapping from requestId to traits
    mapping(bytes32 => Traits) public requestIdToTraits;

    // Struct to represent NFT traits
    struct Traits {
        uint256 energy;
        uint256 speed;
        uint256 gun;
        uint256 bullet;
        uint256 strength;
        uint256 flying;
    }

    // Events
    event NftMinted(uint256 indexed tokenId, address indexed minter, Traits traits);
    event MintFeeUpdated(uint256 newFee);

    // Constructor with all the parameters needed for Chainlink VRF and UriStorage NFTs
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint256 fee,
        string[3] memory nftTokenUris
    )
        VRFConsumerBaseV2(vrfCoordinatorV2, keyHash)
        ERC721("Your NFT Collection", "YNFT")
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_fee = fee;
        i_tokenCounter = 0;

        _initializeContract(nftTokenUris);
    }

    function requestNft() public payable returns (bytes32 requestId) {
        require(msg.value >= i_fee, "Insufficient funds for NFT minting");

        requestId = requestRandomness(i_keyHash, i_fee);

        s_requestIdToSender[requestId] = msg.sender;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Generate traits using the randomness provided
        Traits memory traits = generateTraits(randomness);

        // Mint the NFT
        uint256 tokenId = i_tokenCounter;
        i_tokenCounter = tokenId + 1;

        // Mint the NFT to the address that made the request
        _mint(s_requestIdToSender[requestId], tokenId);
        _setTokenURI(tokenId, getTokenURI(traits));

        tokenIdMinted[tokenId] = true;

        emit NftMinted(tokenId, s_requestIdToSender[requestId], traits);
    }

    function generateTraits(uint256 randomness) internal pure returns (Traits memory) {
        // Customize trait generation here
        return Traits(
            randomness % 101,  
            randomness % 101,  
            randomness % 101,    
            randomness % 101,    
            randomness % 101,    
            randomness % 101     
        );
    }

    function getTokenURI(Traits memory traits) internal pure returns (string memory) {
        // Customize token URI generation here
        return string(abi.encodePacked(
            "https://api.example.com/nft?energy=",
            uint256(traits.energy).toString(),
            "&speed=",
            uint256(traits.speed).toString(),
            "&gun=",
            uint256(traits.gun).toString(),
            "&bullet=",
            uint256(traits.bullet).toString(),
            "&strength=",
            uint256(traits.strength).toString(),
            "&flying=",
            uint256(traits.flying).toString()
        ));
    }

    // Admin function to update the mint fee
    function updateMintFee(uint256 newFee) external onlyOwner {
        i_fee = newFee;
        emit MintFeeUpdated(newFee);
    }

    // Initialize Contract
    function _initializeContract(string[3] memory nftTokenUris) private {
        // Initialize your contract as needed
    }
}
