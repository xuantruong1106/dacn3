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

    // Sự kiện để log giao dịch chuyển tiền
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Hàm nạp tiền vào hợp đồng
    receive() external payable {}

    // Hàm chuyển tiền
    function transfer(address payable recipient, uint256 amount) public {
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(recipient != address(0), "Invalid recipient address");

        // Chuyển tiền
        recipient.transfer(amount);

        // Ghi log sự kiện
        emit Transfer(msg.sender, recipient, amount);
    }

    // Hàm kiểm tra số dư của hợp đồng
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
