// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IERC721Transportable {
    function depart(uint256 tokenId) external;
    function arrive(address to, uint256 tokenId, string calldata uri) external;
}
