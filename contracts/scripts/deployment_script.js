const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const HZC = await ethers.getContractFactory("HorizCoinVulnerable");
  const hzc = await HZC.deploy();
  await hzc.waitForDeployment();
  console.log("HZC deployed →", await hzc.getAddress());

  const Router = await ethers.getContractFactory("ExploitRouter");
  const router = await Router.deploy(deployer.address);
  await router.waitForDeployment();
  console.log("ExploitRouter deployed →", await router.getAddress());
}

main().catch(err => { console.error(err); process.exit(1); });
