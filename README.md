# tr8-contracts
contracts for TR8 protocol


### TR8 Protocol Contracts

![TR8 Contracts](https://violet-manual-egret-987.mypinata.cloud/ipfs/QmPLABzvFZf5B7dwD4u4NbuYy8NLgfcmbQapdqaLHZiZL4)

While TR8 users interact primarily through making attestations to the EAS contract, there are several contracts deployed as part of TR8 protocol.

- `TR8.sol` - The TR8 contract provides several functions.  It acts an a EAS `SchemaResolver`, hooks that gets called when each attestation is made or revoked. When a minting/claiming attestation is made, the `onAttest()` hook triggers the minting of the TR8 to eigible attestation recipients. When a "new TR8 drop" attestation is made, the hook triggers the deployment of a dedicated NFT contract for the drop. In this way, the contract also acts as a Factory contract which minimally clones NFT contracts. The attestation includes NFT metadata and access permissions for issuers and claimers, stored onchain within the attestation and/or newly deployed contract. Finally, the `TR8` contract acts a registry for drops and keeps track of reserved _nameSpaces_ for issuers.
- `TR8Nft.sol` - This is the implementation contract for TR8 NFTs. Each drop gets it own contract/collection which gets [cloned](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones) from this contract. These NFTs are cross-chain NFTs that implement the `ERC721Transportable` interface to faciliate arrivals and departures.
- `TR8Transporter.sol` - Powered by LayerZero, this contract is a transport hub for many TR8 NFT contracts. One transporter is deployed per chain and all movement of NFTs move through them. If a transporter detects that a drop NFT contract has not yet been deployed on the destination chain, it calls out to the `TR8` contract on that chain to deploy, at the same address as the home chain.
![TR8 Transporters](https://violet-manual-egret-987.mypinata.cloud/ipfs/QmZt8FYKxYuTgpZsBv8NuduYWdoPY4yWRr9F882vGhYbzw)

#### Optional TR8 Hook contracts

TR8 Protocol is composable, and issuers can create their own `TR8Hook` contracts that get called each time a minting/claiming attestation is made. Hooks can add logic to allow/deny minting, integrate with third party protocols, and thousands of other things. Four example hook contracts were created and deployed:

- `TR8HookNFTClaimer.sol` - This hook enables claiming of a TR8 only if the recipient is a current owner of an NFT from another collection. This could be used to issue TR8s to members of a DAO, or to reward NFT community members.
- `TR8HookNeedEth.sol` - This hook requires the the recipient has some amount of native token (ether). This could be used to limit hoarding/scamming of TR8 drops. One can imagine a similar contract that requires a certain balance of a specific `ERC20` token.
- `TR8HookFaucet.sol` - This hook acts as faucet, sending tokens to eligible recipients. Note that when a hook is specified for a drop, it doesn't override the specified list of claimers who are allowed to mint/claim the TR8. Rather a hook can revert to prevent the issuance of the TR8 or add new addresses to the claimers list. In this example hook, it does neither, but will drip tokens only to those already eligible for the TR8.
- `TR8HookStreamer.sol` - This hook works similar to the faucet, by starts a real-time stream of tokens to the TR8 receipient, powered by the Superfluid protocol. One can imagine gaming applications that perform similar actions.


#### Deployed Contracts Addresses

Note all equivalent contracts are _deployed to the same address on each chain_.

- `TR8Nft` contract: `0x868F83D1c9349B6c7bA793A0D71Dfb66e60e01Ef`: [Optimism](https://goerli-optimism.etherscan.io/address/0x868F83D1c9349B6c7bA793A0D71Dfb66e60e01Ef) - [Base](https://goerli.basescan.org/address/0x868F83D1c9349B6c7bA793A0D71Dfb66e60e01Ef) - [Zora](https://testnet.explorer.zora.energy/address0x868F83D1c9349B6c7bA793A0D71Dfb66e60e01Ef)
- `TR8` contract: `0xC3b0c31C16D341eb09aa3698964369D2b6744108`: [Optimism](https://goerli-optimism.etherscan.io/address/0xC3b0c31C16D341eb09aa3698964369D2b6744108) - [Base](https://goerli.basescan.org/address/0xC3b0c31C16D341eb09aa3698964369D2b6744108) - [Zora](https://testnet.explorer.zora.energy/address/0xC3b0c31C16D341eb09aa3698964369D2b6744108)
- `TR8Transporter` contract: `0x54C9935e58141cc5b1B4417bb478C7D25228Bfc0`: [Optimism](https://goerli-optimism.etherscan.io/address/0x54C9935e58141cc5b1B4417bb478C7D25228Bfc0) - [Base](https://goerli.basescan.org/address/0x54C9935e58141cc5b1B4417bb478C7D25228Bfc0)

Example hook contracts were deployed only to the "home chain", Optimism:
- `TR8HookFaucet` contract: `0x6072fB0F43Bea837125a3B37B3CF04e76ddd3f19`: [Optimism](https://goerli-optimism.etherscan.io/address/0x6072fB0F43Bea837125a3B37B3CF04e76ddd3f19)
- `TR8HookStreamer` contract: `0xFc3d67C7A95c1c051Db54608313Bd62E9Cd38A76`: [Optimism](https://goerli-optimism.etherscan.io/address/0xFc3d67C7A95c1c051Db54608313Bd62E9Cd38A76)
- `TR8HookNFTClaimer` contract: `0x9F570E88B5CDef206d2633aA3278ac5bceCd4cD8`: [Optimism](https://goerli-optimism.etherscan.io/address/0x9F570E88B5CDef206d2633aA3278ac5bceCd4cD8)
- `TR8HookNeedEth` contract: `0x4a62d7B300b505e44066E51B0b635ddb5044955d`: [Optimism](https://goerli-optimism.etherscan.io/address/0x4a62d7B300b505e44066E51B0b635ddb5044955d)