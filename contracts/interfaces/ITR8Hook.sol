// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

interface ITR8Hook {
    function onMint(Attestation calldata attestation, uint256 value, address nftAddress) external returns (bool);
    function onBurn(Attestation calldata attestation, uint256 value, address nftAddress) external returns (bool);
}
