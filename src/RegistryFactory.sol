// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {FutureCarbonToken} from "./FutureCarbonToken.sol";
import {RedemptionVault} from "./RedemptionVault.sol";

/**
 * @title RegistryFactory
 * @dev Central factory contract for deploying and managing project tokens and redemption vaults.
 *
 * This contract serves as the registry and deployment factory for all DPX projects.
 * Project developers propose projects, and the owner (company multisig) approves or denies them.
 * Upon approval, a FutureCarbonToken is deployed. Later, a RedemptionVault can be deployed.
 *
 * Features:
 * - UUPS Upgradeable: Implementation can be upgraded to add new features
 * - Project Lifecycle Management: Pending → Approved/Denied
 * - Token Deployment: Creates FutureCarbonToken for approved projects
 * - Vault Deployment: Creates RedemptionVault when project nears completion
 * - Registry: Maintains mappings of projects, tokens, and vaults
 * - Discovery: Query all projects, filter by status, lookup by ID/token
 *
 * Lifecycle:
 * 1. Developer calls proposeProject() with project details
 * 2. Owner reviews and calls approveProject() or denyProject()
 * 3. If approved, FutureCarbonToken is automatically deployed
 * 4. Tokens are traded on exchange
 * 5. When project completes, owner calls deployVault() to create RedemptionVault
 * 6. Owner funds vault and activates redemption
 * 7. Token holders redeem their tokens for proceeds
 *
 * IMPORTANT: This contract uses UUPS proxy pattern. After deployment via proxy,
 * the owner can upgrade the implementation by calling upgradeToAndCall().
 * Storage layout must be preserved across upgrades (see storage gap).
 */
contract RegistryFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ============ Enums ============

    /// @notice Project lifecycle status
    enum ProjectStatus {
        Pending,    // Project proposed, awaiting approval
        Approved,   // Project approved, token deployed
        Denied      // Project denied by owner
    }

    // ============ Structs ============

    /// @notice Project information
    struct Project {
        uint256 projectId;          // Unique project identifier (auto-incremented)
        string name;                // Token name
        string symbol;              // Token symbol
        uint256 initialSupply;      // Initial token supply
        address developer;          // Project developer address
        address tokenAddress;       // Deployed FutureCarbonToken address (0 if not approved)
        address vaultAddress;       // Deployed RedemptionVault address (0 if not deployed)
        ProjectStatus status;       // Current project status
        uint256 proposedAt;         // Timestamp of proposal
        uint256 processedAt;        // Timestamp of approval/denial
        string metadata;            // Optional metadata (e.g., off-chain identifier, IPFS hash)
    }

    // ============ State Variables ============

    /// @notice Counter for auto-incrementing project IDs
    uint256 private projectIdCounter;

    /// @notice Mapping from project ID to Project struct
    mapping(uint256 => Project) private projects;

    /// @notice Mapping from token address to project ID (reverse lookup)
    mapping(address => uint256) private tokenToProjectId;

    // ============ Events ============

    /// @notice Emitted when a new project is proposed
    event ProjectProposed(
        uint256 indexed projectId,
        address indexed developer,
        string name,
        string symbol,
        uint256 initialSupply,
        string metadata
    );

    /// @notice Emitted when a project is approved and token is deployed
    event ProjectApproved(
        uint256 indexed projectId,
        address indexed tokenAddress,
        address indexed developer
    );

    /// @notice Emitted when a project is denied
    event ProjectDenied(uint256 indexed projectId, address indexed developer);

    /// @notice Emitted when a redemption vault is deployed
    event VaultDeployed(
        uint256 indexed projectId,
        address indexed tokenAddress,
        address indexed vaultAddress,
        address stablecoin
    );

    // ============ Modifiers ============

    /// @notice Ensures project exists
    modifier projectMustExist(uint256 projectId) {
        require(projectId < projectIdCounter, "Project does not exist");
        _;
    }

    // ============ Constructor ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ============ Initialization ============

    /**
     * @dev Initializes the factory contract (replaces constructor for upgradeable contracts)
     * @param initialOwner The owner address (company multisig wallet)
     *
     * NOTE: This function can only be called once during proxy deployment
     */
    function initialize(address initialOwner) public initializer {
        require(initialOwner != address(0), "Owner cannot be zero address");

        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    // ============ Project Proposal Functions ============

    /**
     * @dev Propose a new project
     * Called by project developers to submit a project for approval
     *
     * @param name Token name (e.g., "Future Carbon Credit - Project Alpha")
     * @param symbol Token symbol (e.g., "FCC-ALPHA")
     * @param initialSupply Initial token supply (with 18 decimals)
     * @param metadata Optional metadata (e.g., off-chain identifier, IPFS hash, project description)
     * @return projectId The assigned project ID
     *
     * NOTE: Project ID is auto-generated. The project will be in Pending status until owner approves/denies
     */
    function proposeProject(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        string memory metadata
    ) external returns (uint256 projectId) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(initialSupply > 0, "Initial supply must be greater than 0");

        // Assign new project ID and increment counter
        projectId = projectIdCounter;
        projectIdCounter++;

        // Create project struct
        Project memory newProject = Project({
            projectId: projectId,
            name: name,
            symbol: symbol,
            initialSupply: initialSupply,
            developer: msg.sender,
            tokenAddress: address(0),
            vaultAddress: address(0),
            status: ProjectStatus.Pending,
            proposedAt: block.timestamp,
            processedAt: 0,
            metadata: metadata
        });

        // Store project
        projects[projectId] = newProject;

        emit ProjectProposed(projectId, msg.sender, name, symbol, initialSupply, metadata);

        return projectId;
    }

    // ============ Owner Functions ============

    /**
     * @dev Approve a project and deploy its token
     * Only callable by owner (company multisig)
     *
     * @param projectId The project ID to approve
     * @return tokenAddress The address of the deployed FutureCarbonToken
     *
     * This function:
     * 1. Validates the project is in Pending status
     * 2. Deploys a new FutureCarbonToken
     * 3. Updates project status to Approved
     * 4. Registers the token in the registry
     */
    function approveProject(uint256 projectId)
        external
        onlyOwner
        projectMustExist(projectId)
        returns (address tokenAddress)
    {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Pending, "Project not in Pending status");

        // Deploy FutureCarbonToken
        // Owner of the token is this factory's owner (company multisig)
        FutureCarbonToken token = new FutureCarbonToken(
            project.name,
            project.symbol,
            project.initialSupply,
            owner()
        );

        tokenAddress = address(token);

        // Update project
        project.tokenAddress = tokenAddress;
        project.status = ProjectStatus.Approved;
        project.processedAt = block.timestamp;

        // Register token in reverse lookup
        tokenToProjectId[tokenAddress] = projectId;

        emit ProjectApproved(projectId, tokenAddress, project.developer);
    }

    /**
     * @dev Deny a project proposal
     * Only callable by owner (company multisig)
     *
     * @param projectId The project ID to deny
     */
    function denyProject(uint256 projectId)
        external
        onlyOwner
        projectMustExist(projectId)
    {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Pending, "Project not in Pending status");

        project.status = ProjectStatus.Denied;
        project.processedAt = block.timestamp;

        emit ProjectDenied(projectId, project.developer);
    }

    /**
     * @dev Deploy a redemption vault for an approved project
     * Only callable by owner (company multisig)
     *
     * @param projectId The project ID to deploy vault for
     * @param stablecoin The stablecoin address (e.g., USDT) for redemptions
     * @return vaultAddress The address of the deployed RedemptionVault
     *
     * NOTE: This is called separately from approval, typically when the project
     * nears completion and carbon credits are about to be sold.
     */
    function deployVault(uint256 projectId, address stablecoin)
        external
        onlyOwner
        projectMustExist(projectId)
        returns (address vaultAddress)
    {
        Project storage project = projects[projectId];
        require(project.status == ProjectStatus.Approved, "Project not approved");
        require(project.tokenAddress != address(0), "Token not deployed");
        require(project.vaultAddress == address(0), "Vault already deployed");
        require(stablecoin != address(0), "Stablecoin cannot be zero address");

        // Deploy RedemptionVault
        // Owner of the vault is this factory's owner (company multisig)
        RedemptionVault vault = new RedemptionVault(
            project.tokenAddress,
            stablecoin,
            owner()
        );

        vaultAddress = address(vault);

        // Update project
        project.vaultAddress = vaultAddress;

        emit VaultDeployed(projectId, project.tokenAddress, vaultAddress, stablecoin);
    }

    // ============ Query Functions ============

    /**
     * @dev Get project information by project ID
     * @param projectId The project ID to query
     * @return project The project information
     */
    function getProject(uint256 projectId)
        external
        view
        projectMustExist(projectId)
        returns (Project memory project)
    {
        return projects[projectId];
    }

    /**
     * @dev Get all projects
     * @return allProjects Array of all projects
     *
     * NOTE: This can be gas-intensive if there are many projects.
     * Consider using pagination in production.
     */
    function getAllProjects() external view returns (Project[] memory allProjects) {
        uint256 count = projectIdCounter;
        allProjects = new Project[](count);

        for (uint256 i = 0; i < count; i++) {
            allProjects[i] = projects[i];
        }

        return allProjects;
    }

    /**
     * @dev Get projects filtered by status
     * @param status The status to filter by
     * @return filteredProjects Array of projects with the specified status
     */
    function getProjectsByStatus(ProjectStatus status)
        external
        view
        returns (Project[] memory filteredProjects)
    {
        // Count matching projects
        uint256 count = 0;
        for (uint256 i = 0; i < projectIdCounter; i++) {
            if (projects[i].status == status) {
                count++;
            }
        }

        // Populate result array
        filteredProjects = new Project[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < projectIdCounter; i++) {
            if (projects[i].status == status) {
                filteredProjects[index] = projects[i];
                index++;
            }
        }

        return filteredProjects;
    }

    /**
     * @dev Get vault address for a token
     * @param tokenAddress The token address to query
     * @return vaultAddress The vault address (address(0) if not deployed)
     */
    function getVaultForToken(address tokenAddress) external view returns (address vaultAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");

        uint256 projectId = tokenToProjectId[tokenAddress];
        require(projectId < projectIdCounter, "Token not found in registry");
        require(projects[projectId].tokenAddress == tokenAddress, "Token not found in registry");

        return projects[projectId].vaultAddress;
    }

    /**
     * @dev Get token address for a project
     * @param projectId The project ID to query
     * @return tokenAddress The token address (address(0) if not approved)
     */
    function getTokenForProject(uint256 projectId)
        external
        view
        projectMustExist(projectId)
        returns (address tokenAddress)
    {
        return projects[projectId].tokenAddress;
    }

    /**
     * @dev Get project ID for a token address
     * @param tokenAddress The token address to query
     * @return projectId The project ID
     */
    function getProjectIdForToken(address tokenAddress)
        external
        view
        returns (uint256 projectId)
    {
        require(tokenAddress != address(0), "Token address cannot be zero");

        projectId = tokenToProjectId[tokenAddress];
        require(projectId < projectIdCounter, "Token not found in registry");
        require(projects[projectId].tokenAddress == tokenAddress, "Token not found in registry");

        return projectId;
    }

    /**
     * @dev Get total number of projects
     * @return count Total number of projects
     */
    function getProjectCount() external view returns (uint256 count) {
        return projectIdCounter;
    }

    /**
     * @dev Check if a project exists
     * @param projectId The project ID to check
     * @return exists True if project exists
     */
    function projectIdExists(uint256 projectId) external view returns (bool exists) {
        return projectId < projectIdCounter;
    }

    /**
     * @dev Get the next project ID that will be assigned
     * @return nextId The next project ID
     */
    function getNextProjectId() external view returns (uint256 nextId) {
        return projectIdCounter;
    }

    // ============ Upgrade Functions ============

    /**
     * @dev Function that authorizes an upgrade to a new implementation
     * Only callable by the owner
     * @param newImplementation Address of the new implementation contract
     *
     * IMPORTANT: This function is called by the UUPS proxy before upgrading.
     * By requiring onlyOwner, we ensure only the contract owner can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============ Storage Gap ============

    /**
     * @dev Storage gap for future upgrades
     * This empty reserved space allows us to add new state variables in future upgrades
     * without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * Current storage usage: ~6 slots (mappings and arrays use separate storage)
     * Reserved: 50 slots for future variables
     */
    uint256[50] private __gap;
}
