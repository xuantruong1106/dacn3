// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract AccountManager {
    struct Account {
        string name;
        bool isRegistered; // Cờ kiểm tra tài khoản đã đăng ký hay chưa
    }

    mapping(address => Account) public accounts;

    event AccountCreated(address indexed user, string name);

    function createAccount(address user, string calldata name) external returns (bool) {
        require(user != address(0), "Invalid address");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(!accounts[user].isRegistered, "Account already registered");

        accounts[user] = Account(name, true);

        emit AccountCreated(user, name);
        return true;
    }

    function getAccount(address user) public view returns (string memory, bool) {
        return (accounts[user].name, accounts[user].isRegistered);
    }
}
