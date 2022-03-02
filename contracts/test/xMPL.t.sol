// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { CompromisedMigrator } from "./mocks/Mocks.sol";

import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";
import { MockERC20 } from "../../modules/mpl-migration/modules/erc20/contracts/test/mocks/MockERC20.sol";

import { Staker } from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";

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
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newAsset))));
        assertEq(xmpl.migrationScheduled(), START);

        owner.xMPL_cancelMigration(address(xmpl));

        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);
    }

    function test_performMigration_notOwner() external {
        vm.expectRevert("xMPL:NOT_OWNER");
        notOwner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_notScheduled() external {
        vm.expectRevert("xMPL:PM:NOT_SCHEDULED");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_tooEarly() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay() - 1);

        vm.expectRevert("xMPL:PM:TOO_EARLY");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_invalidArguments() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("xMPL:PM:INVALID_ARGS");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(oldAsset));

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_wrongToken() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(oldAsset));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("xMPL:PM:WRONG_TOKEN");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(oldAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + 2 * xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_wrongAmount() external {
        CompromisedMigrator badMigrator = new CompromisedMigrator(address(oldAsset), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(badMigrator), address(newAsset));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("xMPL:PM:WRONG_AMOUNT");
        owner.xMPL_performMigration(address(xmpl), address(badMigrator), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        vm.warp(START + 2 * xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_performMigration_migrationPostVesting(uint256 amount_, uint vestingPeriod_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
        vm.warp(START + xmpl.minimumDelay());

        oldAsset.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.minimumDelay() + xmpl.vestingPeriodFinish());

        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedTotalAssets = DEPOSITED + expectedRate * vestingPeriod_ / 1e30;

        assertEq(oldAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newAsset.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.asset(),                                address(oldAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.migrationHash(),                        keccak256(abi.encode(address(migrator), address(newAsset))));
        assertEq(xmpl.migrationScheduled(),                   START);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalAssets(),                    DEPOSITED + amount_, 1);

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(oldAsset.balanceOf(address(xmpl)), 0);
        assertEq(newAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.asset(),                                address(newAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.migrationHash(),                        0);
        assertEq(xmpl.migrationScheduled(),                   0);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalAssets(),                    DEPOSITED + amount_, 1);
    }

    function test_performMigration_migrationBeforeVestingEnds(uint256 amount_, uint256 vestingPeriod_, uint256 warpAmount_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);
        warpAmount_    = constrictToRange(warpAmount_,    1,          vestingPeriod_);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
        vm.warp(START + xmpl.minimumDelay());

        oldAsset.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.minimumDelay() + warpAmount_);

        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedTotalAssets = DEPOSITED + expectedRate * warpAmount_ / 1e30;

        assertEq(oldAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newAsset.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.asset(),                                address(oldAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.migrationHash(),                        keccak256(abi.encode(address(migrator), address(newAsset))));
        assertEq(xmpl.migrationScheduled(),                   START);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), expectedTotalAssets, 1);

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(oldAsset.balanceOf(address(xmpl)), 0);
        assertEq(newAsset.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.asset(),                                address(newAsset));
        assertEq(xmpl.totalAssets(),                          expectedTotalAssets);
        assertEq(xmpl.convertToAssets(sampleSharesToConvert), sampleSharesToConvert * expectedTotalAssets / DEPOSITED);
        assertEq(xmpl.convertToShares(sampleAssetsToConvert), sampleAssetsToConvert * DEPOSITED / expectedTotalAssets);
        assertEq(xmpl.migrationHash(),                        0);
        assertEq(xmpl.migrationScheduled(),                   0);

        assertWithinDiff(xmpl.balanceOfAssets(address(staker)), expectedTotalAssets, 1);
    }

    function test_scheduleMigration_notOwner() external {
        vm.expectRevert("xMPL:NOT_OWNER");
        notOwner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));
    }

    function test_scheduleMigration_once() external {
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newAsset))));
        assertEq(xmpl.migrationScheduled(), START);
    }

    function test_scheduleMigration_withCorrection() external {
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(oldAsset));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(oldAsset))));
        assertEq(xmpl.migrationScheduled(), START);

        vm.warp(START + 1);
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newAsset));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newAsset))));
        assertEq(xmpl.migrationScheduled(), START + 1);
    }

}
