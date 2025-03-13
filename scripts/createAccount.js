const { ethers } = require("hardhat");

async function main() {
  // Lấy tài khoản index 2
  const [_, __, account2] = await ethers.getSigners();
  console.log("Address of index 2:", account2.address);

  // // Deploy contract mới
  // const AccountManager = await ethers.getContractFactory("AccountManager");
  // const contract = await AccountManager.deploy();
  // await contract.waitForDeployment();
  // console.log("Contract deployed to:", contract.target);

  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Địa chỉ contract hiện có
  const AccountManager = await ethers.getContractFactory("AccountManager");
  const contract = await AccountManager.attach(contractAddress);
  console.log("Connected to contract at:", contractAddress);

  // Tạo tài khoản "an" cho index 2
  await contract.connect(account2).createAccount("an");
  console.log("Account created for", account2.address);

  // Kiểm tra tài khoản
  const account = await contract.accounts(account2.address);
  console.log("Account details:", account);

  // Lấy số dư trước khi nạp
  const balanceBefore = await contract.connect(account2).getBalance();
  console.log("Balance before deposit:", ethers.formatEther(balanceBefore), "ETH");

  // Nạp 2 ETH
  await contract.connect(account2).deposit({ value: ethers.parseEther("2.0") });
  console.log("Deposited 2 ETH to", account2.address);

  // Lấy số dư sau khi nạp
  const balanceAfter = await contract.connect(account2).getBalance();
  console.log("Balance after deposit:", ethers.formatEther(balanceAfter), "ETH");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });