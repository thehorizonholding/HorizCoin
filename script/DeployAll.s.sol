// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// Import contracts
import "../src/token/HorizCoinToken.sol";
import "../src/governance/HorizGovernor.sol";
import "../src/governance/TimelockController.sol";
import "../src/governance/ParameterChangeModule.sol";
import "../src/governance/PauseModule.sol";
import "../src/treasury/HorizTreasury.sol";
import "../src/treasury/RateLimitedTreasuryAdapter.sol";
import "../src/distribution/VestingVault.sol";
import "../src/distribution/MerkleAirdrop.sol";
import "../src/distribution/FixedPriceSale.sol";
import "../src/funding/EscrowMilestoneVault.sol";

// Import helper
import "./helpers/AddressWriter.s.sol";

/**
 * @title DeployAll
 * @notice Main deployment script for HorizCoin ecosystem
 * @dev Deploys core contracts with conservative defaults for production safety
 */
contract DeployAll is Script {
    using stdJson for string;

    // Deployment configuration
    struct DeployConfig {
        address deployer;
        address multisig;
        address treasury;
        bool deployOptionalModules;
        uint256 votingDelay;          // In blocks
        uint256 votingPeriod;         // In blocks
        uint256 quorumFraction;       // In basis points (400 = 4%)
        uint256 proposalThreshold;    // In basis points
        uint256 timelockDelay;        // In seconds
        uint256 maxEmissionRate;      // Max emission rate for treasury
    }

    // Default configuration values (conservative for production)
    DeployConfig public config = DeployConfig({
        deployer: address(0),         // Set from msg.sender
        multisig: address(0),         // Set from env or deployer
        treasury: address(0),         // Set to deployer initially
        deployOptionalModules: false, // Comment out optional modules by default
        votingDelay: 1 days / 12,     // ~1 day in blocks (12s block time)
        votingPeriod: 7 days / 12,    // ~7 days in blocks
        quorumFraction: 400,          // 4% as specified
        proposalThreshold: 0,         // 0 initially, can be raised via governance
        timelockDelay: 2 days,        // 2 days as specified in guidance
        maxEmissionRate: 1000 * 1e18  // 1000 tokens per block max
    });

    // Contract instances
    HorizCoinToken public token;
    HorizTimelockController public timelock;
    HorizGovernor public governor;
    HorizTreasury public treasury;
    ParameterChangeModule public parameterModule;
    PauseModule public pauseModule;
    VestingVault public vestingVault;
    MerkleAirdrop public merkleAirdrop;
    FixedPriceSale public fixedPriceSale;
    EscrowMilestoneVault public escrowVault;
    RateLimitedTreasuryAdapter public rateLimitedAdapter;

    // Address writer for tracking deployments
    AddressWriter public addressWriter;

    function run() external {
        // Load configuration from environment
        _loadConfig();
        
        // Start deployment
        vm.startBroadcast(config.deployer);
        
        console.log("=== STARTING HORIZCOIN DEPLOYMENT ===");
        console.log("Deployer:", config.deployer);
        console.log("Network:", vm.toString(block.chainid));
        console.log("Block number:", vm.toString(block.number));
        
        // Initialize address writer
        addressWriter = new AddressWriter();
        
        // Deploy core contracts in dependency order
        _deployToken();
        _deployTimelock();
        _deployGovernor();
        _deployTreasury();
        _deployParameterModule();
        
        // Deploy optional modules (commented out by default)
        // Uncomment these lines to deploy optional modules
        // _deployPauseModule();
        // _deployRateLimitedAdapter();
        
        // Deploy distribution contracts
        _deployVestingVault();
        _deployMerkleAirdrop();
        _deployFixedPriceSale();
        
        // Deploy funding contracts
        _deployEscrowVault();
        
        // Configure contracts and transfer ownership
        _configureContracts();
        
        // Write addresses to file
        addressWriter.writeAddresses();
        addressWriter.printAddresses();
        
        console.log("=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
        console.log("Run post-deploy checklist: ./scripts/post-deploy-checklist.sh");
        
        vm.stopBroadcast();
    }

    function _loadConfig() internal {
        config.deployer = msg.sender;
        
        // Try to load multisig address from environment
        try vm.envAddress("MULTISIG_ADDRESS") returns (address multisig) {
            config.multisig = multisig;
            console.log("Loaded multisig address from env:", multisig);
        } catch {
            config.multisig = config.deployer;
            console.log("Using deployer as multisig (set MULTISIG_ADDRESS env var for production)");
        }
        
        // Try to load treasury address from environment
        try vm.envAddress("TREASURY_ADDRESS") returns (address treasuryAddr) {
            config.treasury = treasuryAddr;
            console.log("Loaded treasury address from env:", treasuryAddr);
        } catch {
            config.treasury = config.deployer;
            console.log("Using deployer as initial treasury");
        }
        
        // Load optional deployment flags
        try vm.envBool("DEPLOY_OPTIONAL_MODULES") returns (bool deployOptional) {
            config.deployOptionalModules = deployOptional;
        } catch {
            // Keep default false
        }
        
        console.log("Configuration loaded successfully");
    }

    function _deployToken() internal {
        console.log("Deploying HorizCoinToken...");
        
        token = new HorizCoinToken(
            config.deployer,  // Initial owner
            config.treasury   // Treasury for initial mint
        );
        
        addressWriter.setToken(address(token));
        console.log("HorizCoinToken deployed at:", address(token));
    }

    function _deployTimelock() internal {
        console.log("Deploying TimelockController...");
        
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        
        // Governor will be proposer, anyone can execute
        proposers[0] = config.deployer; // Temporarily, will be updated to governor
        executors[0] = address(0);      // Anyone can execute
        
        timelock = new HorizTimelockController(
            config.timelockDelay,
            proposers,
            executors,
            config.deployer  // Admin (will be renounced later)
        );
        
        addressWriter.setTimelock(address(timelock));
        console.log("TimelockController deployed at:", address(timelock));
    }

    function _deployGovernor() internal {
        console.log("Deploying HorizGovernor...");
        
        governor = new HorizGovernor(
            IVotes(address(token)),
            timelock,
            config.votingDelay,
            config.votingPeriod,
            config.quorumFraction,
            config.proposalThreshold
        );
        
        addressWriter.setGovernor(address(governor));
        console.log("HorizGovernor deployed at:", address(governor));
    }

    function _deployTreasury() internal {
        console.log("Deploying HorizTreasury...");
        
        treasury = new HorizTreasury(
            config.deployer,          // Admin
            address(timelock),        // Executor
            config.deployer,          // Emergency role
            config.maxEmissionRate    // Max emission rate
        );
        
        addressWriter.setTreasury(address(treasury));
        console.log("HorizTreasury deployed at:", address(treasury));
    }

    function _deployParameterModule() internal {
        console.log("Deploying ParameterChangeModule...");
        
        parameterModule = new ParameterChangeModule(
            address(timelock),  // Executor
            config.deployer     // Admin
        );
        
        addressWriter.setParameterModule(address(parameterModule));
        console.log("ParameterChangeModule deployed at:", address(parameterModule));
    }

    function _deployPauseModule() internal {
        console.log("Deploying PauseModule...");
        
        pauseModule = new PauseModule(
            config.deployer,     // Admin
            address(timelock),   // Timelock for pause/unpause
            config.deployer      // Emergency pauser
        );
        
        addressWriter.setPauseModule(address(pauseModule));
        console.log("PauseModule deployed at:", address(pauseModule));
    }

    function _deployVestingVault() internal {
        console.log("Deploying VestingVault...");
        
        vestingVault = new VestingVault(
            IERC20(address(token)),
            config.deployer  // Admin
        );
        
        addressWriter.setVestingVault(address(vestingVault));
        console.log("VestingVault deployed at:", address(vestingVault));
    }

    function _deployMerkleAirdrop() internal {
        console.log("Deploying MerkleAirdrop...");
        
        merkleAirdrop = new MerkleAirdrop(
            IERC20(address(token)),
            config.deployer  // Admin
        );
        
        addressWriter.setMerkleAirdrop(address(merkleAirdrop));
        console.log("MerkleAirdrop deployed at:", address(merkleAirdrop));
    }

    function _deployFixedPriceSale() internal {
        console.log("Deploying FixedPriceSale (STUB - NOT CONFIGURED)...");
        
        fixedPriceSale = new FixedPriceSale(
            config.deployer  // Admin
        );
        
        addressWriter.setFixedPriceSale(address(fixedPriceSale));
        console.log("FixedPriceSale (STUB) deployed at:", address(fixedPriceSale));
        console.log("WARNING: FixedPriceSale is a STUB with parameters set to 0");
        console.log("DO NOT ACTIVATE without proper configuration!");
    }

    function _deployEscrowVault() internal {
        console.log("Deploying EscrowMilestoneVault...");
        
        escrowVault = new EscrowMilestoneVault(
            config.deployer,     // Admin
            address(timelock)    // Governance approver
        );
        
        addressWriter.setEscrowVault(address(escrowVault));
        console.log("EscrowMilestoneVault deployed at:", address(escrowVault));
    }

    function _deployRateLimitedAdapter() internal {
        console.log("Deploying RateLimitedTreasuryAdapter...");
        
        rateLimitedAdapter = new RateLimitedTreasuryAdapter(
            config.deployer,        // Admin
            address(treasury),      // Treasury
            1 days,                 // Window duration
            10000 * 1e18           // Max spend per window
        );
        
        addressWriter.setRateLimitedAdapter(address(rateLimitedAdapter));
        console.log("RateLimitedTreasuryAdapter deployed at:", address(rateLimitedAdapter));
    }

    function _configureContracts() internal {
        console.log("Configuring contracts...");
        
        // Configure timelock to accept governor as proposer
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        timelock.grantRole(proposerRole, address(governor));
        timelock.revokeRole(proposerRole, config.deployer);
        
        console.log("✓ Timelock configured with governor as proposer");
        
        // Transfer token ownership to treasury initially
        token.transferOwnership(address(treasury));
        console.log("✓ Token ownership transferred to treasury");
        
        // Configure treasury to be owned by timelock
        bytes32 adminRole = treasury.DEFAULT_ADMIN_ROLE();
        treasury.grantRole(adminRole, address(timelock));
        treasury.renounceRole(adminRole, config.deployer);
        
        console.log("✓ Treasury admin role transferred to timelock");
        
        // Grant parameter module execution role to timelock
        bytes32 executorRole = parameterModule.EXECUTOR_ROLE();
        parameterModule.grantRole(executorRole, address(timelock));
        
        console.log("✓ Parameter module configured");
        
        // Transfer vesting vault admin to multisig
        bytes32 vestingAdminRole = vestingVault.DEFAULT_ADMIN_ROLE();
        vestingVault.grantRole(vestingAdminRole, config.multisig);
        vestingVault.renounceRole(vestingAdminRole, config.deployer);
        
        console.log("✓ Vesting vault admin transferred to multisig");
        
        // Transfer airdrop admin to multisig
        bytes32 airdropAdminRole = merkleAirdrop.DEFAULT_ADMIN_ROLE();
        merkleAirdrop.grantRole(airdropAdminRole, config.multisig);
        merkleAirdrop.renounceRole(airdropAdminRole, config.deployer);
        
        console.log("✓ Merkle airdrop admin transferred to multisig");
        
        // Configure escrow vault with timelock as approver
        bytes32 approverRole = escrowVault.MILESTONE_APPROVER_ROLE();
        escrowVault.grantRole(approverRole, address(timelock));
        
        console.log("✓ Escrow vault configured with timelock as approver");
        
        // Renounce timelock admin role (for production safety)
        // WARNING: Uncomment this for production deployment
        // bytes32 timelockAdminRole = timelock.TIMELOCK_ADMIN_ROLE();
        // timelock.renounceRole(timelockAdminRole, config.deployer);
        // console.log("✓ Timelock admin role renounced (governance-only control)");
        
        console.log("Contract configuration completed");
    }

    // Utility function to verify deployment
    function verifyDeployment() external view {
        require(addressWriter.validateCoreAddresses(), "Core addresses validation failed");
        
        console.log("=== DEPLOYMENT VERIFICATION ===");
        console.log("✓ All core contracts deployed");
        console.log("✓ Address validation passed");
        
        // Additional checks
        require(token.owner() == address(treasury), "Token ownership not transferred");
        require(treasury.hasRole(treasury.DEFAULT_ADMIN_ROLE(), address(timelock)), "Treasury not controlled by timelock");
        require(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)), "Governor not timelock proposer");
        
        console.log("✓ Contract configuration verified");
        console.log("=== VERIFICATION COMPLETE ===");
    }
}