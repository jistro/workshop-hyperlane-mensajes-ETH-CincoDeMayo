// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- Imports ---
// Importa Ownable para gestionar la propiedad del contrato y restringir funciones críticas.
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// Importa la interfaz IMailbox, que define las funciones necesarias para interactuar
// con el contrato Mailbox de Hyperlane (ej. para enviar mensajes).
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

/**
 * @title Emisor
 * @notice Este contrato actúa como un punto de partida para enviar mensajes
 * a otro contrato (Receptor) ubicado en una blockchain diferente,
 * utilizando el sistema de mensajería de Hyperlane.
 * @dev Hereda de Ownable para que solo el propietario pueda configurar
 * la dirección y cadena del contrato Receptor.
 */
contract Emisor is Ownable {
    // --- Variables de Estado ---

    /// @notice Almacena la instancia (dirección casteada a interfaz) del contrato Mailbox
    /// de Hyperlane en esta cadena. Es el punto de entrada para enviar mensajes cross-chain.
    IMailbox public mailbox;

    /**
     * @notice Estructura para guardar los datos necesarios para identificar
     * al contrato Receptor en la cadena de destino.
     */
    struct MetadatosReceptor {
        // La dirección del contrato Receptor en la cadena destino.
        // Se guarda como bytes32 porque Hyperlane opera con direcciones en este formato.
        bytes32 direccion;
        // El identificador único (Chain ID) de la blockchain donde se encuentra el Receptor.
        uint32 chainID;
    }

    /// @notice Variable que contiene los metadatos (dirección y chainID)
    /// del contrato Receptor actualmente configurado.
    MetadatosReceptor public receptor;

    // --- Constructor ---

    /**
     * @notice Inicializa el contrato Emisor.
     * @param mailbox_ La dirección del contrato Mailbox de Hyperlane para esta cadena específica.
     * Consulta las direcciones oficiales aquí: https://docs.hyperlane.xyz/docs/reference/contract-addresses#mailbox
     * @param initialOwner La dirección que será designada como propietaria inicial del contrato.
     */
    constructor(address mailbox_, address initialOwner) Ownable(initialOwner) {
        // Asigna la dirección proporcionada a la variable `mailbox`,
        // convirtiéndola al tipo de interfaz `IMailbox` para poder llamar a sus funciones.
        mailbox = IMailbox(mailbox_);
    }

    // --- Funciones ---

    /**
     * @notice Permite al propietario del contrato establecer o actualizar
     * la dirección y el Chain ID del contrato Receptor destino.
     * @dev Solo puede ser llamada por el `owner` del contrato (gracias a `onlyOwner`).
     * @param _direccion La dirección estándar (formato address) del contrato Receptor.
     * @param _chainID El Chain ID de la blockchain donde está desplegado el Receptor.
     */
    function _establecerReceptor(
        address _direccion,
        uint32 _chainID
    ) external onlyOwner {
        // Convierte la dirección `address` (160 bits) a `bytes32` (256 bits).
        // Esto se hace añadiendo ceros a la izquierda (padding).
        // Hyperlane necesita la dirección del receptor en formato `bytes32`.
        receptor.direccion = bytes32(uint256(uint160(_direccion)));
        // Guarda el Chain ID de la cadena destino.
        receptor.chainID = _chainID;
    }

    /**
     * @notice Envía un mensaje de texto al contrato Receptor configurado.
     * @dev Esta función es `payable`, lo que significa que debe recibir fondos (token nativo)
     * al ser llamada. Estos fondos se usan para pagar los costos necesarios para procesar
     * el mensaje en la cadena de destino.
     * @param mensaje El contenido textual del mensaje que se desea enviar.
     */
    function enviarMensaje(string memory mensaje) external payable {
        // Prepara el `payload` del mensaje.
        // Codifica el texto del mensaje junto con la dirección de quien llama a esta función (msg.sender).
        // El contrato Receptor podrá decodificar esto para saber qué se envió y quién lo envió.
        bytes memory payload = abi.encode(mensaje, msg.sender);

        // Llama a la función `dispatch` del contrato Mailbox de Hyperlane.
        // Esta es la acción principal que inicia el envío del mensaje cross-chain.
        // Se adjunta el valor recibido (`msg.value`) para cubrir los costos de gas en destino.
        mailbox.dispatch{value: msg.value}(
            receptor.chainID, // El ID de la cadena a la que se envía el mensaje.
            receptor.direccion, // La dirección (en bytes32) del contrato Receptor en esa cadena.
            payload // Los datos codificados (mensaje y remitente) que se envían.
        );
    }
}