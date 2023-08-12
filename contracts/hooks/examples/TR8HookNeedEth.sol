// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import { ITR8Hook } from "../ITR8Hook.sol";

/**
 * @title A TR8Hook that requires recipients to have a balance of Ether.
 */

contract TR8HookFaucet is ITR8Hook {

    constructor() {}

    error InsufficientBalance();

    function onMint(
        Attestation calldata attestation,
        uint256,
        address
    ) external view returns (bool) {
        if (attestation.recipient.balance == 0) {
            revert InsufficientBalance();
        }
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