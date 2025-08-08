// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

/// @title HelperConfig for RationDistribution
/// @notice Provides network-specific configuration for deployment
contract HelperConfig is Script {
    // ======== STRUCT ========
    struct NetworkConfig {
        address priceFeed;
        uint256 cycleDuration;
        address admin;
    }

    // ======== STATE VAR ========
    NetworkConfig public activeNetworkConfig;

    // Mainnet / Sepolia constants
    address private constant MAINNET_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address private constant SEPOLIA_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getMainnetConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: MAINNET_FEED,
            cycleDuration: 30 days,
            admin: address(0) 
        });
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: SEPOLIA_FEED,
            cycleDuration: 1 days,
            admin:0x8Cd5A30a985d3c3F6312Ba81F42fBC8FB3D3355D
        });
    }

    function getAnvilConfig() internal returns (NetworkConfig memory) {
        // Deploy a local mock price feed
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(8, int256(2000 * 10 ** 8)); // $2000
        vm.stopBroadcast();

        return NetworkConfig({priceFeed: address(mock), cycleDuration: 1 days, admin: msg.sender});
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getActiveConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
