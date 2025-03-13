const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"; // Thay bằng địa chỉ thực
  const AccountManager = await ethers.getContractFactory("AccountManager");
  const contract = await AccountManager.attach(contractAddress);

  const [sender, recipient] = await ethers.getSigners();
  console.log("Sender address:", sender.address);
  console.log("Recipient address:", recipient.address);

  await contract.connect(sender).createAccount("Sender");
  await contract.connect(recipient).createAccount("Recipient");

  const senderWalletBefore = await ethers.provider.getBalance(sender.address);
  const recipientWalletBefore = await ethers.provider.getBalance(recipient.address);
  console.log("Sender wallet before:", ethers.formatEther(senderWalletBefore), "ETH");
  console.log("Recipient wallet before:", ethers.formatEther(recipientWalletBefore), "ETH");

  await contract.connect(sender).transfer(recipient.address, ethers.parseEther("1.0"), { value: ethers.parseEther("1.0") });
  console.log("Transferred 1 ETH from sender to recipient");

  const senderBalance = await contract.connect(sender).getBalance();
  const recipientBalance = await contract.connect(recipient).getBalance();
  console.log("Sender balance in contract:", ethers.formatEther(senderBalance), "ETH");
  console.log("Recipient balance in contract:", ethers.formatEther(recipientBalance), "ETH");

  const senderWalletAfter = await ethers.provider.getBalance(sender.address);
  const recipientWalletAfter = await ethers.provider.getBalance(recipient.address);
  const contractBalance = await ethers.provider.getBalance(contractAddress);
  console.log("Sender wallet after:", ethers.formatEther(senderWalletAfter), "ETH");
  console.log("Recipient wallet after:", ethers.formatEther(recipientWalletAfter), "ETH");
  console.log("Contract balance:", ethers.formatEther(contractBalance), "ETH");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });