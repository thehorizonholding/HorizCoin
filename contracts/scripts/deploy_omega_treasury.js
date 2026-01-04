async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying OmegaConquestTreasury with account:", deployer.address);

  const horizAddress = "0xYourHORIZTokenAddressHere"; // REPLACE WITH ACTUAL

  const Treasury = await ethers.getContractFactory("OmegaConquestTreasury");
  const treasury = await Treasury.deploy(horizAddress);

  await treasury.waitForDeployment();

  console.log("OmegaConquestTreasury deployed to:", await treasury.getAddress());
  console.log("Next: Approve RWAs like OUSG, BUIDL, GOOGLx via approveRWA()");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
