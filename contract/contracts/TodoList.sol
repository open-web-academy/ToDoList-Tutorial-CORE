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
