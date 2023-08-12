// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import "./interfaces/IERC721Transportable.sol";
import "./interfaces/ITR8.sol";

contract TR8Nft is Initializable, IERC721Transportable, ERC721Upgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");

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

    ITR8 public tr8;
    address public hook;
    bool public allowTransfers;

    error NotTransferrable();
    error NotTR8();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(Attestation calldata attestation) initializer public {
        (Drop memory metadata, address _hook, address[] memory claimers, address[] memory issuers, /*string memory secret*/, /*Attribute[] memory attributes*/, /*string[] memory tags*/, bool _allowTransfers) = abi.decode(attestation.data, (Drop, address, address[], address[], string, Attribute[], string[], bool));
        __ERC721_init(metadata.name, metadata.symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _hook);
        _grantRole(DEFAULT_ADMIN_ROLE, attestation.attester);
        _grantRole(ISSUER_ROLE, _hook);
        _grantRole(ISSUER_ROLE, attestation.attester);
        _grantRole(PAUSER_ROLE, _hook);
        _grantRole(PAUSER_ROLE, attestation.attester);
        for(uint i = 0; i < claimers.length; i++) {
            _grantRole(MINTER_ROLE, claimers[i]);
        }
        for(uint i = 0; i < issuers.length; i++) {
            _grantRole(ISSUER_ROLE, issuers[i]);
        }
        hook = _hook;
        allowTransfers = _allowTransfers;
        tr8 = ITR8(msg.sender);
        _grantRole(TRANSPORTER_ROLE, tr8.transporter());
        _transferOwnership(attestation.attester);
    }

    modifier onlyTR8 {
        if (msg.sender != address(tr8)) {
            revert NotTR8();
        }
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string calldata uri)
        public
        onlyTR8
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function depart(uint256 tokenId)
        public
        override
        whenNotPaused
        onlyRole(TRANSPORTER_ROLE)
    {
        _burn(tokenId);
    }

    function arrive(address to, uint256 tokenId, string memory uri)
        public
        override
        whenNotPaused
        onlyRole(TRANSPORTER_ROLE)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        if (!allowTransfers) {
            if (from != address(0)) {
                revert NotTransferrable();
            }
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        if (bytes(super.tokenURI(tokenId)).length > 0) {
            return super.tokenURI(tokenId);
        } else {
            return tr8.getDataUri(tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}