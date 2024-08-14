# TodoList dApp on Core

## What can you do in this tutorial?

## Software Prerequisites
* [Git](https://git-scm.com/) v2.44.0
* [Node.js](https://nodejs.org/en) v20.11.1
* [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) v10.2.4
* [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#installation) v10.2.4
* [MetaMask Web Wallet Extension](https://metamask.io/download/)

## Setting up the development environment

1. Download this repository


2. Install dependencies in the route /contract.
   
```bash
npm install
```

2. Install and configure MetaMask Chrome Extension to use with Core Testnet. Refer [here](https://docs.coredao.org/docs/Dev-Guide/core-testnet-wallet-config) for a detailed guide.

3. Create a secret.json file in the /contract folder and store the private key of your MetaMask wallet in it. Refer [here](https://metamask.zendesk.com/hc/en-us/articles/360015290032-How-to-reveal-your-Secret-Recovery-Phrase) for details on how to get MetaMask account's private key. Example:

```json
{"PrivateKey":"ef1150b212a53b053a3dee265cb26cd010065b9340b4ac6cf5d895a7cf39c923"}
```

:::caution
Do not forget to add this file to the `.gitignore` file in the root folder of your project so that you don't accidentally check your private keys/secret phrases into a public repository. Make sure you keep this file in an absolutely safe place!
:::

4. Copy the following into your `hardhat.config.js` file in /contract

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

## Writing Smart Contract

1. Inside the /contract/contracts folder is the TodoList.sol file which will contain the smart contract code to be used for this tutorial.

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
    mapping(address => uint) private taskCounts;

    event TaskCreated(address indexed user, uint id, string content);
    event TaskCompleted(address indexed user, uint id);
    event TaskRemoved(address indexed user, uint id);
    event TaskUpdated(address indexed user, uint id, string newContent);

    function createTask(string calldata _content) external {
        uint taskId = taskCounts[msg.sender]++;
        userTasks[msg.sender].push(Task(taskId, _content, false));
        emit TaskCreated(msg.sender, taskId, _content);
    }

    function getTasks(uint _startIndex, uint _limit) external view returns (Task[] memory) {
        Task[] memory allTasks = userTasks[msg.sender];
        uint endIndex = _startIndex + _limit > allTasks.length ? allTasks.length : _startIndex + _limit;
        uint taskCount = endIndex - _startIndex;
        Task[] memory paginatedTasks = new Task[](taskCount);

        for (uint i = 0; i < taskCount; i++) {
            paginatedTasks[i] = allTasks[_startIndex + i];
        }

        return paginatedTasks;
    }

    function completeTask(uint _taskId) external {
        Task[] storage tasks = userTasks[msg.sender];
        require(_taskId < tasks.length, "Task does not exist");
        Task storage task = tasks[_taskId];
        require(!task.completed, "Task already completed");

        task.completed = true;
        emit TaskCompleted(msg.sender, _taskId);
    }

    function removeTask(uint _taskId) external {
        Task[] storage tasks = userTasks[msg.sender];
        require(_taskId < tasks.length, "Task does not exist");

        Task memory taskToRemove = tasks[_taskId];
        tasks[_taskId] = tasks[tasks.length - 1];
        tasks.pop();

        emit TaskRemoved(msg.sender, taskToRemove.id);
    }

    function updateTask(uint _taskId, string calldata _newContent) external {
        Task[] storage tasks = userTasks[msg.sender];
        require(_taskId < tasks.length, "Task does not exist");

        Task storage task = tasks[_taskId];
        task.content = _newContent;

        emit TaskUpdated(msg.sender, _taskId, _newContent);
    }
}

```

## Compiling Smart Contract

1. To compile the `TodoList` smart contract defined in the `TodoList.sol`, from the /contract directory run the following command. (Every time a change is made to the contract code we must recompile it).

```bash
npx hardhat compile
```

## Deploy and Interact with Smart Contract

1. Before deploying your smart contract on the Core Chain, it is best adviced to first run a series of tests making sure that the smart contract is working as desired. Refer to the detailed guide [here](https://docs.coredao.org/docs/Dev-Guide/hardhat#contract-testing) for more details.

2. Create a `scripts` folder in the /contract directory of your project. Inside this folder, create a file `deploy.js`; paste the following script into it.

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

3. Make sure your MetaMask wallet has tCORE test tokens for the Core Testnet. Refer [here](https://docs.coredao.org/docs/Dev-Guide/core-faucet) for details on how to get tCORE tokens from Core Faucet. 

4. Run the following command from the root directory of your project, to deploy your smart contract on the Core Chain.

```bash
npx hardhat run scripts/deploy.js
```

## Setting up Frontend

1. In the root folder, install all the dependencies.

```bash
npm install
```

2. In the path src/contractABI we must copy the abi of our smart contract in the case of making modifications, this information will be obtained from contract/artifacts/contracts/TodoList.json.

3. Once the smart contract is deployed, it is necessary to copy the address and replace it in each of the components where we make calls to the contract, in this case in ...

4. To test if things are working fine, run the application by using the following command. This will serve applciation with hot reload feature at [http://localhost:5173](http://localhost:5173/)

```bash
npm run dev
```

## Add New Task

## Get Tasks

## Complete Task

## Update Task

## Delete Taks
