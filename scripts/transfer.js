const { ethers } = require("hardhat");

async function main() {
  // Lấy danh sách tài khoản
  const [owner, addr1, addr2] = await ethers.getSigners();
  console.log("Owner address:", owner.address);
  console.log("Addr1 address:", addr1.address);
  console.log("Addr2 address:", addr2.address);

  // Deploy contract
  const AccountManager = await ethers.getContractFactory("AccountManager");
  const accountManager = await AccountManager.deploy();
  await accountManager.waitForDeployment();
  console.log("Contract deployed at:", accountManager.target);

  // Kiểm tra xem contract có hoạt động không
  console.log("Contract instance created:", accountManager.address ? "Yes" : "No");

  // Thực hiện các lệnh
  try {
    // Tạo tài khoản cho addr1
    await accountManager.connect(addr1).createAccount("User1");
    console.log("Account created for User1");

    // Tạo tài khoản cho addr2
    await accountManager.connect(addr2).createAccount("User2");
    console.log("Account created for User2");

    // Nạp 5 ETH cho addr1
    await accountManager.connect(addr1).deposit({ value: ethers.parseEther("5") });
    console.log("Deposited 5 ETH to User1");

    // Kiểm tra số dư của addr1 trước khi chuyển
    const balance1Before = await accountManager.connect(addr1).getBalance();
    console.log("Balance User1 before:", ethers.formatEther(balance1Before), "ETH");

    // Chuyển 2 ETH từ addr1 đến addr2, gửi kèm 2 ETH qua value
    await accountManager.connect(addr1).transfer(addr2.address, ethers.parseEther("2"), {
      value: ethers.parseEther("2")
    });
    console.log("Transferred 2 ETH from User1 to User2");

    // Kiểm tra số dư sau khi chuyển
    const balance1After = await accountManager.connect(addr1).getBalance();
    const balance2After = await accountManager.connect(addr2).getBalance();
    console.log("Balance User1 after:", ethers.formatEther(balance1After), "ETH");
    console.log("Balance User2 after:", ethers.formatEther(balance2After), "ETH");

    // Kiểm tra số dư của contract
    const contractBalance = await ethers.provider.getBalance(accountManager.target);
    console.log("Contract balance:", ethers.formatEther(contractBalance), "ETH");
  } catch (error) {
    console.error("Error in execution:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });