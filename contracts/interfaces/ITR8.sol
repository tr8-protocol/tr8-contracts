// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface ITR8 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getNftForTokenId(uint256 tokenId) external view returns (address);
    function transporter() external view returns (address);
    function getDataUri(uint256 tokenId) external view returns (string memory);
}
