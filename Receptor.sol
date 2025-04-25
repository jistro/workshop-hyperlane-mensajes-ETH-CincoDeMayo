// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

contract Receptor is Ownable {
    error BuzonNoAutorizado();
    error EmisorNoAutorizado();
    error ChainIdNoAutorizado();

    struct MetadatosEmisor {
        bytes32 direccion;
        uint32 chainID;
    }

    struct MetadatosMensaje {
        string mensaje;
        address quienLoEnvia;
    }

    address mailbox;
    uint256 contadorMensajes;

    mapping(uint256 => MetadatosMensaje) private mensajes;

    MetadatosEmisor emisor;

    constructor(address initialOwner, address mailbox_) Ownable(initialOwner) {
        mailbox = mailbox_;
    }

    function _establecerEmisor(
        address _direccion,
        uint32 _chainID
    ) external onlyOwner {
        emisor.direccion = bytes32(uint256(uint160(_direccion)));
        emisor.chainID = _chainID;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != mailbox) {
            revert BuzonNoAutorizado();
        }
        if (_sender != emisor.direccion) {
            revert EmisorNoAutorizado();
        }
        if (_origin != emisor.chainID) {
            revert ChainIdNoAutorizado();
        }

        (string memory _mensaje, address _quienLoEnvia) = abi.decode(
            _data,
            (string, address)
        );

        mensajes[contadorMensajes] = MetadatosMensaje(_mensaje, _quienLoEnvia);
        contadorMensajes++;
    }

    function obtenerMensaje(uint256 index) public view returns (string memory) {
        return mensajes[index].mensaje;
    }

    function obtenerQuienLoEnvia(uint256 index) public view returns (address) {
        return mensajes[index].quienLoEnvia;
    }

    function obtenerMensajetenerDatosPorIndex(
        uint256 index
    ) public view returns (MetadatosMensaje memory) {
        return mensajes[index];
    }

    function obtenerContadorMensajes() public view returns (uint256) {
        return contadorMensajes;
    }
}
