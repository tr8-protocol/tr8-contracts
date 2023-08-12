// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
//import { SchemaResolver } from "./utils/SchemaResolver.sol";
import "@layerzerolabs/solidity-examples/contracts/contracts-upgradable/lzApp/NonblockingLzAppUpgradeable.sol";
import "./interfaces/ITR8Nft.sol";
import "./interfaces/ITR8.sol";

/**
 * @title Transporter for TR8 Protocol
 */
 // 
contract TR8Transporter is Initializable, NonblockingLzAppUpgradeable, ERC2771ContextUpgradeable {

    ITR8 public tr8;

    error NotOwner();

    constructor() ERC2771ContextUpgradeable(0xb539068872230f20456CF38EC52EF2f91AF4AE49) {
        //_disableInitializers();
    }

    function initialize(address _tr8, address _lzEndpoint) initializer public {
        __NonblockingLzAppUpgradeable_init(_lzEndpoint);
        tr8 = ITR8(_tr8);
    }

    event TR8Departed(
        uint256 tokenId,
        address indexed nftAddress,
        uint16 indexed chainId
    );

    function evmEstimateSendFee(uint256 tokenId, uint16 _dstChainId) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(abi.encodePacked(tr8.ownerOf(tokenId)), tokenId, tr8.tokenURI(tokenId));
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, "");
    }

    function send(uint256 tokenId, uint16 _dstChainId) external payable {
        if ( _msgSender() != tr8.ownerOf(tokenId) ) {
            revert NotOwner();
        }
        bytes memory payload = abi.encode(abi.encodePacked(tr8.ownerOf(tokenId)), tokenId, tr8.tokenURI(tokenId));
        _lzSend(_dstChainId, payload, payable(_msgSender()), address(0), "");
        address nftAddress = tr8.getNftForTokenId(tokenId);
        ITR8Nft(nftAddress).depart(tokenId);
        emit TR8Departed(tokenId, nftAddress, _dstChainId);
    }

    function _nonblockingLzReceive(uint16, bytes memory _payload, uint64, bytes memory) internal override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint256 tokenId, string memory uri) = abi.decode(_payload, (bytes, uint, string));
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }
        address nftAddress = tr8.getNftForTokenId(tokenId);
        if (nftAddress == address(0)) {
            // TODO: deploy the nft contract on remote chain
        } else {
            // mint the token
            ITR8Nft(nftAddress).arrive(toAddress, tokenId, uri);
        }
    }

    // The following functions are overrides required by Solidity.

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

}