const { expect } = require("chai");
const { ethers } = require("hardhat");

const networkName = hre.network.name;

require('dotenv').config();
//var BN = web3.utils.BN;

const chain = hre.network.name;

var addr = {};
if (chain == "optimisticGoerli") {
  addr.lzEndpoint = "0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1";
  addr.chainId = 10132;
  addr.eas = "0x4200000000000000000000000000000000000021";
  addr.tr8 = "0x4F8436A221f248274D488bB6C44cBdbbAC11984c";
}
if (chain == "baseGoerli") {
  addr.lzEndpoint = "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab";
  addr.chainId = 10160;
  addr.eas = "0xAcfE09Fd03f7812F022FBf636700AdEA18Fd2A7A"
}

const dropSchemaUid = "0x3a70fdf707fe6578bb9abbecee6093edea3c6036a4f4cbf6ef1e4ba685ca8b65";
const mintSchemaUid = "0x969e90ca2aee47607bcbea9e0c8de9aaa09a27fbf73b5102af6aa0d475088e56";
const easJSON = require("./abis/EAS.json");

const signer = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
const eas = new ethers.Contract(addr.eas, easJSON.abi, signer);

describe("TR8 New Drop Attestation", function () {

    var attestationUid;
    const nameSpace = "myOrg";
    const name = "My Drop";
    const symbol = "MD";
    const description = "This drop includes streaming super tokens";
    const image = "ipfs://QmeYJPjen9GXU9LSDdi8BR52GpWoDpkLEYZjTGPr2rV1f5";
    const metadata = {
        "nameSpace": nameSpace,
        "name": name,
        "symbol": symbol,
        "description": description,
        "image": image
    };
    //const hook = "0x0000000000000000000000000000000000000000";  // no hook
    //const hook = "0x6072fB0F43Bea837125a3B37B3CF04e76ddd3f19"; // TR8HookFaucet
    const hook = "0xFc3d67C7A95c1c051Db54608313Bd62E9Cd38A76"; // TR8HookStreamer
    const claimers = [
        "0x3Bb902ffbd079504052c8137Be7165e12F931af2" // onRamp Joe
    ];
    const admins = [
        "0x3ADB96227538B3251B87F5ec6fba245607B1BD7A", // MultiDeployer
        "0xc2feE563aCf6C5Bb490944750c9332d56Da46445" // AIrtist HW
    ];
    const secret = "";
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
    const tags = ["event", "hackathon"];
    const allowTransfers = false;

    it("should make a new Drop attestation", async function() {
        const data = ethers.utils.defaultAbiCoder.encode(["tuple(string nameSpace, string name, string symbol, string description, string image)", "address", "address[]", "address[]", "string", "tuple(string key, string value)[]", "string[]", "bool"], [metadata, hook, claimers, admins, secret, attributes, tags, allowTransfers]);
        const attestationRequestData = {
            "recipient": addr.tr8,
            "expirationTime": 0,
            "revocable": false,
            "refUID": ethers.constants.HashZero,
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

    it("Should make a mint attestation", async function () {
        if (!attestationUid) {
            attestationUid = "0x59a1b2af1e743015fa98833977a88037da80182500114f3b1da3622ea86b2dd8";
        }
        const mint = true;
        const extras = [
            {"key": "foo", "value": "bar"}
        ];
        const data = ethers.utils.defaultAbiCoder.encode(["bool", "tuple(string key, string value)[]"], [mint, extras]);
        const attestationRequestData = {
            "recipient": "0xc2feE563aCf6C5Bb490944750c9332d56Da46445",
            "expirationTime": 0,
            "revocable": true,
            "refUID": attestationUid,
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
        const mintAttestationUid = attestedEvent.args[2];
        console.log(mintAttestationUid);
        //await expect(eas.attest(attestationRequest))
        //    .to.emit(eas, 'Attested');
        expect(mintAttestationUid).to.not.be.null;
    });

});


