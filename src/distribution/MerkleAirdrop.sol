// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MerkleAirdrop
 * @notice Claimable airdrop contract using Merkle tree for verification
 * @dev Supports multiple airdrop rounds with different Merkle roots
 */
contract MerkleAirdrop is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role for managing airdrop rounds
    bytes32 public constant AIRDROP_ADMIN_ROLE = keccak256("AIRDROP_ADMIN_ROLE");
    
    /// @notice Role for emergency operations
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /// @notice Airdrop round structure
    struct AirdropRound {
        bytes32 merkleRoot;        // Merkle tree root
        uint256 totalAmount;       // Total tokens allocated for this round
        uint256 claimedAmount;     // Total tokens claimed in this round
        uint256 startTime;         // Claim start time
        uint256 endTime;           // Claim end time
        bool active;               // Whether the round is active
        string ipfsHash;           // IPFS hash of the Merkle tree data
    }

    /// @notice Token being distributed
    IERC20 public immutable token;
    
    /// @notice Mapping of round ID to airdrop round details
    mapping(uint256 => AirdropRound) public airdropRounds;
    
    /// @notice Mapping of round ID to user address to claimed status
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    
    /// @notice Next round ID
    uint256 public nextRoundId;
    
    /// @notice Total amount allocated across all rounds
    uint256 public totalAllocated;
    
    /// @notice Total amount claimed across all rounds
    uint256 public totalClaimed;

    /// @notice Emitted when a new airdrop round is created
    event AirdropRoundCreated(
        uint256 indexed roundId,
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        string ipfsHash
    );
    
    /// @notice Emitted when an airdrop round is updated
    event AirdropRoundUpdated(
        uint256 indexed roundId,
        bytes32 merkleRoot,
        uint256 startTime,
        uint256 endTime,
        bool active
    );
    
    /// @notice Emitted when tokens are claimed
    event TokensClaimed(
        uint256 indexed roundId,
        address indexed claimer,
        uint256 amount
    );
    
    /// @notice Emitted when an airdrop round is deactivated
    event AirdropRoundDeactivated(uint256 indexed roundId);
    
    /// @notice Error thrown when insufficient balance
    error InsufficientBalance();
    
    /// @notice Error thrown when invalid parameters provided
    error InvalidParameters();
    
    /// @notice Error thrown when airdrop round doesn't exist
    error RoundNotExists();
    
    /// @notice Error thrown when airdrop round is not active
    error RoundNotActive();
    
    /// @notice Error thrown when claim period has not started
    error ClaimNotStarted();
    
    /// @notice Error thrown when claim period has ended
    error ClaimPeriodEnded();
    
    /// @notice Error thrown when already claimed
    error AlreadyClaimed();
    
    /// @notice Error thrown when invalid Merkle proof
    error InvalidProof();

    /**
     * @notice Constructs the MerkleAirdrop
     * @param _token Token contract address
     * @param _admin Admin address for role management
     */
    constructor(IERC20 _token, address _admin) {
        if (address(_token) == address(0) || _admin == address(0)) revert InvalidParameters();
        
        token = _token;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(AIRDROP_ADMIN_ROLE, _admin);
        _grantRole(EMERGENCY_ROLE, _admin);
    }

    /**
     * @notice Creates a new airdrop round
     * @param merkleRoot Merkle tree root
     * @param totalAmount Total tokens for this round
     * @param startTime Claim start time (0 for immediate)
     * @param endTime Claim end time (0 for no end)
     * @param ipfsHash IPFS hash of Merkle tree data
     * @return roundId Created round ID
     */
    function createAirdropRound(
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        string calldata ipfsHash
    ) external onlyRole(AIRDROP_ADMIN_ROLE) whenNotPaused returns (uint256 roundId) {
        if (merkleRoot == bytes32(0) || totalAmount == 0) revert InvalidParameters();
        if (startTime == 0) startTime = block.timestamp;
        if (endTime != 0 && endTime <= startTime) revert InvalidParameters();
        
        // Check if sufficient tokens are available
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAllocated + totalAmount) revert InsufficientBalance();
        
        roundId = nextRoundId++;
        
        airdropRounds[roundId] = AirdropRound({
            merkleRoot: merkleRoot,
            totalAmount: totalAmount,
            claimedAmount: 0,
            startTime: startTime,
            endTime: endTime,
            active: true,
            ipfsHash: ipfsHash
        });
        
        totalAllocated += totalAmount;
        
        emit AirdropRoundCreated(
            roundId,
            merkleRoot,
            totalAmount,
            startTime,
            endTime,
            ipfsHash
        );
    }

    /**
     * @notice Claims tokens from an airdrop round
     * @param roundId Airdrop round ID
     * @param amount Amount to claim
     * @param merkleProof Merkle proof for verification
     */
    function claim(
        uint256 roundId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant whenNotPaused {
        AirdropRound storage round = airdropRounds[roundId];
        
        if (round.merkleRoot == bytes32(0)) revert RoundNotExists();
        if (!round.active) revert RoundNotActive();
        if (block.timestamp < round.startTime) revert ClaimNotStarted();
        if (round.endTime != 0 && block.timestamp > round.endTime) revert ClaimPeriodEnded();
        if (hasClaimed[roundId][msg.sender]) revert AlreadyClaimed();
        
        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(merkleProof, round.merkleRoot, leaf)) revert InvalidProof();
        
        // Mark as claimed
        hasClaimed[roundId][msg.sender] = true;
        
        // Update claimed amounts
        round.claimedAmount += amount;
        totalClaimed += amount;
        
        // Transfer tokens
        token.safeTransfer(msg.sender, amount);
        
        emit TokensClaimed(roundId, msg.sender, amount);
    }

    /**
     * @notice Batch claim from multiple rounds
     * @param roundIds Array of round IDs
     * @param amounts Array of amounts to claim
     * @param merkleProofs Array of Merkle proofs
     */
    function batchClaim(
        uint256[] calldata roundIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external nonReentrant whenNotPaused {
        if (roundIds.length != amounts.length || roundIds.length != merkleProofs.length) {
            revert InvalidParameters();
        }
        
        for (uint256 i = 0; i < roundIds.length; i++) {
            uint256 roundId = roundIds[i];
            uint256 amount = amounts[i];
            bytes32[] calldata merkleProof = merkleProofs[i];
            
            AirdropRound storage round = airdropRounds[roundId];
            
            // Skip if round doesn't exist or conditions not met
            if (round.merkleRoot == bytes32(0) || 
                !round.active || 
                block.timestamp < round.startTime ||
                (round.endTime != 0 && block.timestamp > round.endTime) ||
                hasClaimed[roundId][msg.sender]) {
                continue;
            }
            
            // Verify Merkle proof
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
            if (!MerkleProof.verify(merkleProof, round.merkleRoot, leaf)) continue;
            
            // Mark as claimed
            hasClaimed[roundId][msg.sender] = true;
            
            // Update claimed amounts
            round.claimedAmount += amount;
            totalClaimed += amount;
            
            // Transfer tokens
            token.safeTransfer(msg.sender, amount);
            
            emit TokensClaimed(roundId, msg.sender, amount);
        }
    }

    /**
     * @notice Updates an existing airdrop round
     * @param roundId Round ID to update
     * @param merkleRoot New Merkle root (set to current if no change)
     * @param startTime New start time
     * @param endTime New end time
     * @param active Whether the round should be active
     */
    function updateAirdropRound(
        uint256 roundId,
        bytes32 merkleRoot,
        uint256 startTime,
        uint256 endTime,
        bool active
    ) external onlyRole(AIRDROP_ADMIN_ROLE) {
        AirdropRound storage round = airdropRounds[roundId];
        if (round.merkleRoot == bytes32(0)) revert RoundNotExists();
        
        if (merkleRoot != bytes32(0)) {
            round.merkleRoot = merkleRoot;
        }
        if (startTime != 0) {
            round.startTime = startTime;
        }
        if (endTime != 0 && endTime > startTime) {
            round.endTime = endTime;
        }
        
        round.active = active;
        
        emit AirdropRoundUpdated(roundId, round.merkleRoot, round.startTime, round.endTime, active);
    }

    /**
     * @notice Deactivates an airdrop round
     * @param roundId Round ID to deactivate
     */
    function deactivateRound(uint256 roundId) external onlyRole(AIRDROP_ADMIN_ROLE) {
        AirdropRound storage round = airdropRounds[roundId];
        if (round.merkleRoot == bytes32(0)) revert RoundNotExists();
        
        round.active = false;
        
        emit AirdropRoundDeactivated(roundId);
    }

    /**
     * @notice Checks if a user has claimed from a specific round
     * @param roundId Round ID
     * @param user User address
     * @return Whether the user has claimed
     */
    function hasUserClaimed(uint256 roundId, address user) external view returns (bool) {
        return hasClaimed[roundId][user];
    }

    /**
     * @notice Verifies a Merkle proof for a claim
     * @param roundId Round ID
     * @param user User address
     * @param amount Claim amount
     * @param merkleProof Merkle proof
     * @return Whether the proof is valid
     */
    function verifyProof(
        uint256 roundId,
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        AirdropRound memory round = airdropRounds[roundId];
        if (round.merkleRoot == bytes32(0)) return false;
        
        bytes32 leaf = keccak256(abi.encodePacked(user, amount));
        return MerkleProof.verify(merkleProof, round.merkleRoot, leaf);
    }

    /**
     * @notice Gets airdrop round details
     * @param roundId Round ID
     * @return Airdrop round details
     */
    function getAirdropRound(uint256 roundId) external view returns (AirdropRound memory) {
        return airdropRounds[roundId];
    }

    /**
     * @notice Gets the number of active rounds
     * @return Number of active rounds
     */
    function getActiveRoundsCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < nextRoundId; i++) {
            if (airdropRounds[i].active) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /**
     * @notice Withdraws unclaimed tokens after round expiry
     * @param roundId Round ID
     * @param to Recipient address
     */
    function withdrawUnclaimed(uint256 roundId, address to) external onlyRole(EMERGENCY_ROLE) {
        AirdropRound storage round = airdropRounds[roundId];
        if (round.merkleRoot == bytes32(0)) revert RoundNotExists();
        if (round.active) revert RoundNotActive();
        
        uint256 unclaimedAmount = round.totalAmount - round.claimedAmount;
        if (unclaimedAmount > 0) {
            totalAllocated -= unclaimedAmount;
            round.totalAmount = round.claimedAmount; // Update round total to claimed amount
            
            token.safeTransfer(to, unclaimedAmount);
        }
    }

    /**
     * @notice Emergency withdraw function
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyRole(EMERGENCY_ROLE) {
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}