# Mensajeria cross-chain con Hyperlane

## ¿Que es Hyperlane?

Imagina que las diferentes **blockchains** son como **sistemas digitales separados** que, por naturaleza, no pueden comunicarse fácilmente entre sí.

**Hyperlane** es una tecnología que actúa como un **constructor de puentes universal** para conectar estas blockchains distintas.

- **¿Qué hace?** Permite enviar **mensajes y activos digitales** de forma segura de una blockchain a otra.
- **¿Su clave?** Es **"sin permisos"**: cualquiera puede usar las herramientas de Hyperlane para crear estas conexiones, sin necesitar la aprobación de una entidad central.

Con ello Hyperlane ayuda a que el mundo de las blockchains esté más **interconectado y sea más versátil**, permitiendo que diferentes redes trabajen juntas como si fuera una sola.

---

## Que veremos en este curso

En este curso, **exploraremos y aplicaremos** el sistema de mensajería de Hyperlane, conocido como **Mailbox**. Este sistema permite enviar mensajes seguros entre diferentes blockchains, ya sean de **Capa 1 (como Ethereum) o de Capa 2 (como Arbitrum)**.

**Desarrollaremos dos contratos inteligentes:** un **Emisor**, diseñado para enviar mensajes desde una cadena origen, y un **Receptor**, capaz de recibirlos en una cadena destino.

El contrato **Emisor** enviará un mensaje de texto junto con la **dirección** del remitente. Utilizando el **Mailbox** de Hyperlane, este mensaje viajará hasta la cadena destino donde se encuentra el contrato **Receptor**. Finalmente, el **Receptor** procesará el mensaje recibido y **guardará** la información relevante.

---

## Como funciona el Mailbox de Hyperlane

**Imagínate** los contratos de **Emisor** y **Receptor** como dos casas. Cada casa se encuentra en un "estado" diferente (es decir, en **cadenas** o blockchains distintas). La 'casa emisora' quiere enviar un mensaje a la 'casa receptora'.

Para lograrlo, se utiliza el **Mailbox** de Hyperlane. Piensa en el Mailbox como la **oficina local del servicio postal** que existe en cada estado/cadena. Este servicio se **encargará** de llevar el mensaje de una casa a otra.

Así es como funciona el proceso:

1.  La 'casa emisora' (**contrato Emisor**) **envía** el mensaje a la 'oficina postal' (**Mailbox**) de su propio estado/cadena.
2.  Junto con el mensaje, debe incluir la **dirección** específica de la 'casa receptora' (contrato Receptor), el identificador del estado/cadena destino (**Chain ID**), y cubrir el **costo del envío** (normalmente pagado en el token nativo de la cadena origen).
3.  La 'oficina postal' (Mailbox origen) recibe todo esto y lo pasa al **protocolo central de Hyperlane**, que actúa como el sistema de transporte seguro entre los diferentes estados/cadenas.
4.  Hyperlane se encarga de **enrutar** el mensaje para que llegue al estado/cadena correcto.
5.  Una vez allí, la 'oficina postal' (**Mailbox**) de _ese_ estado/cadena destino recibe el mensaje.
6.  Finalmente, esta oficina local **entregará** el mensaje directamente a la 'casa receptora' (el contrato **Receptor**), completando la comunicación.

---

## Pasos a seguir

1.  **Preparar el entorno:** Utiliza [Remix](https://remix.ethereum.org/) para crear y probar los contratos inteligentes, o **algún** framework de desarrollo como [Hardhat](https://hardhat.org/) o [Foundry](https://foundry.paradigm.xyz/).
2.  **Desarrollar los contratos:** Implementa la lógica para `Emisor.sol` y `Receptor.sol`. **Encontrarás** los archivos base con explicaciones detalladas en el repositorio del curso.
3.  **Compilar y Desplegar:**
    - Compila ambos contratos inteligentes.
    - Despliega `Emisor.sol` en la blockchain de origen y `Receptor.sol` en la blockchain de destino.
    - **Al desplegar (en el constructor)**, necesitarás proporcionar:
      - `initialOwner`: La dirección que **será** la propietaria y administradora del contrato.
      - `mailbox`: La dirección del contrato Mailbox oficial de Hyperlane correspondiente a esa cadena específica.
    - Puedes encontrar las direcciones oficiales del Mailbox para cada red en la sección [Contract Addresses](https://docs.hyperlane.xyz/docs/reference/contract-addresses#mailbox) de la documentación de Hyperlane. **Dirígete** allí para obtener la dirección correcta.
4.  **Configurar el Emisor:** En el contrato `Emisor.sol` desplegado, llama a la función `_establecerReceptor()` para guardar la **dirección** y el **Chain ID** del contrato `Receptor.sol` en la cadena destino.
5.  **Configurar el Receptor:** De forma similar, en el contrato `Receptor.sol` desplegado, llama a la función `_establecerEmisor()` para guardar la **dirección** y el **Chain ID** del contrato `Emisor.sol` en la cadena origen.
6.  **Enviar un Mensaje:** Llama a la función `enviarMensaje()` desde el contrato `Emisor.sol`. Esto iniciará el proceso de envío del mensaje hacia la cadena destino a través de Hyperlane.
7.  **Verificar la Recepción:** En el contrato `Receptor.sol`, utiliza la función `obtenerMensajePorIndex()` (o el nombre exacto que tenga en el código) para consultar los mensajes que han sido recibidos desde la cadena origen.