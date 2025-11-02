// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RegistryFactory} from "../src/RegistryFactory.sol";
import {FutureCarbonToken} from "../src/FutureCarbonToken.sol";
import {RedemptionVault} from "../src/RedemptionVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RegistryFactoryTest
 * @dev Comprehensive test suite for RegistryFactory contract
 * Tests initialization, project lifecycle, deployments, queries, and UUPS upgrades
 */
contract RegistryFactoryTest is Test {
    RegistryFactory public factory;
    RegistryFactory public implementation;
    ERC1967Proxy public proxy;

    address public owner;
    address public developer1;
    address public developer2;
    address public user1;
    address public mockStablecoin;

    // Test project parameters
    string constant PROJECT_NAME = "Future Carbon Credit - Project Alpha";
    string constant PROJECT_SYMBOL = "FCC-ALPHA";
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    string constant PROJECT_METADATA = "ipfs://QmXYZ123";

    // Events to test
    event ProjectProposed(
        uint256 indexed projectId,
        address indexed developer,
        string name,
        string symbol,
        uint256 initialSupply,
        string metadata
    );

    event ProjectApproved(
        uint256 indexed projectId,
        address indexed tokenAddress,
        address indexed developer
    );

    event ProjectDenied(uint256 indexed projectId, address indexed developer);

    event VaultDeployed(
        uint256 indexed projectId,
        address indexed tokenAddress,
        address indexed vaultAddress,
        address stablecoin
    );

    function setUp() public {
        owner = address(this);
        developer1 = address(0x1);
        developer2 = address(0x2);
        user1 = address(0x3);
        mockStablecoin = address(0x4);

        // Deploy implementation
        implementation = new RegistryFactory();

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(
            RegistryFactory.initialize.selector,
            owner
        );

        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Wrap proxy with interface
        factory = RegistryFactory(address(proxy));
    }

    // ========== Initialization Tests ==========

    function test_Initialization() public view {
        assertEq(factory.owner(), owner);
        assertEq(factory.getProjectCount(), 0);
        assertEq(factory.getNextProjectId(), 0);
    }

    function test_CannotInitializeTwice() public {
        vm.expectRevert();
        factory.initialize(owner);
    }

    function test_CannotInitializeImplementation() public {
        RegistryFactory newImpl = new RegistryFactory();
        vm.expectRevert();
        newImpl.initialize(owner);
    }

    function test_RevertInitializeWithZeroAddress() public {
        RegistryFactory newImpl = new RegistryFactory();

        bytes memory initData = abi.encodeWithSelector(
            RegistryFactory.initialize.selector,
            address(0)
        );

        vm.expectRevert("Owner cannot be zero address");
        new ERC1967Proxy(address(newImpl), initData);
    }

    // ========== proposeProject Tests ==========

    function test_ProposeProject() public {
        vm.prank(developer1);

        vm.expectEmit(true, true, false, true);
        emit ProjectProposed(0, developer1, PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, PROJECT_METADATA);

        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        assertEq(projectId, 0);
        assertEq(factory.getProjectCount(), 1);
        assertEq(factory.getNextProjectId(), 1);

        RegistryFactory.Project memory project = factory.getProject(0);
        assertEq(project.projectId, 0);
        assertEq(project.name, PROJECT_NAME);
        assertEq(project.symbol, PROJECT_SYMBOL);
        assertEq(project.initialSupply, INITIAL_SUPPLY);
        assertEq(project.developer, developer1);
        assertEq(project.tokenAddress, address(0));
        assertEq(project.vaultAddress, address(0));
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Pending));
        assertEq(project.proposedAt, block.timestamp);
        assertEq(project.processedAt, 0);
        assertEq(project.metadata, PROJECT_METADATA);
    }

    function test_ProposeMultipleProjects() public {
        // First project by developer1
        vm.prank(developer1);
        uint256 projectId1 = factory.proposeProject(
            "Project 1",
            "PRJ1",
            1000 * 10**18,
            "metadata1"
        );

        // Second project by developer2
        vm.prank(developer2);
        uint256 projectId2 = factory.proposeProject(
            "Project 2",
            "PRJ2",
            2000 * 10**18,
            "metadata2"
        );

        // Third project by developer1
        vm.prank(developer1);
        uint256 projectId3 = factory.proposeProject(
            "Project 3",
            "PRJ3",
            3000 * 10**18,
            "metadata3"
        );

        assertEq(projectId1, 0);
        assertEq(projectId2, 1);
        assertEq(projectId3, 2);
        assertEq(factory.getProjectCount(), 3);

        RegistryFactory.Project memory project2 = factory.getProject(1);
        assertEq(project2.developer, developer2);
        assertEq(project2.name, "Project 2");
    }

    function test_RevertProposeProjectEmptyName() public {
        vm.prank(developer1);
        vm.expectRevert("Name cannot be empty");
        factory.proposeProject(
            "",
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );
    }

    function test_RevertProposeProjectEmptySymbol() public {
        vm.prank(developer1);
        vm.expectRevert("Symbol cannot be empty");
        factory.proposeProject(
            PROJECT_NAME,
            "",
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );
    }

    function test_RevertProposeProjectZeroSupply() public {
        vm.prank(developer1);
        vm.expectRevert("Initial supply must be greater than 0");
        factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            0,
            PROJECT_METADATA
        );
    }

    function test_ProposeProjectWithEmptyMetadata() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            ""
        );

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(project.metadata, "");
    }

    function test_ProposeProjectWithLongMetadata() public {
        string memory longMetadata = "ipfs://QmVeryLongHashWithLotsOfCharactersToTestLargeMetadataHandling123456789";

        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            longMetadata
        );

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(project.metadata, longMetadata);
    }

    // ========== approveProject Tests ==========

    function test_ApproveProject() public {
        // First propose a project
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        // Approve it as owner
        // Note: We skip strict event checking here because tokenAddress is generated
        factory.approveProject(projectId);

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Approved));
        assertTrue(project.tokenAddress != address(0));
        assertEq(project.vaultAddress, address(0));
        assertEq(project.processedAt, block.timestamp);

        // Verify token was deployed correctly
        FutureCarbonToken token = FutureCarbonToken(project.tokenAddress);
        assertEq(token.name(), PROJECT_NAME);
        assertEq(token.symbol(), PROJECT_SYMBOL);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);

        // Verify reverse lookup
        assertEq(factory.getProjectIdForToken(project.tokenAddress), projectId);
        assertEq(factory.getTokenForProject(projectId), project.tokenAddress);
    }

    function test_ApproveMultipleProjects() public {
        // Propose two projects
        vm.prank(developer1);
        uint256 projectId1 = factory.proposeProject("Project 1", "PRJ1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        uint256 projectId2 = factory.proposeProject("Project 2", "PRJ2", 2000 * 10**18, "meta2");

        // Approve both
        factory.approveProject(projectId1);
        factory.approveProject(projectId2);

        RegistryFactory.Project memory project1 = factory.getProject(projectId1);
        RegistryFactory.Project memory project2 = factory.getProject(projectId2);

        assertTrue(project1.tokenAddress != address(0));
        assertTrue(project2.tokenAddress != address(0));
        assertTrue(project1.tokenAddress != project2.tokenAddress);

        assertEq(uint(project1.status), uint(RegistryFactory.ProjectStatus.Approved));
        assertEq(uint(project2.status), uint(RegistryFactory.ProjectStatus.Approved));
    }

    function test_RevertApproveProjectNotOwner() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        vm.prank(user1);
        vm.expectRevert();
        factory.approveProject(projectId);
    }

    function test_RevertApproveNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.approveProject(999);
    }

    function test_RevertApproveAlreadyApprovedProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        vm.expectRevert("Project not in Pending status");
        factory.approveProject(projectId);
    }

    function test_RevertApproveDeniedProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.denyProject(projectId);

        vm.expectRevert("Project not in Pending status");
        factory.approveProject(projectId);
    }

    // ========== denyProject Tests ==========

    function test_DenyProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        vm.expectEmit(true, true, false, false);
        emit ProjectDenied(projectId, developer1);

        factory.denyProject(projectId);

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Denied));
        assertEq(project.tokenAddress, address(0));
        assertEq(project.vaultAddress, address(0));
        assertEq(project.processedAt, block.timestamp);
    }

    function test_RevertDenyProjectNotOwner() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        vm.prank(user1);
        vm.expectRevert();
        factory.denyProject(projectId);
    }

    function test_RevertDenyNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.denyProject(999);
    }

    function test_RevertDenyAlreadyApprovedProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        vm.expectRevert("Project not in Pending status");
        factory.denyProject(projectId);
    }

    function test_RevertDenyAlreadyDeniedProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.denyProject(projectId);

        vm.expectRevert("Project not in Pending status");
        factory.denyProject(projectId);
    }

    // ========== deployVault Tests ==========

    function test_DeployVault() public {
        // Propose and approve project
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        // Deploy vault
        address vaultAddress = factory.deployVault(projectId, mockStablecoin);

        RegistryFactory.Project memory projectAfter = factory.getProject(projectId);
        assertEq(projectAfter.vaultAddress, vaultAddress);
        assertTrue(vaultAddress != address(0));

        // Verify vault was deployed correctly
        RedemptionVault vault = RedemptionVault(vaultAddress);
        assertEq(address(vault.futureToken()), projectAfter.tokenAddress);
        assertEq(address(vault.stablecoin()), mockStablecoin);
        assertEq(vault.owner(), owner);
        assertFalse(vault.redemptionActive());

        // Verify getVaultForToken works
        assertEq(factory.getVaultForToken(projectAfter.tokenAddress), vaultAddress);
    }

    function test_RevertDeployVaultNotOwner() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        vm.prank(user1);
        vm.expectRevert();
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.deployVault(999, mockStablecoin);
    }

    function test_RevertDeployVaultProjectNotApproved() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        vm.expectRevert("Project not approved");
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultForDeniedProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.denyProject(projectId);

        vm.expectRevert("Project not approved");
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultAlreadyDeployed() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);
        factory.deployVault(projectId, mockStablecoin);

        vm.expectRevert("Vault already deployed");
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultZeroAddressStablecoin() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        vm.expectRevert("Stablecoin cannot be zero address");
        factory.deployVault(projectId, address(0));
    }

    // ========== Query Function Tests ==========

    function test_GetProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(project.projectId, projectId);
        assertEq(project.name, PROJECT_NAME);
        assertEq(project.developer, developer1);
    }

    function test_RevertGetNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.getProject(999);
    }

    function test_GetAllProjectsEmpty() public view {
        RegistryFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 0);
    }

    function test_GetAllProjectsSingle() public {
        vm.prank(developer1);
        factory.proposeProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, PROJECT_METADATA);

        RegistryFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 1);
        assertEq(projects[0].name, PROJECT_NAME);
    }

    function test_GetAllProjectsMultiple() public {
        vm.prank(developer1);
        factory.proposeProject("Project 1", "PRJ1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        factory.proposeProject("Project 2", "PRJ2", 2000 * 10**18, "meta2");

        vm.prank(developer1);
        factory.proposeProject("Project 3", "PRJ3", 3000 * 10**18, "meta3");

        RegistryFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 3);
        assertEq(projects[0].name, "Project 1");
        assertEq(projects[1].name, "Project 2");
        assertEq(projects[2].name, "Project 3");
    }

    function test_GetProjectsByStatusPending() public {
        vm.prank(developer1);
        factory.proposeProject("Pending 1", "P1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        uint256 projectId2 = factory.proposeProject("Pending 2", "P2", 2000 * 10**18, "meta2");

        factory.approveProject(projectId2); // Approve one

        RegistryFactory.Project[] memory pending = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Pending
        );

        assertEq(pending.length, 1);
        assertEq(pending[0].name, "Pending 1");
    }

    function test_GetProjectsByStatusApproved() public {
        vm.prank(developer1);
        uint256 projectId1 = factory.proposeProject("Project 1", "P1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        uint256 projectId2 = factory.proposeProject("Project 2", "P2", 2000 * 10**18, "meta2");

        vm.prank(developer1);
        factory.proposeProject("Project 3", "P3", 3000 * 10**18, "meta3");

        factory.approveProject(projectId1);
        factory.approveProject(projectId2);

        RegistryFactory.Project[] memory approved = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Approved
        );

        assertEq(approved.length, 2);
        assertEq(approved[0].name, "Project 1");
        assertEq(approved[1].name, "Project 2");
    }

    function test_GetProjectsByStatusDenied() public {
        vm.prank(developer1);
        uint256 projectId1 = factory.proposeProject("Project 1", "P1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        factory.proposeProject("Project 2", "P2", 2000 * 10**18, "meta2");

        factory.denyProject(projectId1);

        RegistryFactory.Project[] memory denied = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Denied
        );

        assertEq(denied.length, 1);
        assertEq(denied[0].name, "Project 1");
    }

    function test_GetProjectsByStatusEmpty() public view {
        RegistryFactory.Project[] memory approved = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Approved
        );
        assertEq(approved.length, 0);
    }

    function test_GetVaultForToken() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);
        address tokenAddress = factory.getTokenForProject(projectId);

        // Before vault deployment
        assertEq(factory.getVaultForToken(tokenAddress), address(0));

        // After vault deployment
        address vaultAddress = factory.deployVault(projectId, mockStablecoin);
        assertEq(factory.getVaultForToken(tokenAddress), vaultAddress);
    }

    function test_RevertGetVaultForZeroAddress() public {
        vm.expectRevert("Token address cannot be zero");
        factory.getVaultForToken(address(0));
    }

    function test_RevertGetVaultForNonExistentToken() public {
        vm.expectRevert("Token not found in registry");
        factory.getVaultForToken(address(0x999));
    }

    function test_GetTokenForProject() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        assertEq(factory.getTokenForProject(projectId), address(0));

        factory.approveProject(projectId);

        address tokenAddress = factory.getTokenForProject(projectId);
        assertTrue(tokenAddress != address(0));
    }

    function test_RevertGetTokenForNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.getTokenForProject(999);
    }

    function test_GetProjectIdForToken() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);
        address tokenAddress = factory.getTokenForProject(projectId);

        assertEq(factory.getProjectIdForToken(tokenAddress), projectId);
    }

    function test_RevertGetProjectIdForZeroAddress() public {
        vm.expectRevert("Token address cannot be zero");
        factory.getProjectIdForToken(address(0));
    }

    function test_RevertGetProjectIdForNonExistentToken() public {
        vm.expectRevert("Token not found in registry");
        factory.getProjectIdForToken(address(0x999));
    }

    function test_GetProjectCount() public {
        assertEq(factory.getProjectCount(), 0);

        vm.prank(developer1);
        factory.proposeProject("P1", "P1", 1000 * 10**18, "m1");

        assertEq(factory.getProjectCount(), 1);

        vm.prank(developer2);
        factory.proposeProject("P2", "P2", 2000 * 10**18, "m2");

        assertEq(factory.getProjectCount(), 2);
    }

    function test_ProjectIdExists() public {
        assertFalse(factory.projectIdExists(0));

        vm.prank(developer1);
        factory.proposeProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, PROJECT_METADATA);

        assertTrue(factory.projectIdExists(0));
        assertFalse(factory.projectIdExists(1));
    }

    function test_GetNextProjectId() public {
        assertEq(factory.getNextProjectId(), 0);

        vm.prank(developer1);
        factory.proposeProject("P1", "P1", 1000 * 10**18, "m1");

        assertEq(factory.getNextProjectId(), 1);

        vm.prank(developer2);
        factory.proposeProject("P2", "P2", 2000 * 10**18, "m2");

        assertEq(factory.getNextProjectId(), 2);
    }

    // ========== Upgrade Tests ==========

    function test_UpgradeToNewImplementation() public {
        // Create some projects first
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        factory.approveProject(projectId);

        // Record state before upgrade
        uint256 projectCountBefore = factory.getProjectCount();
        address ownerBefore = factory.owner();
        RegistryFactory.Project memory projectBefore = factory.getProject(projectId);

        // Deploy new implementation
        RegistryFactory newImplementation = new RegistryFactory();

        // Upgrade
        factory.upgradeToAndCall(address(newImplementation), "");

        // Verify state preserved after upgrade
        assertEq(factory.owner(), ownerBefore);
        assertEq(factory.getProjectCount(), projectCountBefore);

        RegistryFactory.Project memory projectAfter = factory.getProject(projectId);
        assertEq(projectAfter.projectId, projectBefore.projectId);
        assertEq(projectAfter.name, projectBefore.name);
        assertEq(projectAfter.tokenAddress, projectBefore.tokenAddress);
        assertEq(uint(projectAfter.status), uint(projectBefore.status));

        // Verify factory still works
        vm.prank(developer2);
        uint256 newProjectId = factory.proposeProject("New Project", "NEW", 5000 * 10**18, "new");
        assertEq(newProjectId, 1);
    }

    function test_RevertUpgradeNotOwner() public {
        RegistryFactory newImplementation = new RegistryFactory();

        vm.prank(user1);
        vm.expectRevert();
        factory.upgradeToAndCall(address(newImplementation), "");
    }

    function test_UpgradePreservesComplexState() public {
        // Create multiple projects with different states
        vm.prank(developer1);
        uint256 projectId1 = factory.proposeProject("Project 1", "P1", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        uint256 projectId2 = factory.proposeProject("Project 2", "P2", 2000 * 10**18, "meta2");

        vm.prank(developer1);
        uint256 projectId3 = factory.proposeProject("Project 3", "P3", 3000 * 10**18, "meta3");

        // Approve one
        factory.approveProject(projectId1);
        address token1 = factory.getTokenForProject(projectId1);

        // Deny one
        factory.denyProject(projectId3);

        // Deploy vault for approved project
        factory.deployVault(projectId1, mockStablecoin);
        address vault1 = factory.getVaultForToken(token1);

        // Perform upgrade
        RegistryFactory newImpl = new RegistryFactory();
        factory.upgradeToAndCall(address(newImpl), "");

        // Verify all state preserved
        assertEq(factory.getProjectCount(), 3);

        RegistryFactory.Project memory p1 = factory.getProject(projectId1);
        assertEq(uint(p1.status), uint(RegistryFactory.ProjectStatus.Approved));
        assertEq(p1.tokenAddress, token1);
        assertEq(p1.vaultAddress, vault1);

        RegistryFactory.Project memory p2 = factory.getProject(projectId2);
        assertEq(uint(p2.status), uint(RegistryFactory.ProjectStatus.Pending));

        RegistryFactory.Project memory p3 = factory.getProject(projectId3);
        assertEq(uint(p3.status), uint(RegistryFactory.ProjectStatus.Denied));

        // Verify functionality still works
        factory.approveProject(projectId2);
        assertEq(uint(factory.getProject(projectId2).status), uint(RegistryFactory.ProjectStatus.Approved));
    }

    // ========== Integration Tests ==========

    function test_CompleteProjectLifecycle() public {
        // 1. Developer proposes project
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Pending));

        // 2. Owner approves project
        factory.approveProject(projectId);

        project = factory.getProject(projectId);
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Approved));
        assertTrue(project.tokenAddress != address(0));

        // 3. Token is tradeable
        FutureCarbonToken token = FutureCarbonToken(project.tokenAddress);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);

        // Simulate trading by transferring to users
        token.transfer(user1, 100_000 * 10**18);
        assertEq(token.balanceOf(user1), 100_000 * 10**18);

        // 4. Project completes, owner deploys vault
        address vaultAddress = factory.deployVault(projectId, mockStablecoin);

        project = factory.getProject(projectId);
        assertEq(project.vaultAddress, vaultAddress);

        // 5. Verify all relationships
        assertEq(factory.getProjectIdForToken(project.tokenAddress), projectId);
        assertEq(factory.getTokenForProject(projectId), project.tokenAddress);
        assertEq(factory.getVaultForToken(project.tokenAddress), vaultAddress);
    }

    function test_MultipleProjectsLifecycle() public {
        // Developer 1 proposes two projects
        vm.startPrank(developer1);
        uint256 project1 = factory.proposeProject("Project Alpha", "PA", 1_000_000 * 10**18, "alpha");
        uint256 project2 = factory.proposeProject("Project Beta", "PB", 2_000_000 * 10**18, "beta");
        vm.stopPrank();

        // Developer 2 proposes one project
        vm.prank(developer2);
        uint256 project3 = factory.proposeProject("Project Gamma", "PG", 3_000_000 * 10**18, "gamma");

        // Owner approves two, denies one
        factory.approveProject(project1);
        factory.approveProject(project3);
        factory.denyProject(project2);

        // Verify status filtering
        RegistryFactory.Project[] memory approved = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Approved
        );
        RegistryFactory.Project[] memory denied = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Denied
        );

        assertEq(approved.length, 2);
        assertEq(denied.length, 1);

        // Deploy vaults for approved projects
        factory.deployVault(project1, mockStablecoin);
        factory.deployVault(project3, mockStablecoin);

        // Verify all projects maintain correct state
        RegistryFactory.Project memory p1 = factory.getProject(project1);
        RegistryFactory.Project memory p2 = factory.getProject(project2);
        RegistryFactory.Project memory p3 = factory.getProject(project3);

        assertTrue(p1.vaultAddress != address(0));
        assertEq(p2.vaultAddress, address(0));
        assertTrue(p3.vaultAddress != address(0));
    }

    function test_ProjectWithSameNameAndSymbol() public {
        // Two projects can have same name/symbol (different tokens)
        vm.prank(developer1);
        uint256 project1 = factory.proposeProject("Same Name", "SAME", 1000 * 10**18, "meta1");

        vm.prank(developer2);
        uint256 project2 = factory.proposeProject("Same Name", "SAME", 2000 * 10**18, "meta2");

        factory.approveProject(project1);
        factory.approveProject(project2);

        address token1 = factory.getTokenForProject(project1);
        address token2 = factory.getTokenForProject(project2);

        assertTrue(token1 != token2);
        assertEq(FutureCarbonToken(token1).name(), "Same Name");
        assertEq(FutureCarbonToken(token2).name(), "Same Name");
    }

    function test_CannotApproveAfterOwnershipTransfer() public {
        vm.prank(developer1);
        uint256 projectId = factory.proposeProject(
            PROJECT_NAME,
            PROJECT_SYMBOL,
            INITIAL_SUPPLY,
            PROJECT_METADATA
        );

        // Transfer ownership to new owner
        address newOwner = address(0x999);
        factory.transferOwnership(newOwner);

        // Old owner cannot approve
        vm.expectRevert();
        factory.approveProject(projectId);

        // New owner can approve
        vm.prank(newOwner);
        factory.approveProject(projectId);

        RegistryFactory.Project memory project = factory.getProject(projectId);
        assertEq(uint(project.status), uint(RegistryFactory.ProjectStatus.Approved));
    }

    function test_LargeNumberOfProjects() public {
        // Test with 20 projects
        for (uint256 i = 0; i < 20; i++) {
            vm.prank(developer1);
            factory.proposeProject(
                string(abi.encodePacked("Project ", vm.toString(i))),
                string(abi.encodePacked("P", vm.toString(i))),
                (i + 1) * 1000 * 10**18,
                string(abi.encodePacked("meta", vm.toString(i)))
            );
        }

        assertEq(factory.getProjectCount(), 20);

        // Approve half
        for (uint256 i = 0; i < 10; i++) {
            factory.approveProject(i);
        }

        // Deny quarter
        for (uint256 i = 10; i < 15; i++) {
            factory.denyProject(i);
        }

        RegistryFactory.Project[] memory allProjects = factory.getAllProjects();
        assertEq(allProjects.length, 20);

        RegistryFactory.Project[] memory approved = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Approved
        );
        assertEq(approved.length, 10);

        RegistryFactory.Project[] memory denied = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Denied
        );
        assertEq(denied.length, 5);

        RegistryFactory.Project[] memory pending = factory.getProjectsByStatus(
            RegistryFactory.ProjectStatus.Pending
        );
        assertEq(pending.length, 5);
    }
}
