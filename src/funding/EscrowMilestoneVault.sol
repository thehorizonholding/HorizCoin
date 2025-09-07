// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title EscrowMilestoneVault
 * @notice Milestone-based release vault with governance approvals
 * @dev Supports multiple projects with milestone-based fund release
 */
contract EscrowMilestoneVault is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role for creating and managing projects
    bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");
    
    /// @notice Role for approving milestones (should be governance)
    bytes32 public constant MILESTONE_APPROVER_ROLE = keccak256("MILESTONE_APPROVER_ROLE");
    
    /// @notice Role for emergency operations
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    /// @notice Milestone status enumeration
    enum MilestoneStatus {
        Pending,     // Milestone created but not submitted for approval
        Submitted,   // Milestone submitted for approval
        Approved,    // Milestone approved and funds released
        Rejected,    // Milestone rejected
        Cancelled    // Milestone cancelled
    }

    /// @notice Milestone structure
    struct Milestone {
        string description;           // Milestone description
        uint256 amount;              // Amount to be released
        uint256 deadline;            // Milestone deadline
        MilestoneStatus status;      // Current status
        uint256 submittedAt;         // When milestone was submitted for approval
        uint256 approvedAt;          // When milestone was approved
        address approver;            // Who approved the milestone
        string deliverableHash;      // IPFS hash of deliverable documents
    }

    /// @notice Project structure
    struct Project {
        address beneficiary;         // Project beneficiary address
        IERC20 token;               // Token being escrowed
        uint256 totalAmount;        // Total project amount
        uint256 releasedAmount;     // Amount already released
        uint256 startTime;          // Project start time
        uint256 endTime;            // Project end time
        bool active;                // Whether project is active
        string metadataHash;        // IPFS hash of project metadata
        uint256 milestoneCount;     // Number of milestones
    }

    /// @notice Mapping of project ID to project details
    mapping(uint256 => Project) public projects;
    
    /// @notice Mapping of project ID to milestone ID to milestone details
    mapping(uint256 => mapping(uint256 => Milestone)) public milestones;
    
    /// @notice Mapping of beneficiary address to their project IDs
    mapping(address => uint256[]) public beneficiaryProjects;
    
    /// @notice Next project ID
    uint256 public nextProjectId;
    
    /// @notice Total amount escrowed across all projects
    uint256 public totalEscrowed;
    
    /// @notice Total amount released across all projects
    uint256 public totalReleased;
    
    /// @notice Approval timeout period (default 30 days)
    uint256 public approvalTimeout = 30 days;

    /// @notice Emitted when a project is created
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed beneficiary,
        address indexed token,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        string metadataHash
    );
    
    /// @notice Emitted when a milestone is created
    event MilestoneCreated(
        uint256 indexed projectId,
        uint256 indexed milestoneId,
        string description,
        uint256 amount,
        uint256 deadline
    );
    
    /// @notice Emitted when a milestone is submitted for approval
    event MilestoneSubmitted(
        uint256 indexed projectId,
        uint256 indexed milestoneId,
        string deliverableHash
    );
    
    /// @notice Emitted when a milestone is approved
    event MilestoneApproved(
        uint256 indexed projectId,
        uint256 indexed milestoneId,
        address indexed approver,
        uint256 amount
    );
    
    /// @notice Emitted when a milestone is rejected
    event MilestoneRejected(
        uint256 indexed projectId,
        uint256 indexed milestoneId,
        address indexed approver,
        string reason
    );
    
    /// @notice Emitted when funds are released
    event FundsReleased(
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount
    );

    /// @notice Error thrown when insufficient balance
    error InsufficientBalance();
    
    /// @notice Error thrown when invalid parameters
    error InvalidParameters();
    
    /// @notice Error thrown when project doesn't exist
    error ProjectNotExists();
    
    /// @notice Error thrown when milestone doesn't exist
    error MilestoneNotExists();
    
    /// @notice Error thrown when project is not active
    error ProjectNotActive();
    
    /// @notice Error thrown when milestone already submitted
    error MilestoneAlreadySubmitted();
    
    /// @notice Error thrown when milestone not in correct status
    error InvalidMilestoneStatus();
    
    /// @notice Error thrown when deadline passed
    error DeadlinePassed();
    
    /// @notice Error thrown when unauthorized access
    error Unauthorized();

    /**
     * @notice Constructs the EscrowMilestoneVault
     * @param _admin Admin address for role management
     * @param _governanceApprover Governance address for milestone approvals
     */
    constructor(address _admin, address _governanceApprover) {
        if (_admin == address(0) || _governanceApprover == address(0)) revert InvalidParameters();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PROJECT_ADMIN_ROLE, _admin);
        _grantRole(MILESTONE_APPROVER_ROLE, _governanceApprover);
        _grantRole(EMERGENCY_ROLE, _admin);
    }

    /**
     * @notice Creates a new project with milestones
     * @param beneficiary Project beneficiary address
     * @param token Token to be escrowed
     * @param totalAmount Total amount for the project
     * @param startTime Project start time
     * @param endTime Project end time
     * @param metadataHash IPFS hash of project metadata
     * @param milestoneDescriptions Array of milestone descriptions
     * @param milestoneAmounts Array of milestone amounts
     * @param milestoneDeadlines Array of milestone deadlines
     * @return projectId Created project ID
     */
    function createProject(
        address beneficiary,
        IERC20 token,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime,
        string calldata metadataHash,
        string[] calldata milestoneDescriptions,
        uint256[] calldata milestoneAmounts,
        uint256[] calldata milestoneDeadlines
    ) external onlyRole(PROJECT_ADMIN_ROLE) whenNotPaused returns (uint256 projectId) {
        if (beneficiary == address(0) || address(token) == address(0) || totalAmount == 0) {
            revert InvalidParameters();
        }
        if (endTime <= startTime) revert InvalidParameters();
        if (milestoneDescriptions.length != milestoneAmounts.length ||
            milestoneDescriptions.length != milestoneDeadlines.length) {
            revert InvalidParameters();
        }
        
        // Verify total milestone amounts equal project amount
        uint256 totalMilestoneAmount = 0;
        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            totalMilestoneAmount += milestoneAmounts[i];
        }
        if (totalMilestoneAmount != totalAmount) revert InvalidParameters();
        
        // Check if sufficient tokens are available
        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalEscrowed + totalAmount) revert InsufficientBalance();
        
        projectId = nextProjectId++;
        
        projects[projectId] = Project({
            beneficiary: beneficiary,
            token: token,
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: startTime,
            endTime: endTime,
            active: true,
            metadataHash: metadataHash,
            milestoneCount: milestoneDescriptions.length
        });
        
        // Create milestones
        for (uint256 i = 0; i < milestoneDescriptions.length; i++) {
            milestones[projectId][i] = Milestone({
                description: milestoneDescriptions[i],
                amount: milestoneAmounts[i],
                deadline: milestoneDeadlines[i],
                status: MilestoneStatus.Pending,
                submittedAt: 0,
                approvedAt: 0,
                approver: address(0),
                deliverableHash: ""
            });
            
            emit MilestoneCreated(
                projectId,
                i,
                milestoneDescriptions[i],
                milestoneAmounts[i],
                milestoneDeadlines[i]
            );
        }
        
        beneficiaryProjects[beneficiary].push(projectId);
        totalEscrowed += totalAmount;
        
        emit ProjectCreated(
            projectId,
            beneficiary,
            address(token),
            totalAmount,
            startTime,
            endTime,
            metadataHash
        );
    }

    /**
     * @notice Submits a milestone for approval
     * @param projectId Project ID
     * @param milestoneId Milestone ID
     * @param deliverableHash IPFS hash of deliverable documents
     */
    function submitMilestone(
        uint256 projectId,
        uint256 milestoneId,
        string calldata deliverableHash
    ) external nonReentrant whenNotPaused {
        Project storage project = projects[projectId];
        if (project.beneficiary == address(0)) revert ProjectNotExists();
        if (!project.active) revert ProjectNotActive();
        if (msg.sender != project.beneficiary) revert Unauthorized();
        if (milestoneId >= project.milestoneCount) revert MilestoneNotExists();
        
        Milestone storage milestone = milestones[projectId][milestoneId];
        if (milestone.status != MilestoneStatus.Pending) revert MilestoneAlreadySubmitted();
        if (block.timestamp > milestone.deadline) revert DeadlinePassed();
        
        milestone.status = MilestoneStatus.Submitted;
        milestone.submittedAt = block.timestamp;
        milestone.deliverableHash = deliverableHash;
        
        emit MilestoneSubmitted(projectId, milestoneId, deliverableHash);
    }

    /**
     * @notice Approves a milestone and releases funds
     * @param projectId Project ID
     * @param milestoneId Milestone ID
     */
    function approveMilestone(
        uint256 projectId,
        uint256 milestoneId
    ) external onlyRole(MILESTONE_APPROVER_ROLE) nonReentrant whenNotPaused {
        Project storage project = projects[projectId];
        if (project.beneficiary == address(0)) revert ProjectNotExists();
        if (!project.active) revert ProjectNotActive();
        if (milestoneId >= project.milestoneCount) revert MilestoneNotExists();
        
        Milestone storage milestone = milestones[projectId][milestoneId];
        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneStatus();
        
        // Check if approval timeout hasn't passed
        if (block.timestamp > milestone.submittedAt + approvalTimeout) {
            milestone.status = MilestoneStatus.Rejected;
            emit MilestoneRejected(projectId, milestoneId, msg.sender, "Approval timeout");
            return;
        }
        
        milestone.status = MilestoneStatus.Approved;
        milestone.approvedAt = block.timestamp;
        milestone.approver = msg.sender;
        
        // Release funds
        project.releasedAmount += milestone.amount;
        totalReleased += milestone.amount;
        totalEscrowed -= milestone.amount;
        
        project.token.safeTransfer(project.beneficiary, milestone.amount);
        
        emit MilestoneApproved(projectId, milestoneId, msg.sender, milestone.amount);
        emit FundsReleased(projectId, project.beneficiary, milestone.amount);
    }

    /**
     * @notice Rejects a milestone
     * @param projectId Project ID
     * @param milestoneId Milestone ID
     * @param reason Rejection reason
     */
    function rejectMilestone(
        uint256 projectId,
        uint256 milestoneId,
        string calldata reason
    ) external onlyRole(MILESTONE_APPROVER_ROLE) {
        Project storage project = projects[projectId];
        if (project.beneficiary == address(0)) revert ProjectNotExists();
        if (milestoneId >= project.milestoneCount) revert MilestoneNotExists();
        
        Milestone storage milestone = milestones[projectId][milestoneId];
        if (milestone.status != MilestoneStatus.Submitted) revert InvalidMilestoneStatus();
        
        milestone.status = MilestoneStatus.Rejected;
        milestone.approver = msg.sender;
        
        emit MilestoneRejected(projectId, milestoneId, msg.sender, reason);
    }

    /**
     * @notice Batch approves multiple milestones
     * @param projectIds Array of project IDs
     * @param milestoneIds Array of milestone IDs
     */
    function batchApproveMilestones(
        uint256[] calldata projectIds,
        uint256[] calldata milestoneIds
    ) external onlyRole(MILESTONE_APPROVER_ROLE) nonReentrant whenNotPaused {
        if (projectIds.length != milestoneIds.length) revert InvalidParameters();
        
        for (uint256 i = 0; i < projectIds.length; i++) {
            uint256 projectId = projectIds[i];
            uint256 milestoneId = milestoneIds[i];
            
            Project storage project = projects[projectId];
            if (project.beneficiary == address(0) || !project.active) continue;
            if (milestoneId >= project.milestoneCount) continue;
            
            Milestone storage milestone = milestones[projectId][milestoneId];
            if (milestone.status != MilestoneStatus.Submitted) continue;
            if (block.timestamp > milestone.submittedAt + approvalTimeout) continue;
            
            milestone.status = MilestoneStatus.Approved;
            milestone.approvedAt = block.timestamp;
            milestone.approver = msg.sender;
            
            // Release funds
            project.releasedAmount += milestone.amount;
            totalReleased += milestone.amount;
            totalEscrowed -= milestone.amount;
            
            project.token.safeTransfer(project.beneficiary, milestone.amount);
            
            emit MilestoneApproved(projectId, milestoneId, msg.sender, milestone.amount);
            emit FundsReleased(projectId, project.beneficiary, milestone.amount);
        }
    }

    /**
     * @notice Cancels a project and returns remaining funds
     * @param projectId Project ID
     * @param returnTo Address to return funds to
     */
    function cancelProject(
        uint256 projectId,
        address returnTo
    ) external onlyRole(PROJECT_ADMIN_ROLE) {
        Project storage project = projects[projectId];
        if (project.beneficiary == address(0)) revert ProjectNotExists();
        if (!project.active) revert ProjectNotActive();
        
        uint256 remainingAmount = project.totalAmount - project.releasedAmount;
        
        project.active = false;
        totalEscrowed -= remainingAmount;
        
        if (remainingAmount > 0) {
            project.token.safeTransfer(returnTo, remainingAmount);
        }
        
        // Cancel all pending milestones
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            if (milestones[projectId][i].status == MilestoneStatus.Pending ||
                milestones[projectId][i].status == MilestoneStatus.Submitted) {
                milestones[projectId][i].status = MilestoneStatus.Cancelled;
            }
        }
    }

    /**
     * @notice Updates approval timeout
     * @param _newTimeout New timeout in seconds
     */
    function setApprovalTimeout(uint256 _newTimeout) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approvalTimeout = _newTimeout;
    }

    /**
     * @notice Gets project details
     * @param projectId Project ID
     * @return Project details
     */
    function getProject(uint256 projectId) external view returns (Project memory) {
        return projects[projectId];
    }

    /**
     * @notice Gets milestone details
     * @param projectId Project ID
     * @param milestoneId Milestone ID
     * @return Milestone details
     */
    function getMilestone(uint256 projectId, uint256 milestoneId) external view returns (Milestone memory) {
        return milestones[projectId][milestoneId];
    }

    /**
     * @notice Gets all projects for a beneficiary
     * @param beneficiary Beneficiary address
     * @return Array of project IDs
     */
    function getBeneficiaryProjects(address beneficiary) external view returns (uint256[] memory) {
        return beneficiaryProjects[beneficiary];
    }

    /**
     * @notice Gets pending milestones for approval
     * @param projectId Project ID
     * @return Array of milestone IDs with submitted status
     */
    function getPendingMilestones(uint256 projectId) external view returns (uint256[] memory) {
        Project memory project = projects[projectId];
        uint256[] memory pending = new uint256[](project.milestoneCount);
        uint256 count = 0;
        
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            if (milestones[projectId][i].status == MilestoneStatus.Submitted) {
                pending[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pending[i];
        }
        
        return result;
    }

    /**
     * @notice Emergency withdraw function
     * @param token Token to withdraw
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyRole(EMERGENCY_ROLE) {
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