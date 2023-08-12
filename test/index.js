const { expect } = require("chai");
const { ethers } = require("hardhat");

const networkName = hre.network.name;

require('dotenv').config();
//var BN = web3.utils.BN;

const chain = hre.network.name;

const easJSON = require("./abis/EAS.json");
const tr8JSON = require("../artifacts/contracts/TR8.sol/TR8.json");
const transporterJSON = require("../artifacts/contracts/TR8Transporter.sol/TR8Transporter.json");
const { base } = require("mocha/lib/reporters");

var addr = {};
if (chain == "optimisticGoerli") {
  addr.lzEndpoint = "0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1";
  addr.chainId = 10132;
  addr.eas = "0x4200000000000000000000000000000000000021";
  addr.tr8 = "0x4F8436A221f248274D488bB6C44cBdbbAC11984c";
  addr.transporter = "0x5e1D5043e87Dd16F0422d3C6c9f5FFA18394aFE0";
}
if (chain == "baseGoerli") {
  addr.lzEndpoint = "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab";
  addr.chainId = 10160;
  addr.eas = "0xAcfE09Fd03f7812F022FBf636700AdEA18Fd2A7A"
}

var dstChainIds = {
    "optimisticGoerli": 10132,
    "baseGoerli": 10160
};

const dropSchemaUid = "0x3a70fdf707fe6578bb9abbecee6093edea3c6036a4f4cbf6ef1e4ba685ca8b65";
const mintSchemaUid = "0x969e90ca2aee47607bcbea9e0c8de9aaa09a27fbf73b5102af6aa0d475088e56";

const signer = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
const eas = new ethers.Contract(addr.eas, easJSON.abi, signer);
const tr8 = new ethers.Contract(addr.tr8, tr8JSON.abi, signer);
const transporter = new ethers.Contract(addr.transporter, transporterJSON.abi, signer);

describe("TR8 New Drop Attestation", function () {

    var attestationUid;
    const nameSpace = "myOrg";
    const name = "My Drop";
    const symbol = "MD";
    const description = "This drop includes streaming super tokens";
    const image = "ipfs://QmeYJPjen9GXU9LSDdi8BR52GpWoDpkLEYZjTGPr2rV1f5";
    // each of the 5 elements of metadata is a string
    const metadata = {
        "nameSpace": nameSpace,
        "name": name,
        "symbol": symbol,
        "description": description,
        "image": image
    };

    // hook can be the zero address for no hook, or a contract address:
    //const hook = "0x0000000000000000000000000000000000000000";  // no hook
    //const hook = "0x6072fB0F43Bea837125a3B37B3CF04e76ddd3f19"; // TR8HookFaucet
    const hook = "0xFc3d67C7A95c1c051Db54608313Bd62E9Cd38A76"; // TR8HookStreamer
    // claimers is an array of addresses that can claim a TR8 from the contract
    const claimers = [
        "0x3Bb902ffbd079504052c8137Be7165e12F931af2" // onRamp Joe
    ];
    // the admins or issuers is an array of addresses that can issue TR8s to any address
    // the attester (drop creator) does not need to be added here, as it will become an issuer
    const admins = [
        "0x3ADB96227538B3251B87F5ec6fba245607B1BD7A", // MultiDeployer
        "0xc2feE563aCf6C5Bb490944750c9332d56Da46445" // AIrtist HW
    ];
    const secret = "";  // unused, leave blank
    // attributes is an array of key/value pairs, can be an empty array, but both key and value must be strings
    const attributes = [
        {
            "key": "startDate",
            "value": "01-Jun-2023"
        },
        {
            "key": "endDate",
            "value": "30-Jun-2023"
        },
        {
            "key": "virtualEvent",
            "value": "true"
        },
        {
            "key": "city",
            "value": "Toronto"
        },
        {
            "key": "country",
            "value": "Canada"
        },
        {
            "key": "eventURL",
            "value": "https://superfluid.finance/"
        }
    ];
    // tags is an array of strings, can be an empty array
    const tags = ["event", "hackathon"];
    // allowTransfers is a boolean, true if the TR8 can be transferred, false if not
    const allowTransfers = false;

    it.skip("should make a new Drop attestation", async function() {
        const data = ethers.utils.defaultAbiCoder.encode(["tuple(string nameSpace, string name, string symbol, string description, string image)", "address", "address[]", "address[]", "string", "tuple(string key, string value)[]", "string[]", "bool"], [metadata, hook, claimers, admins, secret, attributes, tags, allowTransfers]);
        const attestationRequestData = {
            "recipient": addr.tr8,
            "expirationTime": 0,  // 0 means no expiration, a unix timestamp can be used as and END date for minting
            "revocable": false, // should be false for drop attestations
            "refUID": ethers.constants.HashZero, // should be byte32 zero for drop attestations
            "data": data,
            "value": 0
        };
        const attestationRequest = {
            "schema": dropSchemaUid,
            "data": attestationRequestData
        };
        const txn = await eas.attest(attestationRequest);
        const { events } = await txn.wait();
        const attestedEvent = events.find(x => x.event === "Attested");
        attestationUid = attestedEvent.args[2];
        console.log(attestationUid);
        //await expect(eas.attest(attestationRequest))
        //    .to.emit(eas, 'Attested');
        expect(attestationUid).to.not.be.null;
    });

    it("Should get an attestation", async function () {
        if (!attestationUid) {
            this.skip();
        }
        const attestation = await eas.getAttestation(attestationUid);
        console.log(attestation);
        expect(attestation.uid).to.equal(attestationUid);
    });

    var mintAttestationUid;

    it("Should make a mint attestation", async function () {
        if (!attestationUid) {
            attestationUid = "0x80939d4f740539974cad692f9403085bbdf831a8feac5d9b5dd78f5e26200103";
        }
        // the mint and extras vars are not really used, but must be included. 
        // extras can be an empty array, but both key and value must be strings
        // extras can used for any purpose of the issuer, but not currently used by the TR8 contracts
        const mint = true;
        const extras = [
            {"key": "foo", "value": "bar"}
        ];
        const data = ethers.utils.defaultAbiCoder.encode(["bool", "tuple(string key, string value)[]"], [mint, extras]);
        const attestationRequestData = {
            "recipient": "0xc2feE563aCf6C5Bb490944750c9332d56Da46445", // gets the TR8
            "expirationTime": 0,
            "revocable": true,
            "refUID": attestationUid, // IMPORTANT: the attestation UID of the drop
            "data": data,
            "value": 0
        };
        const attestationRequest = {
            "schema": mintSchemaUid,
            "data": attestationRequestData
        };
        const txn = await eas.attest(attestationRequest);
        const { events } = await txn.wait();
        const attestedEvent = events.find(x => x.event === "Attested");
        mintAttestationUid = attestedEvent.args[2];
        console.log(mintAttestationUid);
        //await expect(eas.attest(attestationRequest))
        //    .to.emit(eas, 'Attested');
        expect(mintAttestationUid).to.not.be.null;
    });

    it("Should send a TR8 to Base Goerli", async function () {
        if (!mintAttestationUid) {
            this.skip();
        }
        const tokenId = new BigNumber(mintAttestationUid);
        console.log(tokenId);
        const fees = await transporter.evmEstimateSendFee(tokenId, dstChainIds.baseGoerli);
        console.log(fees);
        const txn = await transporter.send(tokenId, dstChainIds.baseGoerli, {"value": ''+fees[0]});
        const { events } = await txn.wait();
        expect(1).to.equal(1); // TODO: change this
    });

});


