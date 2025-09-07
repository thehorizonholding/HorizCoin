// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HorizErrors
 * @notice Centralized error definitions for HorizCoin contracts
 * @dev Provides consistent error handling across the ecosystem
 */
library HorizErrors {
    // General errors
    error InvalidAddress();
    error InvalidParameters();
    error Unauthorized();
    error NotImplemented();
    error OperationFailed();
    
    // Token errors
    error InsufficientBalance();
    error InsufficientAllowance();
    error TransferFailed();
    error MintFailed();
    error BurnFailed();
    error ExceedsMaxSupply();
    error TransfersPaused();
    
    // Governance errors
    error ProposalNotExists();
    error ProposalNotActive();
    error ProposalAlreadyExecuted();
    error ProposalExecutionFailed();
    error InsufficientVotes();
    error VotingPeriodEnded();
    error VotingPeriodNotStarted();
    error AlreadyVoted();
    error QuorumNotMet();
    error TooManyActions();
    error InvalidVotingPeriod();
    error InvalidQuorum();
    
    // Treasury errors
    error TreasuryInsufficientBalance();
    error TreasuryTransferFailed();
    error InvalidTreasuryOperation();
    error EmissionRateExceedsMaximum();
    error ReservationExceedsBalance();
    
    // Vesting errors
    error VestingNotExists();
    error VestingAlreadyRevoked();
    error VestingNotRevocable();
    error NoTokensReleasable();
    error VestingNotStarted();
    error CliffNotReached();
    
    // Airdrop errors
    error AirdropRoundNotExists();
    error AirdropRoundNotActive();
    error AirdropClaimNotStarted();
    error AirdropClaimPeriodEnded();
    error AirdropAlreadyClaimed();
    error AirdropInvalidProof();
    error AirdropInsufficientBalance();
    
    // Sale errors
    error SaleNotActive();
    error SaleNotStarted();
    error SaleEnded();
    error SaleInvalidPurchaseAmount();
    error SaleInsufficientSupply();
    error SalePaymentFailed();
    error SaleNotWhitelisted();
    error SaleMaxPurchaseExceeded();
    
    // Milestone errors
    error ProjectNotExists();
    error ProjectNotActive();
    error MilestoneNotExists();
    error MilestoneAlreadySubmitted();
    error MilestoneNotSubmitted();
    error MilestoneAlreadyApproved();
    error MilestoneDeadlinePassed();
    error MilestoneApprovalTimeout();
    error InsufficientProjectFunds();
    
    // Rate limiting errors
    error RateLimitExceeded();
    error InvalidRateLimit();
    error RateLimitWindowInvalid();
    
    // Pause errors
    error ContractPaused();
    error ContractNotPaused();
    error EmergencyPauseActive();
    error EmergencyPauseExpired();
    error CannotExtendEmergencyPause();
    
    // Access control errors
    error MissingRole();
    error RoleAlreadyGranted();
    error RoleNotGranted();
    error CannotRenounceLastAdmin();
    
    // Math errors
    error DivisionByZero();
    error MathOverflow();
    error MathUnderflow();
    error ExceedsMaxBasisPoints();
    error InvalidBasisPoints();
    
    // Time errors
    error InvalidTimestamp();
    error DeadlinePassed();
    error TooEarly();
    error TooLate();
    error InvalidDuration();
    
    // Merkle tree errors
    error InvalidMerkleProof();
    error InvalidMerkleRoot();
    error MerkleTreeEmpty();
    
    // Batch operation errors
    error BatchSizeExceedsMaximum();
    error BatchParameterMismatch();
    error BatchOperationFailed();
    
    // Reentrancy errors
    error ReentrantCall();
    
    // Initialization errors
    error AlreadyInitialized();
    error NotInitialized();
    error InitializationFailed();
}

/**
 * @title HorizEvents
 * @notice Centralized event definitions for HorizCoin contracts
 * @dev Provides consistent event schemas across the ecosystem
 */
library HorizEvents {
    // Governance events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 weight,
        string reason
    );
    
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    
    // Parameter changes
    event ParameterUpdated(string indexed name, uint256 oldValue, uint256 newValue);
    event StringParameterUpdated(string indexed name, string oldValue, string newValue);
    event AddressParameterUpdated(string indexed name, address oldValue, address newValue);
    event BoolParameterUpdated(string indexed name, bool oldValue, bool newValue);
    
    // Treasury events
    event FundsTransferred(
        address indexed token,
        address indexed to,
        uint256 amount,
        string purpose
    );
    
    event EmissionRateUpdated(uint256 oldRate, uint256 newRate);
    event EmissionsDistributed(address indexed recipient, uint256 amount);
    
    // Vesting events
    event VestingScheduleCreated(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration
    );
    
    event TokensVested(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount
    );
    
    event VestingRevoked(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 unvestedAmount
    );
    
    // Access control events
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    
    // Emergency events
    event EmergencyPauseActivated(address indexed trigger, uint256 timestamp);
    event EmergencyPauseDeactivated(address indexed trigger, uint256 timestamp);
    event EmergencyWithdrawal(address indexed token, address indexed to, uint256 amount);
    
    // Rate limiting events
    event RateLimitUpdated(address indexed contract, uint256 newLimit, uint256 windowDuration);
    event RateLimitExceeded(address indexed user, uint256 attemptedAmount, uint256 limit);
}