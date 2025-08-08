// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {RationDistribution} from "../src/RationDistribution.sol";

/**
 * @notice Interactions contract for RationDistribution.
 * - Contains functions for admin and dealer interactions.
 * - Uses Script for broadcasting transactions.
 */
contract Interactions is Script {
    // ===== ADMIN =====
    function addDealer(address contractAddr, address dealer) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).addDealer(dealer);
        vm.stopBroadcast();
    }

    function removeDealer(address contractAddr, address dealer) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).removeDealer(dealer);
        vm.stopBroadcast();
    }

    function pauseContract(address contractAddr) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).pause();
        vm.stopBroadcast();
    }

    function unpauseContract(address contractAddr) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).unpause();
        vm.stopBroadcast();
    }

    // ===== DEALER =====
    function registerBeneficiary(address contractAddr, address beneficiary) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).registerBeneficiary(beneficiary);
        vm.stopBroadcast();
    }

    function claimRationFor(address contractAddr, address beneficiary) public {
        vm.startBroadcast();
        RationDistribution(contractAddr).claimRationFor(beneficiary);
        vm.stopBroadcast();
    }

    // ===== VIEW HELPERS (non-broadcast) =====
    function checkEligibility(address contractAddr, address beneficiary) public view returns (bool) {
        return RationDistribution(contractAddr).isBeneficiaryEligible(beneficiary);
    }

    function getSubsidyAmount(address contractAddr) public view returns (uint256) {
        return RationDistribution(contractAddr).getSubsidyAmount();
    }
}
