const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OmegaConquestTreasury", function () {
  let treasury, horiz, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const HORIZ = await ethers.getContractFactory("ERC20Mock"); // Replace with real HORIZ
    horiz = await HORIZ.deploy("HorizCoin", "HORIZ", ethers.parseEther("1000000"));

    const Treasury = await ethers.getContractFactory("OmegaConquestTreasury");
    treasury = await Treasury.deploy(await horiz.getAddress());
  });

  it("Should allow owner to approve and conquer RWA", async function () {
    const mockRWA = addr1.address; // Mock RWA token
    await treasury.approveRWA(mockRWA);
    expect(await treasury.approvedRWA(mockRWA)).to.be.true;
  });

  it("Should restrict conquest to approved RWAs", async function () {
    await expect(
      treasury.conquerRWA(1000, addr1.address, 0)
    ).to.be.revertedWith("RWA not approved");
  });
});
