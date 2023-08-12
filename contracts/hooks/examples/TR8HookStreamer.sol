// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import { ITR8Hook } from "../ITR8Hook.sol";
import { ISuperfluid, ISuperToken, ISuperAgreement } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperTokenFactory } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";
import { INativeSuperToken } from "./superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/INativeSuperToken.sol"; 
import { NativeSuperTokenProxy } from "./superfluid-finance/ethereum-contracts/contracts/tokens/NativeSuperToken.sol";
import { CFAv1Library } from "./superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

/**
 * @title A TR8Hook that streams tokens to valid recipients. Optimism-Goerli contracts hardcoded for this example.
 */

contract TR8HookStreamer is ITR8Hook {
    using CFAv1Library for CFAv1Library.InitData;

    ISuperTokenFactory private _superTokenFactory;
    INativeSuperToken public token;
    ISuperfluid _host;
    IConstantFlowAgreementV1 _cfa;
    CFAv1Library.InitData public cfaV1;
    int96 flowRate;

    constructor() {
        token = INativeSuperToken(address(new NativeSuperTokenProxy()));
        _superTokenFactory = ISuperTokenFactory(0xfafe31cf998Df4e5D8310B03EBa8fb5bF327Eaf5);
        _superTokenFactory.initializeCustomSuperToken(address(token));
        token.initialize("Super Streaming Token", "SST", 420000000000000000000000000000000, address(this));
        _host = ISuperfluid(0xE40983C2476032A0915600b9472B3141aA5B5Ba9);
        _cfa = IConstantFlowAgreementV1(0xff48668fa670A85e55A7a822b352d5ccF3E7b18C);
        cfaV1 = CFAv1Library.InitData(_host, IConstantFlowAgreementV1(address(_host.getAgreementClass(keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")))));
        flowRate = 1000000000000000000;
    }

    function onMint(
        Attestation calldata attestation,
        uint256,
        address
    ) external override returns (bool) {
        cfaV1.flow(attestation.recipient, token, flowRate);
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