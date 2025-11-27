// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {FctFactory} from "../src/FctFactory.sol";
import {FutureCarbonToken} from "../src/FutureCarbonToken.sol";
import {RedemptionVault} from "../src/RedemptionVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FctFactoryTest
 * @dev Comprehensive test suite for FctFactory contract
 * Tests initialization, project creation, deployments, queries, and UUPS upgrades
 */
contract FctFactoryTest is Test {
    FctFactory public factory;
    FctFactory public implementation;
    ERC1967Proxy public proxy;

    address public owner;
    address public user1;
    address public user2;
    address public mockStablecoin;

    // Test project parameters
    string constant PROJECT_NAME = "Future Carbon Credit - Project Alpha";
    string constant PROJECT_SYMBOL = "FCC-ALPHA";
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 constant VINTAGE_YEAR = 2025;
    string constant REGISTRY_CODE = "VCS-1234-2025";

    // Events to test
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed tokenAddress,
        string name,
        string symbol,
        uint256 initialSupply,
        uint256 vintageYear,
        string projectRegistryCode
    );

    event VaultDeployed(
        uint256 indexed projectId, address indexed tokenAddress, address indexed vaultAddress, address stablecoin
    );

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        mockStablecoin = address(0x3);

        // Deploy implementation
        implementation = new FctFactory();

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(FctFactory.initialize.selector, owner);

        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Wrap proxy with interface
        factory = FctFactory(address(proxy));
    }

    // Helper function to create empty metadata
    function emptyMetadata() internal pure returns (FutureCarbonToken.MetadataEntry[] memory) {
        return new FutureCarbonToken.MetadataEntry[](0);
    }

    // Helper function to create single metadata entry
    function singleMetadata(string memory key, string memory value)
        internal
        pure
        returns (FutureCarbonToken.MetadataEntry[] memory)
    {
        FutureCarbonToken.MetadataEntry[] memory metadata = new FutureCarbonToken.MetadataEntry[](1);
        metadata[0] = FutureCarbonToken.MetadataEntry({key: key, value: value});
        return metadata;
    }

    // Helper function to create multiple metadata entries
    function multipleMetadata() internal pure returns (FutureCarbonToken.MetadataEntry[] memory) {
        FutureCarbonToken.MetadataEntry[] memory metadata = new FutureCarbonToken.MetadataEntry[](3);
        metadata[0] = FutureCarbonToken.MetadataEntry({key: "location", value: "Brazil"});
        metadata[1] = FutureCarbonToken.MetadataEntry({key: "methodology", value: "VM0042"});
        metadata[2] = FutureCarbonToken.MetadataEntry({key: "developer", value: "GreenCorp Inc."});
        return metadata;
    }

    // ========== Initialization Tests ==========

    function test_Initialization() public view {
        assertEq(factory.owner(), owner);
        assertEq(factory.getProjectCount(), 0);
        assertEq(factory.getNextProjectId(), 1);
    }

    function test_CannotInitializeTwice() public {
        vm.expectRevert();
        factory.initialize(owner);
    }

    function test_CannotInitializeImplementation() public {
        FctFactory newImpl = new FctFactory();
        vm.expectRevert();
        newImpl.initialize(owner);
    }

    function test_RevertInitializeWithZeroAddress() public {
        FctFactory newImpl = new FctFactory();

        bytes memory initData = abi.encodeWithSelector(FctFactory.initialize.selector, address(0));

        vm.expectRevert("Owner cannot be zero address");
        new ERC1967Proxy(address(newImpl), initData);
    }

    // ========== createProject Tests ==========

    function test_CreateProject() public {
        vm.expectEmit(false, false, false, false);
        emit ProjectCreated(1, address(0), PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE);

        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        assertEq(projectId, 1);
        assertEq(factory.getProjectCount(), 1);
        assertEq(factory.getNextProjectId(), 2);
        assertTrue(tokenAddress != address(0));

        FctFactory.Project memory project = factory.getProject(1);
        assertEq(project.projectId, 1);
        assertEq(project.name, PROJECT_NAME);
        assertEq(project.symbol, PROJECT_SYMBOL);
        assertEq(project.initialSupply, INITIAL_SUPPLY);
        assertEq(project.tokenAddress, tokenAddress);
        assertEq(project.vaultAddress, address(0));
        assertEq(project.createdAt, block.timestamp);
        assertEq(project.vintageYear, VINTAGE_YEAR);
        assertEq(project.projectRegistryCode, REGISTRY_CODE);

        // Verify token was deployed correctly
        FutureCarbonToken token = FutureCarbonToken(tokenAddress);
        assertEq(token.name(), PROJECT_NAME);
        assertEq(token.symbol(), PROJECT_SYMBOL);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);
        assertEq(token.vintageYear(), VINTAGE_YEAR);
        assertEq(token.getProjectRegistryCode(), REGISTRY_CODE);

        FutureCarbonToken.MetadataEntry[] memory tokenMetadata = token.getMetadataEntries();
        assertEq(tokenMetadata.length, 0);

        // Verify reverse lookup
        assertEq(factory.getProjectIdForToken(tokenAddress), projectId);
        assertEq(factory.getTokenForProject(projectId), tokenAddress);
    }

    function test_CreateProjectWithMetadata() public {
        FutureCarbonToken.MetadataEntry[] memory metadata = multipleMetadata();

        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, metadata
        );

        FutureCarbonToken token = FutureCarbonToken(tokenAddress);

        FutureCarbonToken.MetadataEntry[] memory allMetadata = token.getMetadataEntries();
        assertEq(allMetadata.length, 3);
        assertEq(allMetadata[0].key, "location");
        assertEq(allMetadata[0].value, "Brazil");
        assertEq(allMetadata[1].key, "methodology");
        assertEq(allMetadata[2].value, "GreenCorp Inc.");
    }

    function test_CreateMultipleProjects() public {
        // First project
        (uint256 projectId1, address tokenAddress1) = factory.createProject(
            "Project 1", "PRJ1", 1000 * 10 ** 18, 2024, "VCS-1000", emptyMetadata()
        );

        // Second project
        (uint256 projectId2, address tokenAddress2) = factory.createProject(
            "Project 2", "PRJ2", 2000 * 10 ** 18, 2025, "GS-2000", singleMetadata("type", "forestry")
        );

        // Third project
        (uint256 projectId3, address tokenAddress3) = factory.createProject(
            "Project 3", "PRJ3", 3000 * 10 ** 18, 2026, "ACR-3000", emptyMetadata()
        );

        assertEq(projectId1, 1);
        assertEq(projectId2, 2);
        assertEq(projectId3, 3);
        assertEq(factory.getProjectCount(), 3);
        assertTrue(tokenAddress1 != tokenAddress2);
        assertTrue(tokenAddress2 != tokenAddress3);

        FctFactory.Project memory project2 = factory.getProject(2);
        assertEq(project2.name, "Project 2");
        assertEq(project2.vintageYear, 2025);
        assertEq(project2.projectRegistryCode, "GS-2000");
    }

    function test_RevertCreateProjectNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );
    }

    function test_RevertCreateProjectEmptyName() public {
        vm.expectRevert("Name cannot be empty");
        factory.createProject("", PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata());
    }

    function test_RevertCreateProjectEmptySymbol() public {
        vm.expectRevert("Symbol cannot be empty");
        factory.createProject(PROJECT_NAME, "", INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata());
    }

    function test_RevertCreateProjectZeroSupply() public {
        vm.expectRevert("Initial supply must be greater than 0");
        factory.createProject(PROJECT_NAME, PROJECT_SYMBOL, 0, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata());
    }

    function test_RevertCreateProjectZeroVintageYear() public {
        vm.expectRevert("Vintage year must be greater than 0");
        factory.createProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, 0, REGISTRY_CODE, emptyMetadata());
    }

    function test_RevertCreateProjectEmptyRegistryCode() public {
        vm.expectRevert("Project registry code cannot be empty");
        factory.createProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, "", emptyMetadata());
    }

    // ========== deployVault Tests ==========

    function test_DeployVault() public {
        // Create project
        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        // Deploy vault
        address vaultAddress = factory.deployVault(projectId, mockStablecoin);

        FctFactory.Project memory projectAfter = factory.getProject(projectId);
        assertEq(projectAfter.vaultAddress, vaultAddress);
        assertTrue(vaultAddress != address(0));

        // Verify vault was deployed correctly
        RedemptionVault vault = RedemptionVault(vaultAddress);
        assertEq(address(vault.futureToken()), tokenAddress);
        assertEq(address(vault.stablecoin()), mockStablecoin);
        assertEq(vault.owner(), owner);
        assertFalse(vault.redemptionActive());

        // Verify getVaultForToken works
        assertEq(factory.getVaultForToken(tokenAddress), vaultAddress);
    }

    function test_RevertDeployVaultNotOwner() public {
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        vm.prank(user1);
        vm.expectRevert();
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.deployVault(999, mockStablecoin);
    }

    function test_RevertDeployVaultAlreadyDeployed() public {
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        factory.deployVault(projectId, mockStablecoin);

        vm.expectRevert("Vault already deployed");
        factory.deployVault(projectId, mockStablecoin);
    }

    function test_RevertDeployVaultZeroAddressStablecoin() public {
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        vm.expectRevert("Stablecoin cannot be zero address");
        factory.deployVault(projectId, address(0));
    }

    // ========== Query Function Tests ==========

    function test_GetProject() public {
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        FctFactory.Project memory project = factory.getProject(projectId);
        assertEq(project.projectId, projectId);
        assertEq(project.name, PROJECT_NAME);
        assertEq(project.vintageYear, VINTAGE_YEAR);
    }

    function test_RevertGetNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.getProject(999);
    }

    function test_GetAllProjectsEmpty() public view {
        FctFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 0);
    }

    function test_GetAllProjectsSingle() public {
        factory.createProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata());

        FctFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 1);
        assertEq(projects[0].name, PROJECT_NAME);
    }

    function test_GetAllProjectsMultiple() public {
        factory.createProject("Project 1", "PRJ1", 1000 * 10 ** 18, 2024, "VCS-1", emptyMetadata());
        factory.createProject("Project 2", "PRJ2", 2000 * 10 ** 18, 2025, "VCS-2", emptyMetadata());
        factory.createProject("Project 3", "PRJ3", 3000 * 10 ** 18, 2026, "VCS-3", emptyMetadata());

        FctFactory.Project[] memory projects = factory.getAllProjects();
        assertEq(projects.length, 3);
        assertEq(projects[0].name, "Project 1");
        assertEq(projects[1].name, "Project 2");
        assertEq(projects[2].name, "Project 3");
    }

    function test_GetVaultForToken() public {
        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

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
        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        address retrievedToken = factory.getTokenForProject(projectId);
        assertEq(retrievedToken, tokenAddress);
        assertTrue(retrievedToken != address(0));
    }

    function test_RevertGetTokenForNonExistentProject() public {
        vm.expectRevert("Project does not exist");
        factory.getTokenForProject(999);
    }

    function test_GetProjectIdForToken() public {
        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

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

        factory.createProject("P1", "P1", 1000 * 10 ** 18, 2024, "V1", emptyMetadata());
        assertEq(factory.getProjectCount(), 1);

        factory.createProject("P2", "P2", 2000 * 10 ** 18, 2025, "V2", emptyMetadata());
        assertEq(factory.getProjectCount(), 2);
    }

    function test_ProjectIdExists() public {
        assertFalse(factory.projectIdExists(0));
        assertFalse(factory.projectIdExists(1));

        factory.createProject(PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata());

        assertFalse(factory.projectIdExists(0)); // 0 is never used
        assertTrue(factory.projectIdExists(1));
        assertFalse(factory.projectIdExists(2));
    }

    function test_GetNextProjectId() public {
        assertEq(factory.getNextProjectId(), 1);

        factory.createProject("P1", "P1", 1000 * 10 ** 18, 2024, "V1", emptyMetadata());
        assertEq(factory.getNextProjectId(), 2);

        factory.createProject("P2", "P2", 2000 * 10 ** 18, 2025, "V2", emptyMetadata());
        assertEq(factory.getNextProjectId(), 3);
    }

    // ========== Upgrade Tests ==========

    function test_UpgradeToNewImplementation() public {
        // Create a project first
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        // Record state before upgrade
        uint256 projectCountBefore = factory.getProjectCount();
        address ownerBefore = factory.owner();
        FctFactory.Project memory projectBefore = factory.getProject(projectId);

        // Deploy new implementation
        FctFactory newImplementation = new FctFactory();

        // Upgrade
        factory.upgradeToAndCall(address(newImplementation), "");

        // Verify state preserved after upgrade
        assertEq(factory.owner(), ownerBefore);
        assertEq(factory.getProjectCount(), projectCountBefore);

        FctFactory.Project memory projectAfter = factory.getProject(projectId);
        assertEq(projectAfter.projectId, projectBefore.projectId);
        assertEq(projectAfter.name, projectBefore.name);
        assertEq(projectAfter.tokenAddress, projectBefore.tokenAddress);
        assertEq(projectAfter.vintageYear, projectBefore.vintageYear);

        // Verify factory still works
        (uint256 newProjectId,) = factory.createProject("New Project", "NEW", 5000 * 10 ** 18, 2027, "NEW-1", emptyMetadata());
        assertEq(newProjectId, 2);
    }

    function test_RevertUpgradeNotOwner() public {
        FctFactory newImplementation = new FctFactory();

        vm.prank(user1);
        vm.expectRevert();
        factory.upgradeToAndCall(address(newImplementation), "");
    }

    // ========== Integration Tests ==========

    function test_CompleteProjectLifecycle() public {
        // 1. Owner creates project
        (uint256 projectId, address tokenAddress) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, multipleMetadata()
        );

        FctFactory.Project memory project = factory.getProject(projectId);
        assertTrue(project.tokenAddress != address(0));

        // 2. Token is tradeable
        FutureCarbonToken token = FutureCarbonToken(tokenAddress);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);

        // Simulate trading by transferring to users
        token.transfer(user1, 100_000 * 10 ** 18);
        assertEq(token.balanceOf(user1), 100_000 * 10 ** 18);

        // 3. Project completes, owner deploys vault
        address vaultAddress = factory.deployVault(projectId, mockStablecoin);

        project = factory.getProject(projectId);
        assertEq(project.vaultAddress, vaultAddress);

        // 4. Verify all relationships
        assertEq(factory.getProjectIdForToken(tokenAddress), projectId);
        assertEq(factory.getTokenForProject(projectId), tokenAddress);
        assertEq(factory.getVaultForToken(tokenAddress), vaultAddress);

        // 5. Verify token metadata is accessible
        assertEq(token.vintageYear(), VINTAGE_YEAR);
        assertEq(token.getProjectRegistryCode(), REGISTRY_CODE);

        FutureCarbonToken.MetadataEntry[] memory tokenMetadata = token.getMetadataEntries();
        assertEq(tokenMetadata.length, 3);
    }

    function test_MultipleProjectsLifecycle() public {
        // Create three projects
        (uint256 project1, address token1) =
            factory.createProject("Project Alpha", "PA", 1_000_000 * 10 ** 18, 2024, "VCS-100", emptyMetadata());
        (uint256 project2, address token2) =
            factory.createProject("Project Beta", "PB", 2_000_000 * 10 ** 18, 2025, "GS-200", emptyMetadata());
        (uint256 project3, address token3) =
            factory.createProject("Project Gamma", "PG", 3_000_000 * 10 ** 18, 2026, "ACR-300", emptyMetadata());

        // Deploy vaults for all projects
        factory.deployVault(project1, mockStablecoin);
        factory.deployVault(project2, mockStablecoin);
        factory.deployVault(project3, mockStablecoin);

        // Verify all projects maintain correct state
        FctFactory.Project memory p1 = factory.getProject(project1);
        FctFactory.Project memory p2 = factory.getProject(project2);
        FctFactory.Project memory p3 = factory.getProject(project3);

        assertTrue(p1.vaultAddress != address(0));
        assertTrue(p2.vaultAddress != address(0));
        assertTrue(p3.vaultAddress != address(0));

        assertTrue(p1.vaultAddress != p2.vaultAddress);
        assertTrue(p2.vaultAddress != p3.vaultAddress);
    }

    function test_ProjectWithSameNameAndSymbol() public {
        // Two projects can have same name/symbol (different tokens)
        (uint256 project1, address token1) =
            factory.createProject("Same Name", "SAME", 1000 * 10 ** 18, 2024, "VCS-1", emptyMetadata());
        (uint256 project2, address token2) =
            factory.createProject("Same Name", "SAME", 2000 * 10 ** 18, 2025, "VCS-2", emptyMetadata());

        assertTrue(token1 != token2);
        assertEq(FutureCarbonToken(token1).name(), "Same Name");
        assertEq(FutureCarbonToken(token2).name(), "Same Name");
    }

    function test_CannotCreateAfterOwnershipTransfer() public {
        // Transfer ownership to new owner
        address newOwner = address(0x999);
        factory.transferOwnership(newOwner);

        // Old owner cannot create
        vm.expectRevert();
        factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        // New owner can create
        vm.prank(newOwner);
        (uint256 projectId,) = factory.createProject(
            PROJECT_NAME, PROJECT_SYMBOL, INITIAL_SUPPLY, VINTAGE_YEAR, REGISTRY_CODE, emptyMetadata()
        );

        FctFactory.Project memory project = factory.getProject(projectId);
        assertTrue(project.tokenAddress != address(0));
    }

    function test_LargeNumberOfProjects() public {
        // Test with 20 projects
        for (uint256 i = 0; i < 20; i++) {
            factory.createProject(
                string(abi.encodePacked("Project ", vm.toString(i))),
                string(abi.encodePacked("P", vm.toString(i))),
                (i + 1) * 1000 * 10 ** 18,
                2024 + i,
                string(abi.encodePacked("VCS-", vm.toString(i))),
                emptyMetadata()
            );
        }

        assertEq(factory.getProjectCount(), 20);

        FctFactory.Project[] memory allProjects = factory.getAllProjects();
        assertEq(allProjects.length, 20);
    }
}
