// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @title AddressWriter
 * @notice Helper script for writing deployment addresses to JSON file
 * @dev Provides functionality to track and export deployed contract addresses
 */
contract AddressWriter is Script {
    struct DeploymentAddresses {
        address token;
        address timelock;
        address governor;
        address treasury;
        address parameterModule;
        address pauseModule;
        address vestingVault;
        address merkleAirdrop;
        address fixedPriceSale;
        address escrowVault;
        address rateLimitedAdapter;
    }

    /// @notice File path for addresses JSON
    string constant ADDRESSES_FILE = "./addresses.json";
    
    /// @notice Deployment addresses storage
    DeploymentAddresses public addresses;

    /**
     * @notice Sets the token address
     * @param _token Token contract address
     */
    function setToken(address _token) external {
        addresses.token = _token;
        console.log("Token address set:", _token);
    }

    /**
     * @notice Sets the timelock address
     * @param _timelock Timelock contract address
     */
    function setTimelock(address _timelock) external {
        addresses.timelock = _timelock;
        console.log("Timelock address set:", _timelock);
    }

    /**
     * @notice Sets the governor address
     * @param _governor Governor contract address
     */
    function setGovernor(address _governor) external {
        addresses.governor = _governor;
        console.log("Governor address set:", _governor);
    }

    /**
     * @notice Sets the treasury address
     * @param _treasury Treasury contract address
     */
    function setTreasury(address _treasury) external {
        addresses.treasury = _treasury;
        console.log("Treasury address set:", _treasury);
    }

    /**
     * @notice Sets the parameter module address
     * @param _parameterModule Parameter module contract address
     */
    function setParameterModule(address _parameterModule) external {
        addresses.parameterModule = _parameterModule;
        console.log("Parameter module address set:", _parameterModule);
    }

    /**
     * @notice Sets the pause module address
     * @param _pauseModule Pause module contract address
     */
    function setPauseModule(address _pauseModule) external {
        addresses.pauseModule = _pauseModule;
        console.log("Pause module address set:", _pauseModule);
    }

    /**
     * @notice Sets the vesting vault address
     * @param _vestingVault Vesting vault contract address
     */
    function setVestingVault(address _vestingVault) external {
        addresses.vestingVault = _vestingVault;
        console.log("Vesting vault address set:", _vestingVault);
    }

    /**
     * @notice Sets the merkle airdrop address
     * @param _merkleAirdrop Merkle airdrop contract address
     */
    function setMerkleAirdrop(address _merkleAirdrop) external {
        addresses.merkleAirdrop = _merkleAirdrop;
        console.log("Merkle airdrop address set:", _merkleAirdrop);
    }

    /**
     * @notice Sets the fixed price sale address
     * @param _fixedPriceSale Fixed price sale contract address
     */
    function setFixedPriceSale(address _fixedPriceSale) external {
        addresses.fixedPriceSale = _fixedPriceSale;
        console.log("Fixed price sale address set:", _fixedPriceSale);
    }

    /**
     * @notice Sets the escrow vault address
     * @param _escrowVault Escrow vault contract address
     */
    function setEscrowVault(address _escrowVault) external {
        addresses.escrowVault = _escrowVault;
        console.log("Escrow vault address set:", _escrowVault);
    }

    /**
     * @notice Sets the rate limited adapter address
     * @param _rateLimitedAdapter Rate limited adapter contract address
     */
    function setRateLimitedAdapter(address _rateLimitedAdapter) external {
        addresses.rateLimitedAdapter = _rateLimitedAdapter;
        console.log("Rate limited adapter address set:", _rateLimitedAdapter);
    }

    /**
     * @notice Writes all addresses to JSON file
     */
    function writeAddresses() external {
        console.log("Writing addresses to file:", ADDRESSES_FILE);
        
        string memory json = string.concat(
            "{\n",
            '  "network": "', vm.toString(block.chainid), '",\n',
            '  "timestamp": "', vm.toString(block.timestamp), '",\n',
            '  "contracts": {\n',
            '    "token": "', vm.toString(addresses.token), '",\n',
            '    "timelock": "', vm.toString(addresses.timelock), '",\n',
            '    "governor": "', vm.toString(addresses.governor), '",\n',
            '    "treasury": "', vm.toString(addresses.treasury), '",\n',
            '    "parameterModule": "', vm.toString(addresses.parameterModule), '",\n',
            '    "pauseModule": "', vm.toString(addresses.pauseModule), '",\n',
            '    "vestingVault": "', vm.toString(addresses.vestingVault), '",\n',
            '    "merkleAirdrop": "', vm.toString(addresses.merkleAirdrop), '",\n',
            '    "fixedPriceSale": "', vm.toString(addresses.fixedPriceSale), '",\n',
            '    "escrowVault": "', vm.toString(addresses.escrowVault), '",\n',
            '    "rateLimitedAdapter": "', vm.toString(addresses.rateLimitedAdapter), '"\n',
            "  }\n",
            "}"
        );
        
        vm.writeFile(ADDRESSES_FILE, json);
        console.log("Addresses written successfully");
    }

    /**
     * @notice Prints all stored addresses to console
     */
    function printAddresses() external view {
        console.log("=== DEPLOYMENT ADDRESSES ===");
        console.log("Network:", vm.toString(block.chainid));
        console.log("Token:", addresses.token);
        console.log("Timelock:", addresses.timelock);
        console.log("Governor:", addresses.governor);
        console.log("Treasury:", addresses.treasury);
        console.log("Parameter Module:", addresses.parameterModule);
        console.log("Pause Module:", addresses.pauseModule);
        console.log("Vesting Vault:", addresses.vestingVault);
        console.log("Merkle Airdrop:", addresses.merkleAirdrop);
        console.log("Fixed Price Sale:", addresses.fixedPriceSale);
        console.log("Escrow Vault:", addresses.escrowVault);
        console.log("Rate Limited Adapter:", addresses.rateLimitedAdapter);
        console.log("=== END ADDRESSES ===");
    }

    /**
     * @notice Validates that all required addresses are set
     * @return Whether all core addresses are non-zero
     */
    function validateCoreAddresses() external view returns (bool) {
        return addresses.token != address(0) &&
               addresses.timelock != address(0) &&
               addresses.governor != address(0) &&
               addresses.treasury != address(0) &&
               addresses.parameterModule != address(0) &&
               addresses.vestingVault != address(0);
    }

    /**
     * @notice Gets all addresses as a struct
     * @return DeploymentAddresses struct with all addresses
     */
    function getAddresses() external view returns (DeploymentAddresses memory) {
        return addresses;
    }
}