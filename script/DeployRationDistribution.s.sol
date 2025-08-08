// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RationDistribution} from "../src/RationDistribution.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRationDistribution is Script {
    function run() external returns (RationDistribution) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getActiveNetworkConfig();

        // Load admin from environment variable securely
        address admin = vm.envAddress("ADMIN_ADDRESS");

        // Override admin from HelperConfig with env admin
        config.admin = admin;

        vm.startBroadcast();
        RationDistribution ration = new RationDistribution(config.admin, config.cycleDuration, config.priceFeed);
        vm.stopBroadcast();

        return ration;
    }
}
