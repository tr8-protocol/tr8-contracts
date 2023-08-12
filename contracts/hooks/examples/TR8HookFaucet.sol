// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IEAS, Attestation } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import { ITR8Hook } from "../ITR8Hook.sol";
import { ITR8Nft } from "../../interfaces/ITR8Nft.sol";

/**
 * @title A TR8Hook that sends tokens to valid recipients.
 */

contract TR8HookFaucet is ITR8Hook, ERC20 {

    constructor() ERC20("Not Ether", "notETH") {}

    function onMint(
        Attestation calldata attestation,
        uint256,
        address
    ) external override returns (bool) {
        _mint(attestation.recipient, 1 ether);
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