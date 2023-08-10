// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import { SchemaResolver } from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

// TODO: finalize interface
interface ITR8Nft {
    function initialize(string calldata _name, string calldata _symbol, address _admin, address _owner) external;
    function mint(address to, uint256 value) external;
}

/**
 * @title EAS Resolver, NFT Factory, and Transporter for TR8 Protocol
 */
contract TR8 is SchemaResolver {
    //using Address for address;

    // links a drop creation attestation to the cloned NFT contract
    mapping(bytes32 => address) public nftForDrop;

    // Factory variables
    address public nftImplementation;
    bytes32 public dropSchema;

    error InvalidDrop();
    error ExpiredDrop();

    constructor(IEAS eas) SchemaResolver(eas) {}




    // EAS Schema Resolver:

    function onAttest(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        // TODO: check schema? 
        // TODO: check for drop creation schema first?
        if (attestation.schema == dropSchema) {
            // This is a drop creation attestation
            (string _name, string _symbol, string _nameSpace) = abi.decode(attestation.data, (string, string, string));
            // TODO: check nameSpace
            nftForDrop[attestation.uid] = _cloneNFT(attestation.schema, _name, _symbol, attestation.attester);
        } else {
            // This is a minting attestation
            if (nftForDrop[attestation.refUID] == address(0)) {
                revert InvalidDrop();
            }
            Attestation drop = _eas.getAttestation(attestation.refUID);
            if (drop.expirationTime < block.timestamp) {
                // minting period has ended
                revert ExpiredDrop();
            }
            // TODO: call hook

            // TODO: who gets NFT? attester or receipient?
            ITR8Nft(nftForDrop[attestation.refUID]).mint(attestation);
        }

        return true;
    }

    function onRevoke(Attestation calldata attestation, uint256 /*value*/) internal override returns (bool) {
        // TODO: check schema?

        // TODO: call hook

        return true;
    }

    // TR8 Factory

    // @dev deploys a TR8Nft contract
    function _cloneNFT(bytes32 salt, string calldata _name, string calldata _symbol, address owner) internal returns (address) {
        address clone = Clones.cloneDeterministic(nftImplementation, salt);
        ITR8Nft(clone).initialize(_name, _symbol, _msgSender(), owner);
        emit TR8DropCreated(_msgSender(), clone);
        return clone;
    }

}
