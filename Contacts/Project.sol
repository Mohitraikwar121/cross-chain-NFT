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

    // 1. Teleport NFT from source to target chain (mark as teleported and escrow it)
    function teleportNFT(
        string memory sourceChain,
        string memory targetChain,
        address nftContract,
        uint256 tokenId
    ) external {
        IERC721 nft = IERC721(nftContract);
        address owner = nft.ownerOf(tokenId);

        // Mark token as teleported
        crossChainTokens[sourceChain][tokenId] = true;

        // Emit teleport event
        emit TokenTeleported(sourceChain, targetChain, tokenId, owner);

        // Escrow the token in the bridge contract
        nft.transferFrom(owner, address(this), tokenId);
    }

    // 2. Claim teleported NFT on target chain
    function claimTeleportedNFT(
        string memory sourceChain,
        string memory targetChain,
        address nftContract,
        uint256 tokenId
    ) external {
        require(crossChainTokens[sourceChain][tokenId], "Token has not been teleported.");

        IERC721 nft = IERC721(nftContract);
        address owner = msg.sender;

        // Transfer to new owner
        nft.transferFrom(address(this), owner, tokenId);

        // Clear teleport flag
        crossChainTokens[sourceChain][tokenId] = false;

        // Emit claim event (same event reused for clarity)
        emit TokenTeleported(sourceChain, targetChain, tokenId, owner);
    }

    // 3. Admin can manually clear teleport status if incorrect
    function clearTeleportedNFT(string memory sourceChain, uint256 tokenId) external onlyAdmin {
        crossChainTokens[sourceChain][tokenId] = false;
    }

    // 4. Utility: Check if an NFT has been teleported
    function checkTeleportStatus(string memory sourceChain, uint256 tokenId) external view returns (bool) {
        return crossChainTokens[sourceChain][tokenId];
    }
}
