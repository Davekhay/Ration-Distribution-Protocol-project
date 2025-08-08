// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/RationDistribution.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";
import {DeployRationDistribution} from "script/DeployRationDistribution.s.sol";

contract RationDistributionTest is Test {
    RationDistribution public ration;
    MockV3Aggregator public mockPriceFeed;

    address owner = address(1);
    address dealer = address(2);
    address user1 = address(3);
    address user2 = address(4);

    uint256 cycle = 1 days;
    int256 mockPrice = int256(2000 * 10 ** 8); // Mock ETH/USD price with 8 decimals

    function setUp() public {
        vm.startPrank(owner);
        mockPriceFeed = new MockV3Aggregator(8, mockPrice);
        ration = new RationDistribution(owner, cycle, address(mockPriceFeed));
        ration.addDealer(dealer);
        vm.stopPrank();
    }

    /* ========== CONSTRUCTOR & GETTERS ========== */
    function testConstructorParams() public view {
        assertEq(address(ration.priceFeed()), address(mockPriceFeed));
        assertEq(ration.cycleDuration(), cycle);
        assertEq(ration.owner(), owner);
    }

    function testConstructorRevertZeroAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(RD_ZeroAdmin.selector));
        new RationDistribution(address(0), cycle, address(mockPriceFeed));
    }

    function testConstructorRevertZeroFeed() public {
        vm.expectRevert(abi.encodeWithSelector(RD_ZeroFeed.selector));
        new RationDistribution(owner, cycle, address(0));
    }

    /* ========== DEALER MANAGEMENT ========== */
    function testOnlyOwnerCanAddDealer() public {
        vm.prank(owner);
        ration.addDealer(address(99));
        assertTrue(ration.isDealer(address(99)));

        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        ration.addDealer(address(100));
    }

    function testAddAndRemoveDealer() public {
        vm.startPrank(owner);
        ration.addDealer(address(10));
        assertTrue(ration.isDealer(address(10)));

        ration.removeDealer(address(10));
        assertFalse(ration.isDealer(address(10)));
        vm.stopPrank();
    }

    function testAddDealerRevertsZero() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(RD_ZeroDealer.selector));
        ration.addDealer(address(0));
    }

    function testRemoveDealerRevertsNotDealer() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(RD_NotDealerToRemove.selector));
        ration.removeDealer(address(12345));
    }

    /* ========== BENEFICIARY REGISTRATION ========== */
    function testOnlyDealerCanRegisterBeneficiary() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);
        Beneficiary memory b = ration.getBeneficiary(user1);
        assertTrue(b.registered);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(RD_NotDealer.selector));
        ration.registerBeneficiary(user2);
    }

    function testRegisterFailsForAlreadyRegistered() public {
        vm.startPrank(dealer);
        ration.registerBeneficiary(user1);
        vm.expectRevert(abi.encodeWithSelector(RD_AlreadyRegistered.selector));
        ration.registerBeneficiary(user1);
        vm.stopPrank();
    }

    function testRegisterRevertsZeroAddress() public {
        vm.prank(dealer);
        vm.expectRevert(abi.encodeWithSelector(RD_ZeroDealer.selector));
        ration.registerBeneficiary(address(0));
    }

    /* ========== SUBSIDY CALCULATION ========== */
    function testSubsidyAmountFromPriceFeed() public view {
        uint256 expected = (1e8 * 1 ether) / uint256(uint256(mockPrice));
        uint256 amount = ration.getSubsidyAmount();
        assertEq(amount, expected);
    }

    function testSubsidyRevertsIfInvalidPrice() public {
        mockPriceFeed.updateAnswer(0);
        vm.expectRevert(abi.encodeWithSelector(RD_InvalidPrice.selector));
        ration.getSubsidyAmount();
    }

    /* ========== CLAIM FLOW (TIMING) ========== */
    function testCannotClaimBeforeCycleEnds() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);

        vm.prank(dealer);
        vm.expectRevert(abi.encodeWithSelector(RD_ClaimNotReady.selector));
        ration.claimRationFor(user1);
    }

    function testClaimRationAfterCycleEnds() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);

        vm.warp(block.timestamp + cycle + 1);

        vm.prank(dealer);
        ration.claimRationFor(user1);

        Beneficiary memory b = ration.getBeneficiary(user1);
        assertEq(b.lastClaimed, block.timestamp);
    }

    function testEligibilityLogicWorks() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);
        assertFalse(ration.isBeneficiaryEligible(user1));

        vm.warp(block.timestamp + cycle + 1);
        assertTrue(ration.isBeneficiaryEligible(user1));
    }

    /* ========== PAUSE / UNPAUSE BEHAVIOR ========== */
    function testPausedPreventsClaim() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);

        vm.warp(block.timestamp + cycle + 1);

        vm.prank(owner);
        ration.pause();

        vm.prank(dealer);
        vm.expectRevert("Pausable: paused");
        ration.claimRationFor(user1);
    }

    function testUnpausedAllowsClaim() public {
        vm.prank(dealer);
        ration.registerBeneficiary(user1);

        vm.warp(block.timestamp + cycle + 1);

        vm.prank(owner);
        ration.pause();
        vm.prank(owner);
        ration.unpause();

        vm.prank(dealer);
        ration.claimRationFor(user1);

        Beneficiary memory b = ration.getBeneficiary(user1);
        assertEq(b.lastClaimed, block.timestamp);
    }

    /* ========== INTEGRATION-LIKE: Deploy script & full flow ========== */
   function testDeployScriptAndFullFlow() public {
    DeployRationDistribution deployer = new DeployRationDistribution();
    RationDistribution deployed = deployer.run();

    // Rename local variable to avoid shadowing
    address contractOwner = deployed.owner();

    vm.prank(contractOwner);
    deployed.addDealer(dealer);
    assertTrue(deployed.isDealer(dealer));

    vm.prank(dealer);
    deployed.registerBeneficiary(user2);

    Beneficiary memory beforeB = deployed.getBeneficiary(user2);
    assertTrue(beforeB.registered);
    assertEq(beforeB.lastClaimed, 0);

    vm.warp(block.timestamp + deployed.cycleDuration() + 1);

    vm.prank(dealer);
    deployed.claimRationFor(user2);

    Beneficiary memory afterB = deployed.getBeneficiary(user2);
    assertEq(afterB.lastClaimed, block.timestamp);

    vm.prank(contractOwner);
    deployed.pause();

    vm.warp(block.timestamp + deployed.cycleDuration() + 1);
    vm.prank(dealer);
    vm.expectRevert("Pausable: paused");
    deployed.claimRationFor(user2);

    vm.prank(contractOwner);
    deployed.unpause();

    vm.warp(block.timestamp + deployed.cycleDuration() + 1);
    vm.prank(dealer);
    deployed.claimRationFor(user2);
 }

}
