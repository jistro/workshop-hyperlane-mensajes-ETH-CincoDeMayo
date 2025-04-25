// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- Imports ---
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// Importa la interfaz IMailbox (aunque no se llama directamente,
// define la estructura esperada por Hyperlane y el contexto de `handle`).
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

/**
 * @title Receptor
 * @notice Este contrato recibe y almacena mensajes enviados desde un contrato Emisor
 * en otra blockchain a través del sistema de mensajería de Hyperlane.
 * @dev Implementa la función `handle` requerida por Hyperlane y valida el origen
 * de los mensajes antes de procesarlos. Hereda de Ownable para la configuración segura.
 */
contract Receptor is Ownable {
    // --- Errores Personalizados ---
    // Se emite si `handle` es llamado por una dirección que no es el Mailbox configurado.
    error BuzonNoAutorizado();
    // Se emite si el mensaje recibido no proviene de la dirección del Emisor configurada.
    error EmisorNoAutorizado();
    // Se emite si el mensaje recibido no proviene de la Chain ID del Emisor configurada.
    error ChainIdNoAutorizado();

    // --- Estructuras ---
    /**
     * @notice Almacena los datos del contrato Emisor esperado.
     * Utilizado para verificar la autenticidad del remitente y la cadena origen.
     */
    struct MetadatosEmisor {
        bytes32 direccion; // Dirección del Emisor (en formato bytes32).
        uint32 chainID; // Chain ID de la cadena origen del Emisor.
    }

    /**
     * @notice Almacena la información relevante de un mensaje recibido y decodificado.
     */
    struct MetadatosMensaje {
        string mensaje; // El contenido textual del mensaje.
        address quienLoEnvia; // La dirección que originó la llamada en el contrato Emisor.
    }

    // --- Variables de Estado ---

    /// @notice Dirección del contrato Mailbox de Hyperlane en *esta* cadena.
    /// Esencial para verificar que `handle` solo sea llamado por el sistema Hyperlane.
    address public mailbox;

    /// @notice Contador que registra el número total de mensajes recibidos y almacenados.
    uint256 public contadorMensajes;

    /// @notice Mapping que almacena cada mensaje recibido, indexado por un contador.
    /// Es privado para encapsular el almacenamiento; se accede mediante funciones getter.
    mapping(uint256 => MetadatosMensaje) private mensajes;

    /// @notice Variable que guarda la configuración del Emisor esperado (dirección y chainID).
    MetadatosEmisor public emisor;

    // --- Constructor ---
    /**
     * @notice Inicializa el contrato Receptor.
     * @param initialOwner La dirección que será propietaria inicial del contrato.
     * @param mailbox_ La dirección del contrato Mailbox de Hyperlane en la cadena actual.
     */
    constructor(address initialOwner, address mailbox_) Ownable(initialOwner) {
        // Guarda la dirección del Mailbox proporcionada.
        mailbox = mailbox_;
    }

    // --- Funciones de Configuración ---
    /**
     * @notice Permite al propietario configurar o actualizar los datos
     * del contrato Emisor cuya recepción de mensajes está autorizada.
     * @dev Esta configuración es VITAL para la seguridad del receptor.
     * @param _direccion La dirección del contrato Emisor en la cadena origen.
     * @param _chainID El Chain ID de la cadena origen donde reside el Emisor.
     */
    function _establecerEmisor(
        address _direccion,
        uint32 _chainID
    ) external onlyOwner {
        // Convierte la dirección del Emisor a bytes32 y la guarda.
        emisor.direccion = bytes32(uint256(uint160(_direccion)));
        // Guarda el Chain ID esperado de la cadena origen.
        emisor.chainID = _chainID;
    }

    // --- Función de Recepción de Mensajes (Hyperlane Hook) ---
    /**
     * @notice Punto de entrada principal para los mensajes de Hyperlane.
     * El contrato Mailbox llama a esta función cuando recibe un mensaje
     * destinado a la dirección de este contrato.
     * @dev La firma `handle(uint32, bytes32, bytes)` es ESTÁNDAR y REQUERIDA por Hyperlane.
     * Debe ser `external`. Usualmente `payable` para permitir recibir pagos de gas interchain (IGP).
     * `virtual` permite la sobreescritura en contratos derivados.
     * @param _origin El Chain ID de la cadena origen del mensaje.
     * @param _sender La dirección (en bytes32) del contrato que envió el mensaje en la cadena origen.
     * @param _data El payload (carga útil) codificado del mensaje.
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        // --- Verificaciones de Seguridad Esenciales ---
        // 1. Validar que la llamada proviene EXCLUSIVAMENTE del Mailbox de esta cadena.
        if (msg.sender != mailbox) {
            revert BuzonNoAutorizado(); // Evita ejecución si no es el Mailbox.
        }
        // 2. Validar que el mensaje fue enviado por el contrato Emisor configurado.
        if (_sender != emisor.direccion) {
            revert EmisorNoAutorizado(); // Evita mensajes de emisores desconocidos.
        }
        // 3. Validar que el mensaje proviene de la cadena origen configurada.
        if (_origin != emisor.chainID) {
            revert ChainIdNoAutorizado(); // Evita mensajes de cadenas no esperadas.
        }

        // --- Procesamiento y Almacenamiento del Mensaje ---
        // Decodifica el payload (`_data`). El formato (string, address) debe
        // coincidir EXACTAMENTE con el `abi.encode` del contrato Emisor.
        (string memory _mensaje, address _quienLoEnvia) = abi.decode(
            _data,
            (string, address)
        );

        // Almacena los datos decodificados en el mapping, usando el contador actual como clave.
        mensajes[contadorMensajes] = MetadatosMensaje(_mensaje, _quienLoEnvia);
        // Incrementa el contador para el siguiente mensaje.
        contadorMensajes++;

        // (Opcional) Aquí se podría añadir lógica adicional:
        // - Emitir un evento `MensajeRecibido(contadorMensajes-1, _mensaje, _quienLoEnvia)`.
        // - Llamar a otra función interna para procesar el mensaje.
        // - Interactuar con otros contratos basados en el mensaje recibido.
    }

    // --- Funciones de Consulta (Getters) ---

    /**
     * @notice Devuelve el contenido de texto de un mensaje guardado, por su índice.
     * @param index El índice (basado en el orden de llegada) del mensaje a consultar.
     * @return string El mensaje de texto.
     */
    function obtenerMensaje(uint256 index) public view returns (string memory) {
        if (index >= contadorMensajes) {
            revert();
        }
        return mensajes[index].mensaje;
    }

    /**
     * @notice Devuelve la dirección original que envió un mensaje específico, por su índice.
     * @param index El índice del mensaje a consultar.
     * @return address La dirección del remitente original.
     */
    function obtenerQuienLoEnvia(uint256 index) public view returns (address) {
        if (index >= contadorMensajes) {
            revert();
        }
        return mensajes[index].quienLoEnvia;
    }

    /**
     * @notice Devuelve la estructura completa con los datos de un mensaje, por su índice.
     * @dev El nombre original `obtenerMensajetenerDatosPorIndex` parece contener un typo.
     * Se recomienda renombrar a algo como `obtenerDatosDelMensaje` o `obtenerMensajeCompleto`.
     * @param index El índice del mensaje a consultar.
     * @return MetadatosMensaje La estructura con el mensaje y quién lo envió.
     */
    function obtenerMensajePorIndex(
        uint256 index
    ) public view returns (MetadatosMensaje memory) {
        if (index >= contadorMensajes) {
            revert();
        }
        return mensajes[index];
    }

    /**
     * @notice Devuelve el número total de mensajes que han sido recibidos y almacenados.
     * @return uint256 El valor actual del contador.
     */
    function obtenerContadorMensajes() public view returns (uint256) {
        return contadorMensajes;
    }
}
