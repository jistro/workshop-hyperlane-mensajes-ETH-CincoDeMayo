// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

contract Emisor is Ownable {
    IMailbox public mailbox;

    struct MetadatosReceptor {
        bytes32 direccion;
        uint32 chainID;
    }

    MetadatosReceptor receptor;

    // https://docs.hyperlane.xyz/docs/reference/contract-addresses#mailbox
    constructor(address mailbox_, address initialOwner) Ownable(initialOwner) {
        mailbox = IMailbox(mailbox_);
    }

    function _establecerReceptor(
        address _direccion,
        uint32 _chainID
    ) external onlyOwner {
        receptor.direccion = bytes32(uint256(uint160(_direccion)));
        receptor.chainID = _chainID;
    }

    function enviarMensaje(string memory mensaje) external payable {
        bytes memory payload = abi.encode(mensaje, msg.sender);

        mailbox.dispatch{value: msg.value}(
            receptor.chainID,
            receptor.direccion,
            payload
        );
    }
}
