// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { CompromisedMigrator } from "./mocks/Mocks.sol";

import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";
import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";
import { MockERC20 } from "../../modules/mpl-migration/modules/erc20/contracts/test/mocks/MockERC20.sol";
import { Staker }    from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";

import { Staker } from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";

import { ExitTest, RevenueStreamingTest, RDT as RevenueDistributionToken } from "../../modules/revenue-distribution-token/contracts/test/RevenueDistributionToken.t.sol";

import { xMPL } from "../xMPL.sol";

import { xMPLOwner } from "./accounts/Owner.sol";

contract xMPLTest is TestUtils {

    uint256 constant DEPOSITED  = 1e18;
    uint256 constant OLD_SUPPLY = 10_000_000e18;
    uint256 constant START      = 52 weeks;

    uint256 constant sampleAssetsToConvert = 1e18;
    uint256 constant sampleSharesToConvert = 1e18;

    Migrator  migrator;
    MockERC20 newAsset;
    MockERC20 oldAsset;
    Staker    staker;
    xMPLOwner owner;
    xMPLOwner notOwner;
    xMPL      xmpl;

    function setUp() external {
        vm.warp(START);

        oldAsset = new MockERC20("Old Token", "OT", 18);
        newAsset = new MockERC20("New Token", "NT", 18);

        migrator = new Migrator(address(oldAsset), address(newAsset));

        owner    = new xMPLOwner();
        notOwner = new xMPLOwner();
        staker   = new Staker();

        newAsset.mint(address(migrator), OLD_SUPPLY);
        oldAsset.mint(address(staker),   DEPOSITED);

        xmpl = new xMPL("xMPL", "xMPL", address(owner), address(oldAsset), 1e30);

        staker.erc20_approve(address(oldAsset), address(xmpl), DEPOSITED);
        staker.rdToken_deposit(address(xmpl), DEPOSITED);
    }

    function test_cancelMigration_notOwner() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.expectRevert("xMPL:NOT_OWNER");
        notOwner.xMPL_cancelMigration(address(xmpl));

        owner.xMPL_cancelMigration(address(xmpl));
    }

    function test_cancelMigration_notScheduled() external {
        vm.expectRevert("xMPL:CM:NOT_SCHEDULED");
        owner.xMPL_cancelMigration(address(xmpl));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
        owner.xMPL_cancelMigration(address(xmpl));
    }

    function test_cancelMigration_success() external {
        assertEq(xmpl.scheduledMigrator(),           address(0));
        assertEq(xmpl.scheduledNewAsset(),           address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.scheduledMigrator(),           address(migrator));
        assertEq(xmpl.scheduledNewAsset(),           address(newAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(), START + xmpl.MINIMUM_MIGRATION_DELAY());

        owner.xMPL_cancelMigration(address(xmpl));

        assertEq(xmpl.scheduledMigrator(),           address(0));
        assertEq(xmpl.scheduledNewAsset(),           address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(), 0);
    }

    function test_performMigration_notOwner() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        vm.expectRevert("xMPL:NOT_OWNER");
        notOwner.xMPL_performMigration(address(xmpl));

        owner.xMPL_performMigration(address(xmpl));
    }

    function test_performMigration_notScheduled() external {
        vm.expectRevert("xMPL:PM:NOT_SCHEDULED");
        owner.xMPL_performMigration(address(xmpl));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        owner.xMPL_performMigration(address(xmpl));
    }

    function test_performMigration_tooEarly() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY() - 1);

        vm.expectRevert("xMPL:PM:TOO_EARLY");
        owner.xMPL_performMigration(address(xmpl));

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        owner.xMPL_performMigration(address(xmpl));
    }

    function test_performMigration_wrongAmount() external {
        CompromisedMigrator badMigrator = new CompromisedMigrator(address(oldAsset), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(badMigrator), address(newAsset));

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        vm.expectRevert("xMPL:PM:WRONG_AMOUNT");
        owner.xMPL_performMigration(address(xmpl));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + 2 * xmpl.MINIMUM_MIGRATION_DELAY());

        owner.xMPL_performMigration(address(xmpl));
    }

    function test_performMigration_migrationPostVesting(uint256 amount_, uint vestingPeriod_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        oldAsset.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY() + xmpl.vestingPeriodFinish());

        uint256 expectedRate        = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedTotalAssets = DEPOSITED + expectedRate * vestingPeriod_ / 1e30;

        assertEq(oldAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newAsset.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.asset(),                                address(oldAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.scheduledMigrator(),                    address(migrator));
        assertEq(xmpl.scheduledNewAsset(),                    address(newAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(),          START + xmpl.MINIMUM_MIGRATION_DELAY());

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalAssets(),                    DEPOSITED + amount_, 1);

        owner.xMPL_performMigration(address(xmpl));

        assertEq(oldAsset.balanceOf(address(xmpl)), 0);
        assertEq(newAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.asset(),                                address(newAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.scheduledMigrator(),                    address(0));
        assertEq(xmpl.scheduledNewAsset(),                    address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(),          0);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalAssets(),                    DEPOSITED + amount_, 1);
    }

    function test_performMigration_migrationBeforeVestingEnds(uint256 amount_, uint256 vestingPeriod_, uint256 warpAmount_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);
        warpAmount_    = constrictToRange(warpAmount_,    1,          vestingPeriod_);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY());

        oldAsset.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.MINIMUM_MIGRATION_DELAY() + warpAmount_);

        uint256 expectedRate        = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedTotalAssets = DEPOSITED + expectedRate * warpAmount_ / 1e30;

        assertEq(oldAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newAsset.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.asset(),                                address(oldAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.scheduledMigrator(),                    address(migrator));
        assertEq(xmpl.scheduledNewAsset(),                    address(newAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(),          START + xmpl.MINIMUM_MIGRATION_DELAY());

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), expectedTotalAssets, 1);

        owner.xMPL_performMigration(address(xmpl));

        assertEq(oldAsset.balanceOf(address(xmpl)), 0);
        assertEq(newAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.asset(),                                address(newAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.scheduledMigrator(),                    address(0));
        assertEq(xmpl.scheduledNewAsset(),                    address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(),          0);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), expectedTotalAssets, 1);
    }

    function test_scheduleMigration_notOwner() external {
        vm.expectRevert("xMPL:NOT_OWNER");
        notOwner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_scheduleMigration_zeroMigrator() external {
        vm.expectRevert("xMPL:SM:INVALID_MIGRATOR");
        owner.xMPL_scheduleMigration(address(xmpl), address(0), address(newAsset));
    }

    function test_scheduleMigration_zeroNewAsset() external {
        vm.expectRevert("xMPL:SM:INVALID_NEW_ASSET");
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(0));
    }

    function test_scheduleMigration_once() external {
        assertEq(xmpl.scheduledMigrator(),           address(0));
        assertEq(xmpl.scheduledNewAsset(),           address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.scheduledMigrator(),           address(migrator));
        assertEq(xmpl.scheduledNewAsset(),           address(newAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(), START + xmpl.MINIMUM_MIGRATION_DELAY());
    }

    function test_scheduleMigration_withCorrection() external {
        assertEq(xmpl.scheduledMigrator(),           address(0));
        assertEq(xmpl.scheduledNewAsset(),           address(0));
        assertEq(xmpl.scheduledMigrationTimestamp(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(oldAsset));

        assertEq(xmpl.scheduledMigrator(),           address(migrator));
        assertEq(xmpl.scheduledNewAsset(),           address(oldAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(), START + xmpl.MINIMUM_MIGRATION_DELAY());

        vm.warp(START + 1);
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.scheduledMigrator(),           address(migrator));
        assertEq(xmpl.scheduledNewAsset(),           address(newAsset));
        assertEq(xmpl.scheduledMigrationTimestamp(), START + 1 + xmpl.MINIMUM_MIGRATION_DELAY());
    }

}

///@dev Copied from modules/revenue-distribution-token/src/test/ReveneuDistributionToken.sol
contract FullMigrationTest is TestUtils {

    Migrator  migrator;
    MockERC20 asset;
    MockERC20 newAsset;
    xMPL      rdToken;

    bytes constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    uint256 start;

    function setUp() public virtual {
        // Use non-zero timestamp
        start = 10_000_000;
        vm.warp(start);

        asset    = new MockERC20("Old Token", "OT", 18);
        newAsset = new MockERC20("New Token", "NT", 18);
        migrator = new Migrator(address(asset), address(newAsset));
        rdToken  = new xMPL("Revenue Distribution Token", "RDT", address(this), address(asset), 1e30);
    }

    function test_fullMigrationStory(uint256 depositAmount, uint256 vestingAmount, uint256 vestingPeriod) external {
        depositAmount = constrictToRange(depositAmount, 1e6,        1e30);                    // 1 trillion at WAD precision
        vestingAmount = constrictToRange(vestingAmount, 1e6,        1e30);                    // 1 trillion at WAD precision
        vestingPeriod = constrictToRange(vestingPeriod, 10 seconds, 100_000 days) / 10 * 10;  // Must be divisible by 10 for for loop 10% increment calculations

        Staker staker = new Staker();

        asset.mint(address(staker), depositAmount);

        staker.erc20_approve(address(asset), address(rdToken), depositAmount);
        staker.rdToken_deposit(address(rdToken), depositAmount);

        assertEq(rdToken.freeAssets(),          depositAmount);
        assertEq(rdToken.totalAssets(),         depositAmount);
        assertEq(rdToken.convertToAssets(1e30), 1e30);
        assertEq(rdToken.issuanceRate(),        0);
        assertEq(rdToken.lastUpdated(),         start);
        assertEq(rdToken.vestingPeriodFinish(), 0);

        vm.warp(start + 1 days);

        assertEq(rdToken.totalAssets(), depositAmount);  // No change

        vm.warp(start);  // Warp back after demonstrating totalHoldings is not time-dependent before vesting starts

        _depositAndUpdateVesting(vestingAmount, vestingPeriod);

        uint256 expectedRate = vestingAmount * 1e30 / vestingPeriod;

        assertEq(rdToken.freeAssets(),          depositAmount);
        assertEq(rdToken.totalAssets(),         depositAmount);
        assertEq(rdToken.convertToAssets(1e30), 1e30);
        assertEq(rdToken.issuanceRate(),        expectedRate);
        assertEq(rdToken.lastUpdated(),         start);
        assertEq(rdToken.vestingPeriodFinish(), start + vestingPeriod);

        // Warp and assert vesting in 10% increments
        for (uint256 i = 1; i < 10; ++i) {
            vm.warp(start + vestingPeriod * i / 10);  // 10% intervals of vesting schedule

            uint256 expectedTotalHoldings = depositAmount + expectedRate * (block.timestamp - start) / 1e30;

            assertWithinDiff(rdToken.balanceOfAssets(address(staker)), expectedTotalHoldings, 1);

            // Do the migration
            if (i == 5) {
                newAsset.mint(address(migrator), asset.balanceOf(address(rdToken)));

                // go back in time to schedule a migration
                uint256 currentTimestamp = block.timestamp;
                vm.warp(block.timestamp - 10 days - 1);
                rdToken.scheduleMigration(address(migrator), address(newAsset));

                vm.warp(currentTimestamp);
                rdToken.performMigration();
            }

            assertEq(rdToken.totalAssets(),         expectedTotalHoldings);
            assertEq(rdToken.convertToAssets(1e30), expectedTotalHoldings * 1e30 / depositAmount);
        }

        vm.warp(start + vestingPeriod);

        uint256 expectedFinalTotal = depositAmount + vestingAmount;

        // Assertions below will use the newAsset token

        assertWithinDiff(rdToken.balanceOfAssets(address(staker)), expectedFinalTotal, 2);

        assertWithinDiff(rdToken.totalAssets(),         expectedFinalTotal,                           1);
        assertWithinDiff(rdToken.convertToAssets(1e30), rdToken.totalAssets() * 1e30 / depositAmount, 1);  // Using totalHoldings because of rounding

        assertEq(newAsset.balanceOf(address(rdToken)), depositAmount + vestingAmount);
        assertEq(asset.balanceOf(address(rdToken)),    0);

        assertEq(newAsset.balanceOf(address(staker)), 0);
        assertEq(rdToken.balanceOf(address(staker)),  depositAmount);

        staker.rdToken_redeem(address(rdToken), depositAmount);  // Use `redeem` so rdToken amount can be used to burn 100% of tokens

        assertWithinDiff(rdToken.freeAssets(),  0, 1);
        assertWithinDiff(rdToken.totalAssets(), 0, 1);

        assertEq(rdToken.convertToAssets(1e30), 1e30);                    // Exchange rate returns to zero when empty
        assertEq(rdToken.issuanceRate(),        expectedRate);
        assertEq(rdToken.lastUpdated(),         start + vestingPeriod);   // This makes issuanceRate * time zero
        assertEq(rdToken.vestingPeriodFinish(), start + vestingPeriod);

        assertWithinDiff(newAsset.balanceOf(address(rdToken)), 0, 2);

        assertEq(rdToken.balanceOfAssets(address(staker)), 0);

        assertWithinDiff(newAsset.balanceOf(address(staker)), depositAmount + vestingAmount, 2);
        assertWithinDiff(rdToken.balanceOf(address(staker)),  0,                             1);

        assertEq(asset.balanceOf(address(staker)), 0);
    }

    function _depositAndUpdateVesting(uint256 vestingAmount_, uint256 vestingPeriod_) internal {
        asset.mint(address(this), vestingAmount_);
        asset.transfer(address(rdToken), vestingAmount_);
        rdToken.updateVestingSchedule(vestingPeriod_);
    }

}
