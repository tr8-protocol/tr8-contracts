// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { SchemaResolver } from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

// TODO: finalize interface
interface ITR8Nft {
    function initialize(string calldata _name, string calldata _symbol, address _admin, address _owner) external;
    function mint(address to, uint256 value) external;
    function safeMint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

/**
 * @title EAS Resolver, NFT Factory, and Transporter for TR8 Protocol
 */
contract TR8 is SchemaResolver, ERC2771Context {
    //using Address for address;

    bool public homeChain;
    // links a drop creation attestation to the cloned NFT contract
    mapping(bytes32 => address) public nftForDrop;
    // links a namespace to the cloned NFT contract
    mapping(bytes32 => address[]) public nftsForNameSpace;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // Factory variables
    address public nftImplementation;
    bytes32 public dropSchema;

    error InvalidDrop();
    error ExpiredDrop();
    error InvalidNameSpace();

    constructor(IEAS eas) SchemaResolver(eas) ERC2771Context(0xb539068872230f20456CF38EC52EF2f91AF4AE49) {}


    event TR8DropCreated(
        address indexed owner,
        address nftContract
    );

    // EAS Schema Resolver:

    function onAttest(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        // TODO: check schema? 
        // TODO: check for drop creation schema first?
        if (attestation.schema == dropSchema) {
            // This is a drop creation attestation
            (string memory _name, string memory _symbol, string memory _nameSpace) = abi.decode(attestation.data, (string, string, string));
            nftForDrop[attestation.uid] = _cloneNFT(attestation.schema, _name, _symbol, attestation.attester);
            // check nameSpace is owned by attester
            if (_nameSpaceExists(_nameSpace)) {
                if (!_ownsNameSpace(attestation.attester, _nameSpace)) {
                    revert InvalidNameSpace();
                }
            } else {
                nftsForNameSpace[keccak256(abi.encodePacked(_nameSpace))].push(nftForDrop[attestation.uid]);
            }
        } else {
            // This is a minting attestation
            if (nftForDrop[attestation.refUID] == address(0)) {
                revert InvalidDrop();
            }
            Attestation memory drop = _eas.getAttestation(attestation.refUID);
            if (drop.expirationTime < block.timestamp) {
                // minting period has ended
                revert ExpiredDrop();
            }
            // TODO: call hook

            // TODO: who gets NFT? attester or receipient? or always recipeint regardless of who attested?
            ITR8Nft(nftForDrop[attestation.refUID]).safeMint(attestation.recipient, uint256(attestation.uid));
        }

        return true;
    }

    function onRevoke(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        // TODO: check schema?

        // TODO: call hook

        return true;
    }

    // TR8 Factory

    // public functions
    function nameSpaceExists(string calldata _nameSpace) external view returns (bool) {
        return _nameSpaceExists(_nameSpace);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        address nftAddress = nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID];
        return ITR8Nft(nftAddress).tokenURI(tokenId);
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        address nftAddress = nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID];
        return ITR8Nft(nftAddress).exists(tokenId);
    }

    function getAssestationForTokenId(uint256 tokenId) external view returns (Attestation memory) {
        return _eas.getAttestation(bytes32(tokenId));
    }

    // @dev deploys a TR8Nft contract
    function _cloneNFT(bytes32 salt, string memory _name, string memory _symbol, address owner) internal returns (address) {
        address clone = Clones.cloneDeterministic(nftImplementation, salt);
        ITR8Nft(clone).initialize(_name, _symbol, _msgSender(), owner);
        emit TR8DropCreated(_msgSender(), clone);
        return clone;
    }

    function _ownsNameSpace(address attestor, string memory _nameSpace) internal view returns (bool authorized) {
       if (_nameSpaceExists(_nameSpace)) {
            // must have ISSUER_ROLE on the first NFT in the namespace
            authorized = ITR8Nft(
                nftsForNameSpace[keccak256(abi.encodePacked(_nameSpace))][0]
            ).hasRole(ISSUER_ROLE, attestor);   
        }
    }

    function _nameSpaceExists(string memory _nameSpace) internal view returns (bool) {
        return nftsForNameSpace[keccak256(abi.encodePacked(_nameSpace))].length > 0;
    }

}
