// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.28;

// contract AccountManager {
//     struct Account {
//         string name;
//         uint256 balance;
//         bool isRegistered;
//     }

//     mapping(address => Account) public accounts;

//     event AccountCreated(address indexed user, string name);
//     event Deposit(address indexed user, uint256 amount);
//     event Transfer(address indexed from, address indexed to, uint256 amount);

//     function createAccount(string calldata name) external {
//         require(bytes(name).length > 0, "Name cannot be empty");
//         require(!accounts[msg.sender].isRegistered, "Account already registered");

//         accounts[msg.sender] = Account(name, 0, true);
//         emit AccountCreated(msg.sender, name);
//     }

//     function deposit() external payable {
//         require(accounts[msg.sender].isRegistered, "Account does not exist");
//         require(msg.value > 0, "Deposit amount must be greater than zero");

//         accounts[msg.sender].balance += msg.value;
//         emit Deposit(msg.sender, msg.value);
//     }

//     function transfer(address recipient, uint256 amount) external payable {
//         require(accounts[msg.sender].isRegistered, "Sender account does not exist");
//         require(accounts[recipient].isRegistered, "Recipient account does not exist");
//         require(msg.value == amount, "Sent value must match amount");

//         accounts[recipient].balance += msg.value;

//         emit Transfer(msg.sender, recipient, msg.value);
//     }

//     function getBalance() public view returns (uint256) {
//         return accounts[msg.sender].balance;
//     }
// }

pragma solidity ^0.8.28;

contract AccountManager {
    struct Account {
        string name;
        bool isRegistered;
    }

    mapping(address => Account) public accounts;

    event AccountCreated(address indexed user, string name);
    event Deposit(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function createAccount(string calldata name) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(!accounts[msg.sender].isRegistered, "Account already registered");

        accounts[msg.sender] = Account(name, true);
        emit AccountCreated(msg.sender, name);
    }

    function deposit() external payable {
        require(accounts[msg.sender].isRegistered, "Account does not exist");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        emit Deposit(msg.sender, msg.value);
    }

    function transfer(address payable recipient, uint256 amount) external payable {
        require(accounts[msg.sender].isRegistered, "Sender account does not exist");
        require(accounts[recipient].isRegistered, "Recipient account does not exist");
        require(msg.value == amount, "Sent value must match amount");

        recipient.transfer(msg.value); // Gửi ETH trực tiếp đến recipient

        emit Transfer(msg.sender, recipient, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return msg.sender.balance; // Trả về số dư ví thực tế của msg.sender
    }
}