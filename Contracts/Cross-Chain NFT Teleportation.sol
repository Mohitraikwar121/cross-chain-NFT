// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract CrossChainNFTBridge {

    address public admin;
    mapping(string => mapping(uint256 => bool)) public crossChainTokens;

    event TokenTeleported(string sourceChain, string targetChain, uint256 tokenId, address owner);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this.");
        _;
    }

    // 1. Teleport NFT from source to target chain (represented here by marking the token as teleported)
    function teleportNFT(
        string memory sourceChain,
        string memory targetChain,
        address nftContract,
        uint256 tokenId
    ) external {
        IERC721 nft = IERC721(nftContract);
        address owner = nft.ownerOf(tokenId);

        // Mark the token as teleported from the source chain
        crossChainTokens[sourceChain][tokenId] = true;

        // Emit an event for the teleportation
        emit TokenTeleported(sourceChain, targetChain, tokenId, owner);

        // Transfer NFT to bridge contract (escrow on source chain)
        nft.transferFrom(owner, address(this), tokenId);
    }

    // 2. Claim Teleported NFT on target chain
    function claimTeleportedNFT(
        string memory sourceChain,
        string memory targetChain,
        address nftContract,
        uint256 tokenId
    ) external {
        require(crossChainTokens[sourceChain][tokenId], "Token has not been teleported.");

        IERC721 nft = IERC721(nftContract);
        address owner = msg.sender;

        // Transfer NFT to the recipient on the target chain
        nft.transferFrom(address(this), owner, tokenId);

        // Mark the token as claimed on target chain
        crossChainTokens[sourceChain][tokenId] = false;

        // Emit an event for the teleportation claim
        emit TokenTeleported(sourceChain, targetChain, tokenId, owner);
    }

    // 3. Admin function to clear up any incorrectly teleported tokens
    function clearTeleportedNFT(string memory sourceChain, uint256 tokenId) external onlyAdmin {
        crossChainTokens[sourceChain][tokenId] = false;
    }
}
