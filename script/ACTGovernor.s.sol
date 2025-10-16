// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ACTGovernor} from "../src/ACTGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {console} from "forge-std/console.sol";

// forge script script/ACTGovernor.s.sol --rpc-url sepolia --broadcast
contract ACTGovernorScript is Script {
    function run() public {
        // string memory root = vm.projectRoot();
        // string memory path = string.concat(
        //     root,
        //     "/broadcast/ACT.s.sol/",
        //     vm.toString(block.chainid),
        //     "/run-latest.json"
        // );
        // string memory json = vm.readFile(path);
        // address actTokenAddress = abi.decode(
        //     vm.parseJson(json, ".transactions[0].contractAddress"),
        //     (address)
        // );

        address actTokenAddress = address(vm.envAddress("ACT_TOKEN_ADDRESS"));
        uint48 votingDelay = uint48(vm.envOr("DAO_VOTING_DELAY", uint256(7200)));
        uint32 votingPeriod = uint32(vm.envOr("DAO_VOTING_PERIOD", uint256(50400)));
        uint256 proposalThresholdWhole = vm.envOr("DAO_PROPOSAL_THRESHOLD", uint256(1000));
        uint256 proposalThreshold = proposalThresholdWhole * 10**18;
        uint256 quorumPercentage = vm.envOr("DAO_QUORUM_PERCENTAGE", uint256(4));

        uint256 deployerPrivateKey;

        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
            vm.startBroadcast(deployerPrivateKey);
        } catch {
            // If no private key, broadcast will use mnemonic from CLI args
            vm.startBroadcast();
        }

        ACTGovernor governor = new ACTGovernor(
            IVotes(actTokenAddress),
            votingDelay,
            votingPeriod,
            proposalThreshold,
            quorumPercentage
        );

        vm.stopBroadcast();

        console.log("=== ACT Governor Deployment ===");
        console.log("Governor deployed at:", address(governor));
        console.log("Governor name:", governor.name());
        console.log("ACT Token address:", actTokenAddress);
        console.log("---");
        console.log("Governance Parameters:");
        console.log("- Voting Delay:", votingDelay, "blocks");
        console.log("- Voting Period:", votingPeriod, "blocks");
        console.log("- Proposal Threshold:", proposalThreshold, "wei");
        console.log("- Quorum Percentage:", quorumPercentage, "%");
        console.log("================================");
    }
}
