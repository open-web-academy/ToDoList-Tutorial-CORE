# dApp de Lista de Tareas en Core

Las aplicaciones descentralizadas (dApps) utilizan una blockchain o contratos inteligentes en cadena para almacenar y referenciar datos, en lugar de depender de bases de datos centralizadas tradicionales. Una estructura común y simple de una dApp generalmente consiste en un front-end en React.js o Vue.js que utiliza Web3.js o Ethers.js para interactuar con contratos inteligentes desplegados en una blockchain compatible con EVM.

## ¿Qué puedes hacer en este tutorial?

En este tutorial, aprenderás cómo crear una lista de tareas donde podrás agregar tareas y marcarlas como completadas o eliminarlas en la red CORE.

## Requisitos de Software

* [Git](https://git-scm.com/) v2.44.0
* [Node.js](https://nodejs.org/en) v20.11.1
* [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) v10.2.4
* [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#installation) v10.2.4
* [MetaMask Web Wallet Extension](https://metamask.io/download/)

## Configuración del entorno de desarrollo

1. Descarga este repositorio

2. Instala las dependencias en la ruta /contract.
   
```bash
npm install
```

3. Instala y configura la Extensión MetaMask para Chrome para usar con Core Testnet. Consulta [aquí](https://docs.coredao.org/docs/Dev-Guide/core-testnet-wallet-config) para una guía detallada.

4. Crea un archivo secret.json en la carpeta /contract y almacena la clave privada de tu billetera MetaMask en él. Consulta [aquí](https://metamask.zendesk.com/hc/en-us/articles/360015290032-How-to-reveal-your-Secret-Recovery-Phrase) para detalles sobre cómo obtener la clave privada de la cuenta MetaMask. Ejemplo:

```json
{"PrivateKey":"ef1150b212a53b053a3dee265cb26cd010065b9340b4ac6cf5d895a7cf39c923"}
```

:::Advertencia: 
No olvides añadir este archivo al archivo .gitignore en la carpeta raíz de tu proyecto para evitar que tu clave privada/frases secretas se suban accidentalmente a un repositorio público. ¡Asegúrate de mantener este archivo en un lugar absolutamente seguro!
:::

5. Copia lo siguiente en tu archivo hardhat.config.js en /contract

```js
/**
 * @type import('hardhat/config').HardhatUserConfig
 */


require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-waffle");


const { PrivateKey } = require('./secret.json');


module.exports = {
   defaultNetwork: 'testnet',


   networks: {
      hardhat: {
      },
      testnet: {
         url: 'https://rpc.test.btcs.network',
         accounts: [PrivateKey],
         chainId: 1115,
      }
   },
   solidity: {
      compilers: [
        {
           version: '0.8.24',
           settings: {
            evmVersion: 'paris',
            optimizer: {
                 enabled: true,
                 runs: 200,
              },
           },
        },
      ],
   },
   paths: {
      sources: './contracts',
      cache: './cache',
      artifacts: './artifacts',
   },
   mocha: {
      timeout: 20000,
   },
};
```

## Escritura del Contrato Inteligente

1. Dentro de la carpeta /contract/contracts se encuentra el archivo `TodoList.sol` que contendrá el código del contrato inteligente a utilizar en este tutorial.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        uint id;
        string content;
        bool completed;
    }

    mapping(address => Task[]) private userTasks;
    mapping(address => mapping(uint => uint)) private userTaskIndex;
    mapping(address => uint) private taskCounts;

    event TaskCreated(address indexed user, uint id, string content);
    event TaskCompleted(address indexed user, uint id);
    event TaskRemoved(address indexed user, uint id);
    event TaskUpdated(address indexed user, uint id, string newContent);

    function createTask(string calldata _content) external {
        uint taskId = taskCounts[msg.sender]++;
        userTasks[msg.sender].push(Task(taskId, _content, false));
        userTaskIndex[msg.sender][taskId] = userTasks[msg.sender].length - 1;
        emit TaskCreated(msg.sender, taskId, _content);
    }

    function getTasks(uint _startIndex, uint _limit) external view returns (Task[] memory) {
        Task[] memory allTasks = userTasks[msg.sender];
        uint totalTasks = allTasks.length;

        require(_startIndex < totalTasks, "Start index out of bounds");

        uint endIndex = _startIndex + _limit > totalTasks ? totalTasks : _startIndex + _limit;
        uint taskCount = endIndex - _startIndex;

        Task[] memory paginatedTasks = new Task[](taskCount);

        for (uint i = 0; i < taskCount; i++) {
            paginatedTasks[i] = allTasks[totalTasks - 1 - (_startIndex + i)];
        }

        return paginatedTasks;
    }

    function completeTask(uint _taskId) external {
        uint index = userTaskIndex[msg.sender][_taskId];
        require(index < userTasks[msg.sender].length, "Task does not exist");

        Task storage task = userTasks[msg.sender][index];
        require(!task.completed, "Task already completed");

        task.completed = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    function removeTask(uint _taskId) external {
        uint index = userTaskIndex[msg.sender][_taskId];
        Task[] storage tasks = userTasks[msg.sender];
        require(index < tasks.length, "Task does not exist");

        tasks[index] = tasks[tasks.length - 1];
        userTaskIndex[msg.sender][tasks[index].id] = index;
        tasks.pop();

        delete userTaskIndex[msg.sender][_taskId];

        emit TaskRemoved(msg.sender, _taskId);
    }

    function updateTask(uint _taskId, string calldata _newContent) external {
        uint index = userTaskIndex[msg.sender][_taskId];
        Task[] storage tasks = userTasks[msg.sender];
        require(index < tasks.length, "Task does not exist");

        Task storage task = tasks[index];
        task.content = _newContent;

        emit TaskUpdated(msg.sender, _taskId, _newContent);
    }
}
```

## Compilación del Contrato Inteligente

1. Para compilar el contrato inteligente `TodoList` definido en `TodoList.sol`, desde el directorio /contract ejecuta el siguiente comando. (Cada vez que se realice un cambio en el código del contrato, debemos recompilarlo).

```bash
npx hardhat compile
```

## Despliegue e Interacción con el Contrato Inteligente

1. Antes de desplegar tu contrato inteligente en la cadena Core, es aconsejable ejecutar una serie de pruebas para asegurarse de que el contrato funciona como se desea. Consulta la guía detallada [aquí](https://docs.coredao.org/docs/Dev-Guide/hardhat#contract-testing) para más detalles.

2. Crea una carpeta `scripts` en el directorio /contract de tu proyecto. Dentro de esta carpeta, crea un archivo `deploy.js`; pega el siguiente script en él.

```javascript
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploy contract with the account:", deployer.address);

  const TodoList = await ethers.getContractFactory("TodoList");

  const todoList = await TodoList.deploy();

  console.log("Contract Address:", todoList.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

3. Asegúrate de que tu billetera MetaMask tenga tokens de prueba tCORE para la Red de Pruebas Core. Consulta [aquí](https://docs.coredao.org/docs/Dev-Guide/core-faucet) para detalles sobre cómo obtener tokens tCORE.

4. Ejecuta el siguiente comando desde el directorio raíz de tu proyecto para desplegar tu contrato inteligente en la cadena Core.

```bash
npx hardhat run scripts/deploy.js
```

## Configuración del Frontend

1. En la carpeta raíz, instala todas las dependencias.

```bash
npm install
```

2. En la ruta src/contractABI debemos copiar el ABI de nuestro contrato inteligente en caso de hacer modificaciones, esta información se obtendrá de contract/artifacts/contracts/TodoList.json.

3. Una vez que el contrato inteligente esté desplegado, es necesario copiar la dirección y reemplazarla en cada uno de los componentes donde realizamos llamadas al contrato, en este caso src/components/New.tsx y src/components/Get.tsx.

4. Para probar si todo está funcionando correctamente, ejecuta la aplicación utilizando el siguiente comando. Esto servirá la aplicación con la función de recarga en caliente en [http://localhost:5173](http://localhost:5173/)

```bash
npm run dev
```

## Añadir Tarea

 1. Para agregar una nueva tarea, primero debe ingresar el texto o la descripción de la tarea.
 2. Una vez hecho esto, haga clic en el botón "Add Task" y acepte la transacción en metamask.

<img src="https://github.com/open-web-academy/ToDoList-Tutorial-CORE/blob/master/src/public/NewTask.gif?raw=true" width="50%">

## Completar Tarea

1. Para marcar una tarea como completada, primero debes dirigirte a la opción "Task List" del menú.
2. Debes localizar la tarea que deseas marcar como completada y luego hacer clic en el botón "Complete".
3. Por último, solo tendrás que aceptar la transacción en metamask y la tarea quedará marcada como completada.

<img src="https://raw.githubusercontent.com/open-web-academy/ToDoList-Tutorial-CORE/master/src/public/CompleteTask.gif" width="50%">

## Eliminar Tarea

1. Para eliminar una tarea, primero debes dirigirte a la opción "Task List" del menú.
2. Debes localizar la tarea que deseas eliminar y luego hacer clic en el botón "Remove".
3. Por último, solo tendrás que aceptar la transacción en metamask y la tarea será eliminada.

<img src="https://raw.githubusercontent.com/open-web-academy/ToDoList-Tutorial-CORE/master/src/public/RemoveTask.gif" width="50%">
