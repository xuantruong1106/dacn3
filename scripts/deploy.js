const hre = require("hardhat");

async function main() {
    const AccountManager = await hre.ethers.getContractFactory("AccountManager");
    const accountManager = await AccountManager.deploy();
    await accountManager.waitForDeployment();  // Đợi hợp đồng triển khai

    console.log("AccountManager deployed to:", await accountManager.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
