// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

interface ITR8 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getNftForTokenId(uint256 tokenId) external view returns (address);
    function transporter() external view returns (address);
    function getDropAssestationForTokenId(uint256 tokenId) external view returns (Attestation memory);
    function getDataUri(uint256 tokenId) external view returns (string memory);
    function cloneNFT(Attestation memory attestation) external returns (address);
    function homeChain() external view returns (bool);
}
