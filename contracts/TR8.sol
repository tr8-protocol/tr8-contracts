// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import { SchemaResolver } from "./utils/SchemaResolver.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "@layerzerolabs/solidity-examples/contracts/contracts-upgradable/lzApp/NonblockingLzAppUpgradeable.sol";

// TODO: finalize interface
interface ITR8Nft {
    //function initialize(string calldata _name, string calldata _symbol, address _admin, address _owner, address hook, address[] calldata issuers, address[] calldata claimers, bool allowTransfers) external;
    function initialize(Attestation calldata attestation) external;
    function mint(address to, uint256 value) external;
    function safeMint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function burn(uint256 tokenId) external;
}

interface ITR8Hook {
    function onMint(Attestation calldata attestation, uint256 value, address nftAddress) external returns (bool);
    function onBurn(Attestation calldata attestation, uint256 value, address nftAddress) external returns (bool);
}

/**
 * @title EAS Resolver, NFT Factory, and Transporter for TR8 Protocol
 */
contract TR8 is Initializable, SchemaResolver, NonblockingLzAppUpgradeable, ERC2771ContextUpgradeable {
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

    //constructor(IEAS eas, address _lzEndpoint)
    //    SchemaResolver(eas) 
    //    ERC2771Context(0xb539068872230f20456CF38EC52EF2f91AF4AE49) 
    //    NonblockingLzApp(_lzEndpoint) 
    //{}

    constructor() ERC2771ContextUpgradeable(0xb539068872230f20456CF38EC52EF2f91AF4AE49) {
        //_disableInitializers();
    }

    function initialize(IEAS eas, address _lzEndpoint, address _nftImplementation) initializer public {
        __SchemaResolver_init(eas);
        __NonblockingLzAppUpgradeable_init(_lzEndpoint);
        nftImplementation = _nftImplementation;
    }

    struct Attribute {
        string key;
        string value;
    }

    event TR8DropCreated(
        address indexed owner,
        address nftContract
    );

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

    function onRevoke(Attestation calldata attestation, uint256 value) internal override returns (bool) {
        Attestation memory drop = _eas.getAttestation(attestation.refUID);
        (/*string memory _nameSpace*/, /*string memory _name*/, /*string memory _symbol*/, /*string memory description*/, /*string memory image*/, address hook, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(drop.data, (string, string, string, string, string, address, address[], address[], string, Attribute[], string[], bool));
        // call hook
        if (hook != address(0)) {
            ITR8Hook(hook).onBurn(attestation, value, nftForDrop[attestation.refUID]);
        }
        if ( ITR8Nft(nftForDrop[attestation.refUID]).exists(uint256(attestation.uid)) ) {
            ITR8Nft(nftForDrop[attestation.refUID]).burn(uint256(attestation.uid));
        }
        return true;
    }

    function _newMint(Attestation calldata attestation, uint256 value) internal returns (bool) {
        if (nftForDrop[attestation.refUID] == address(0)) {
            revert InvalidDrop();
        }
        Attestation memory drop = _eas.getAttestation(attestation.refUID);
        if (drop.expirationTime < block.timestamp) {
            // minting period has ended
            revert ExpiredDrop();
        }
        (/*string memory _nameSpace*/, /*string memory _name*/, /*string memory _symbol*/, /*string memory description*/, /*string memory image*/, address hook, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(drop.data, (string, string, string, string, string, address, address[], address[], string, Attribute[], string[], bool));
        // call hook
        if (hook != address(0)) {
            // hook can revert or add MINTER_ROLE to recipient or ISSUER_ROLE to attester ... and do other stuff
            ITR8Hook(hook).onMint(attestation, value, nftForDrop[attestation.refUID]);
        }
        if ( ITR8Nft(nftForDrop[attestation.refUID]).hasRole(ISSUER_ROLE, attestation.attester) ||
            ITR8Nft(nftForDrop[attestation.refUID]).hasRole(MINTER_ROLE, attestation.recipient) ) {
            // recipient gets NFT
            ITR8Nft(nftForDrop[attestation.refUID]).safeMint(attestation.recipient, uint256(attestation.uid));
        }
        return true;
    }

    // TR8 Factory

    function _newDrop(Attestation calldata attestation) internal returns (bool) {
        (string memory _nameSpace, /*string memory _name*/, /*string memory _symbol*/, /*string memory description*/, /*string memory image*/, /*address hook*/, /*address[] memory claimers*/, /*address[] memory issuers*/, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, /*bool allowTransfers*/) = abi.decode(attestation.data, (string, string, string, string, string, address, address[], address[], string, Attribute[], string[], bool));
        //nftForDrop[attestation.uid] = _cloneNFT(attestation.uid, _name, _symbol, attestation.attester, hook, issuers, claimers, allowTransfers);
        nftForDrop[attestation.uid] = _cloneNFT(attestation);
        if (_nameSpaceExists(_nameSpace)) {
            if (!_ownsNameSpace(attestation.attester, _nameSpace)) {
                revert InvalidNameSpace();
            }
        } else {
            nftsForNameSpace[keccak256(abi.encodePacked(_nameSpace))].push(nftForDrop[attestation.uid]);
        }
        return true;
    }

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
    // xfunction _cloneNFT(bytes32 salt, string memory _name, string memory _symbol, address owner, address hook, address[] memory issuers, address[] memory claimers, bool allowTransfers) internal returns (address) {
    function _cloneNFT(Attestation calldata attestation) internal returns (address) {
        address clone = Clones.cloneDeterministic(nftImplementation, attestation.uid);
        //ITR8Nft(clone).initialize(_name, _symbol, _msgSender(), owner, hook, issuers, claimers, allowTransfers);
        ITR8Nft(clone).initialize(attestation);
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

    // LayerZero Transporter
    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory) internal override {
        // TODO
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

}
