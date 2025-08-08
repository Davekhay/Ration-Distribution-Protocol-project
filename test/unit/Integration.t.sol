// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {RationDistribution} from "src/RationDistribution.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract IntegrationTest is Test {
    RationDistribution public ration;
    HelperConfig public helper;
    address public dealer = address(2);
    address public beneficiary = address(3);

    function setUp() public {
        helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getActiveConfig();

        ration = new RationDistribution(config.admin, config.cycleDuration, config.priceFeed);

        vm.startPrank(config.admin);
        ration.addDealer(dealer);
        vm.stopPrank();
    }

    function testEndToEndWorkflow() public {
        vm.startPrank(dealer);
        ration.registerBeneficiary(beneficiary);

        // Warp to after cycle duration
        vm.warp(block.timestamp + ration.cycleDuration() + 1);

        ration.claimRationFor(beneficiary);

        (, uint256 lastClaimed) = ration.beneficiaries(beneficiary);
        assertEq(lastClaimed, block.timestamp);
        vm.stopPrank();
    }
}
