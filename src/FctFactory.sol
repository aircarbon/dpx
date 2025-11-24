// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {FutureCarbonToken} from "./FutureCarbonToken.sol";
import {RedemptionVault} from "./RedemptionVault.sol";

/**
 * @title FctFactory
 * @dev Central factory contract for deploying and managing project tokens and redemption vaults.
 *
 * This contract serves as the registry and deployment factory for all DPX projects.
 * Only the owner (company multisig) can create new projects, which immediately deploys a token.
 *
 * Features:
 * - UUPS Upgradeable: Implementation can be upgraded to add new features
 * - Token Deployment: Creates FutureCarbonToken for new projects
 * - Vault Deployment: Creates RedemptionVault when project nears completion
 * - Registry: Maintains mappings of projects, tokens, and vaults
 * - Discovery: Query all projects, lookup by ID/token
 *
 * Lifecycle:
 * 1. Owner calls createProject() with project details
 * 2. FutureCarbonToken is automatically deployed
 * 3. Tokens are traded on exchange
 * 4. When project completes, owner calls deployVault() to create RedemptionVault
 * 5. Owner funds vault and activates redemption
 * 6. Token holders redeem their tokens for proceeds
 *
 * IMPORTANT: This contract uses UUPS proxy pattern. After deployment via proxy,
 * the owner can upgrade the implementation by calling upgradeToAndCall().
 * Storage layout must be preserved across upgrades (see storage gap).
 */
contract FctFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ============ Structs ============

    /// @notice Project information
    struct Project {
        uint256 projectId;          // Unique project identifier (auto-incremented)
        string name;                // Token name
        string symbol;              // Token symbol
        uint256 initialSupply;      // Initial token supply
        address tokenAddress;       // Deployed FutureCarbonToken address
        address vaultAddress;       // Deployed RedemptionVault address (0 if not deployed)
        uint256 createdAt;          // Timestamp of project creation
        uint256 vintageYear;        // Vintage year of the carbon credits
        string projectRegistryCode; // Project registry code (e.g., Verra ID)
    }

    // ============ State Variables ============

    /// @notice Counter for auto-incrementing project IDs
    uint256 private projectIdCounter;

    /// @notice Mapping from project ID to Project struct
    mapping(uint256 => Project) private projects;

    /// @notice Mapping from token address to project ID (reverse lookup)
    mapping(address => uint256) private tokenToProjectId;

    // ============ Events ============

    /// @notice Emitted when a new project is created and token is deployed
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 initialSupply,
        uint256 vintageYear,
        string projectRegistryCode
    );

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

    // ============ Owner Functions ============

    /**
     * @dev Create a new project and deploy its token
     * Only callable by owner (company multisig)
     *
     * @param name Token name (e.g., "Future Carbon Credit - Project Alpha")
     * @param symbol Token symbol (e.g., "FCC-ALPHA")
     * @param initialSupply Initial token supply (with 18 decimals)
     * @param vintageYear Vintage year of the carbon credits
     * @param projectRegistryCode Project registry code (e.g., Verra ID)
     * @param metadata Array of custom metadata key-value pairs
     * @return projectId The assigned project ID
     * @return tokenAddress The address of the deployed FutureCarbonToken
     *
     * This function:
     * 1. Validates input parameters
     * 2. Deploys a new FutureCarbonToken with all project details
     * 3. Creates a project record in the registry
     * 4. Registers the token for reverse lookup
     */
    function createProject(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 vintageYear,
        string memory projectRegistryCode,
        FutureCarbonToken.MetadataEntry[] memory metadata
    ) external onlyOwner returns (uint256 projectId, address tokenAddress) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(initialSupply > 0, "Initial supply must be greater than 0");
        require(vintageYear > 0, "Vintage year must be greater than 0");
        require(bytes(projectRegistryCode).length > 0, "Project registry code cannot be empty");

        // Assign new project ID and increment counter
        projectId = projectIdCounter;
        projectIdCounter++;

        // Deploy FutureCarbonToken
        // Owner of the token is this factory's owner (company multisig)
        FutureCarbonToken token = new FutureCarbonToken(
            name,
            symbol,
            initialSupply,
            owner(),
            vintageYear,
            projectRegistryCode,
            metadata
        );

        tokenAddress = address(token);

        // Create project struct
        Project memory newProject = Project({
            projectId: projectId,
            name: name,
            symbol: symbol,
            initialSupply: initialSupply,
            tokenAddress: tokenAddress,
            vaultAddress: address(0),
            createdAt: block.timestamp,
            vintageYear: vintageYear,
            projectRegistryCode: projectRegistryCode
        });

        // Store project
        projects[projectId] = newProject;

        // Register token in reverse lookup
        tokenToProjectId[tokenAddress] = projectId;

        emit ProjectCreated(projectId, tokenAddress, name, symbol, initialSupply, vintageYear, projectRegistryCode);

        return (projectId, tokenAddress);
    }

    /**
     * @dev Deploy a redemption vault for a project
     * Only callable by owner (company multisig)
     *
     * @param projectId The project ID to deploy vault for
     * @param stablecoin The stablecoin address (e.g., USDT) for redemptions
     * @return vaultAddress The address of the deployed RedemptionVault
     *
     * NOTE: This is called when the project nears completion and carbon
     * credits are about to be sold. Each project can only have one vault.
     */
    function deployVault(uint256 projectId, address stablecoin)
        external
        onlyOwner
        projectMustExist(projectId)
        returns (address vaultAddress)
    {
        Project storage project = projects[projectId];
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
     * Consider using pagination in production or querying off-chain via events.
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
