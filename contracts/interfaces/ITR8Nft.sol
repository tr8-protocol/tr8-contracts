// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

interface ITR8Nft {
    //function initialize(string calldata _name, string calldata _symbol, address _admin, address _owner, address hook, address[] calldata issuers, address[] calldata claimers, bool allowTransfers) external;
    function initialize(Attestation calldata attestation) external;
    function mint(address to, uint256 value) external;
    function safeMint(address to, uint256 tokenId, string calldata uri) external;
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function burn(uint256 tokenId) external;
    function hook() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function depart(uint256 tokenId) external;
    function arrive(address to, uint256 tokenId, string calldata uri) external;
}
