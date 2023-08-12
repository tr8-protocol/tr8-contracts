// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import { ITR8Hook } from "../ITR8Hook.sol";
import { ITR8Nft } from "../../interfaces/ITR8Nft.sol";

/**
 * @title A TR8Hook that grants the MINTER_ROLE if the attestation recipient already owns an NFT in a specifid collection.
 */

contract TR8HookNFTClaimer is ITR8Hook {

    IERC721 public nft;

    constructor(address _nft) {
        nft = IERC721(_nft);
    }

    function onMint(
        Attestation calldata attestation,
        uint256,
        address nftAddress
    ) external override returns (bool) {
        if (nft.balanceOf(attestation.recipient) > 0) {
            ITR8Nft(nftAddress).grantRole(keccak256("MINTER_ROLE"), attestation.recipient);
        }
        return true;
    }

    function onBurn(
        Attestation calldata,
        uint256,
        address
    ) external pure returns (bool) {
        return true;
    }
    
}