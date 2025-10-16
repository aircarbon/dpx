// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ACT} from "../src/ACT.sol";
import {ACTGovernor} from "../src/ACTGovernor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge test --match-contract ACTGovernorTest -vv
contract ACTGovernorTest is Test {
    ACT public token;
    ACTGovernor public governor;

    address public deployer;
    address public voter1;
    address public voter2;
    address public voter3;

    uint256 public constant INITIAL_SUPPLY = 10_000_000 * 10**18;
    uint48 public constant VOTING_DELAY = 1;
    uint32 public constant VOTING_PERIOD = 50;
    uint256 public constant PROPOSAL_THRESHOLD = 0;
    uint256 public constant QUORUM_PERCENTAGE = 4;

    function setUp() public {
        deployer = address(this);
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");

        // Deploy implementation contract
        ACT implementation = new ACT();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            ACT.initialize.selector,
            "ACT Token",
            "ACT",
            INITIAL_SUPPLY
        );

        // Deploy proxy and initialize
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Wrap proxy in ACT interface
        token = ACT(address(proxy));

        governor = new ACTGovernor(
            token,
            VOTING_DELAY,
            VOTING_PERIOD,
            PROPOSAL_THRESHOLD,
            QUORUM_PERCENTAGE
        );

        token.transfer(voter1, 1_000_000 * 10**18);
        token.transfer(voter2, 500_000 * 10**18);
        token.transfer(voter3, 100_000 * 10**18);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.prank(voter3);
        token.delegate(voter3);

        vm.roll(block.number + 1);
    }

    function test_GovernorDeployment() public view {
        assertEq(governor.name(), "ACT Governor");
        assertEq(address(governor.token()), address(token));
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), PROPOSAL_THRESHOLD);
    }

    function test_QuorumCalculation() public view {
        uint256 expectedQuorum = (INITIAL_SUPPLY * QUORUM_PERCENTAGE) / 100;
        assertEq(governor.quorum(block.number - 1), expectedQuorum);
    }

    function test_CreateProposal() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertTrue(proposalId != 0);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));
    }

    function test_VoteOnProposal() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        assertEq(forVotes, 1_000_000 * 10**18);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function test_ProposalSucceeds() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_ProposalDefeated() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 0);

        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_QuorumNotReached() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter3);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD + 1);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_GetVotes() public view {
        uint256 voter1Votes = token.getVotes(voter1);
        uint256 voter2Votes = token.getVotes(voter2);
        uint256 voter3Votes = token.getVotes(voter3);

        assertEq(voter1Votes, 1_000_000 * 10**18);
        assertEq(voter2Votes, 500_000 * 10**18);
        assertEq(voter3Votes, 100_000 * 10**18);
    }

    function test_CannotVoteTwice() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter1);
        vm.expectRevert();
        governor.castVote(proposalId, 1);
    }

    function test_CannotVoteBeforeActive() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Proposal #1: Test proposal";

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = "";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.prank(voter1);
        vm.expectRevert();
        governor.castVote(proposalId, 1);
    }
}
