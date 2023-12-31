// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import { SchemaResolver } from "./utils/SchemaResolver.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "./interfaces/ITR8Nft.sol";
import "./hooks/ITR8Hook.sol";

/**
 * @title EAS Resolver, NFT Factory, and Transporter for TR8 Protocol
 */
 // 
contract TR8 is Initializable, SchemaResolver, ERC2771ContextUpgradeable, OwnableUpgradeable {
    //using Address for address;

    bool public homeChain;
    // links a drop creation attestation to the cloned NFT contract
    mapping(bytes32 => address) public nftForDrop;
    // links a cloned NFT contract to the drop creation attestation
    mapping(address => bytes32) public dropForNft;
    // links a namespace to the cloned NFT contract
    mapping(bytes32 => address[]) nftsForNameSpace;

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // Factory variables
    address nftImplementation;
    address public transporter;
    bytes32 dropSchema;

    error InvalidDrop();
    error ExpiredDrop();
    error AlreadyMinted();
    error NotAuthorized();
    error InvalidNameSpace();

    constructor() ERC2771ContextUpgradeable(0xb539068872230f20456CF38EC52EF2f91AF4AE49) {
        //_disableInitializers();
    }

    function initialize(IEAS eas, address _nftImplementation, address _transporter) initializer public {
        __SchemaResolver_init(eas);
        __Ownable_init();
        nftImplementation = _nftImplementation;
        transporter = _transporter;
        _transferOwnership(_msgSender());
    }

    struct Attribute {
        string key;
        string value;
    }

    struct Drop {
        string nameSpace;
        string name;
        string symbol;
        string description;
        string image;
    }

    event TR8DropCreated(
        address indexed owner,
        string nameSpace,
        address nftAddress,
        bytes32 indexed uid
    );

    function setDropSchema(bytes32 _dropSchema) external onlyOwner {
        dropSchema = _dropSchema;
    }
    function setHomeChain(bool _homeChain) external onlyOwner {
        homeChain = _homeChain;
    }

    // EAS Schema Resolver:

    function onAttest(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        if (attestation.schema == dropSchema) {
            // This is a drop creation attestation
            return _newDrop(attestation);
        } else {
            // This is a minting attestation
            return _newMint(attestation, value);
        }
    }

    function _newMint(Attestation calldata attestation, uint256 value) internal returns (bool) {
        if (nftForDrop[attestation.refUID] == address(0)) {
            revert InvalidDrop();
        }
        if (_eas.getAttestation(attestation.refUID).expirationTime > 0 &&
            _eas.getAttestation(attestation.refUID).expirationTime < block.timestamp) {
            // minting period has ended
            revert ExpiredDrop();
        }
        if (ITR8Nft(nftForDrop[attestation.refUID]).balanceOf(attestation.recipient) > 0) {
            // recipient already has an NFT
            revert AlreadyMinted();
        }
        // call hook
        address hook = ITR8Nft(nftForDrop[attestation.refUID]).hook();
        if (hook != address(0)) {
            // hook can revert or add MINTER_ROLE to recipient or ISSUER_ROLE to attester ... and do other stuff
            ITR8Hook(hook).onMint(attestation, value, nftForDrop[attestation.refUID]);
        }
        if ( ITR8Nft(nftForDrop[attestation.refUID]).hasRole(ISSUER_ROLE, attestation.attester) ||
            ITR8Nft(nftForDrop[attestation.refUID]).hasRole(MINTER_ROLE, attestation.recipient) ) {
            // recipient gets NFT
            ITR8Nft(nftForDrop[attestation.refUID]).safeMint(attestation.recipient, uint256(attestation.uid), "");
        } else {
            // recipient does not get NFT
            revert NotAuthorized();
        }
        return true;
    }

    function onRevoke(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        (/*Drop memory metadata*/, address hook, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(_eas.getAttestation(attestation.refUID).data, (Drop, address, address[], address[], string, Attribute[], string[], bool));
        // call hook
        if (hook != address(0)) {
            ITR8Hook(hook).onBurn(attestation, value, nftForDrop[attestation.refUID]);
        }
        if ( ITR8Nft(nftForDrop[attestation.refUID]).exists(uint256(attestation.uid)) ) {
            ITR8Nft(nftForDrop[attestation.refUID]).burn(uint256(attestation.uid));
        }
        return true;
    }
    

    // public functions

    function nameSpaceExists(string calldata _nameSpace) external view returns (bool) {
        return _nameSpaceExists(_nameSpace);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return ITR8Nft(nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID]).tokenURI(tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return ITR8Nft(nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID]).ownerOf(tokenId);
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        return ITR8Nft(nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID]).exists(tokenId);
    }

    function getAssestationForTokenId(uint256 tokenId) external view returns (Attestation memory) {
        return _eas.getAttestation(bytes32(tokenId));
    }

    function getNftsForNameSpace(string calldata _nameSpace) external view returns (address[] memory) {
        return nftsForNameSpace[keccak256(abi.encodePacked(_nameSpace))];
    }

    function getNftForTokenId(uint256 tokenId) external view returns (address) {
        return nftForDrop[_eas.getAttestation(bytes32(tokenId)).refUID];
    }

    function getDropAssestationForTokenId(uint256 tokenId) external view returns (Attestation memory) {
        return _eas.getAttestation(_eas.getAttestation(bytes32(tokenId)).refUID);
    }

    function getDataUri(uint256 tokenId) external view returns (string memory) {
        (Drop memory metadata, /*address hook*/, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, Attribute[] memory attributes, string[] memory tags, bool allowTransfers) = abi.decode(this.getDropAssestationForTokenId(tokenId).data, (Drop, address, address[], address[], string, Attribute[], string[], bool));
        string memory attributesString;
        for (uint i = 0; i < attributes.length; i++) {
            if (i > 0) {
                attributesString = string.concat(attributesString, ', ');
            }
            attributesString = string.concat(attributesString, '{ "trait_type": "', attributes[i].key, '", "value": "', attributes[i].value, '"}');
        }
        if (allowTransfers) {
            attributesString = string.concat(attributesString, ', { "trait_type": "transferable", "value": "true"}');
        } else {
            attributesString = string.concat(attributesString, ', { "trait_type": "transferable", "value": "false"}');
        }
        string memory tagsString;
        for (uint i = 0; i < tags.length; i++) {
            if (i > 0) {
                tagsString = string.concat(tagsString, ', ');
            }
            tagsString = string.concat(tagsString, '"', tags[i], '"');
        }
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                abi.encodePacked(
                    '{"name":"', metadata.name, '", "description":"', metadata.description, '", "image":"', metadata.image, '", "tags": [', tagsString, '], "attributes":[', attributesString, ']}'
                )
            )
        ));
    }

    // TR8 Factory

    function _newDrop(Attestation calldata attestation) internal returns (bool) {
        (Drop memory metadata, /*address hook*/, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(attestation.data, (Drop, address, address[], address[], string, Attribute[], string[], bool));
        nftForDrop[attestation.uid] = _cloneNFT(attestation, metadata.nameSpace);
        dropForNft[nftForDrop[attestation.uid]] = attestation.uid;
        if (_nameSpaceExists(metadata.nameSpace)) {
            if (!_ownsNameSpace(attestation.attester, metadata.nameSpace)) {
                revert InvalidNameSpace();
            }
        }
        nftsForNameSpace[keccak256(abi.encodePacked(metadata.nameSpace))].push(nftForDrop[attestation.uid]);
        return true;
    }

    function cloneNFT(Attestation calldata attestation) external returns (address) {
        if (_msgSender() != transporter) {
            revert NotAuthorized();
        }
        (Drop memory metadata, /*address hook*/, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(attestation.data, (Drop, address, address[], address[], string, Attribute[], string[], bool));
        return _cloneNFT(attestation, metadata.nameSpace);
    }

    // @dev deploys a TR8Nft contract
    function _cloneNFT(Attestation calldata attestation, string memory nameSpace) internal returns (address) {
        address clone = Clones.cloneDeterministic(nftImplementation, attestation.uid);
        ITR8Nft(clone).initialize(attestation);
        emit TR8DropCreated(_msgSender(), nameSpace, clone, attestation.uid);
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

    // The following functions are overrides required by Solidity.

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

}
