// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { CompromisedMigrator } from "./mocks/Mocks.sol";

import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";
import { MockERC20 } from "../../modules/mpl-migration/modules/erc20/src/test/mocks/MockERC20.sol";

import { Staker } from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";

import { xMPL } from "../xMPL.sol";

import { xMPLOwner } from "./accounts/Owner.sol";

contract xMPLTest is TestUtils {

    uint256 constant DEPOSITED  = 1e18;
    uint256 constant OLD_SUPPLY = 10_000_000e18;
    uint256 constant START      = 52 weeks;

    MockERC20 newUnderlying;
    MockERC20 oldUnderlying;
    Migrator  migrator;
    xMPLOwner owner;
    xMPLOwner notOwner;
    Staker    staker;
    xMPL      xmpl;

    function setUp() external {
        vm.warp(START);

        oldUnderlying = new MockERC20("Old Token", "OT", 18);
        newUnderlying = new MockERC20("New Token", "NT", 18);

        migrator = new Migrator(address(oldUnderlying), address(newUnderlying));

        owner    = new xMPLOwner();
        notOwner = new xMPLOwner();
        staker   = new Staker();

        newUnderlying.mint(address(migrator), OLD_SUPPLY);
        oldUnderlying.mint(address(staker),   DEPOSITED);

        xmpl = new xMPL("xMPL", "xMPL", address(owner), address(oldUnderlying), 1e30);

        staker.erc20_approve(address(oldUnderlying), address(xmpl), DEPOSITED);
        staker.rdToken_deposit(address(xmpl), DEPOSITED);
    }

    function test_cancelMigration_notOwner() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.expectRevert("XMPL:NOT_OWNER");
        notOwner.xMPL_cancelMigration(address(xmpl));

        owner.xMPL_cancelMigration(address(xmpl));
    }

    function test_cancelMigration_notScheduled() external {
        vm.expectRevert("XMPL:CM:NOT_SCHEDULED");
        owner.xMPL_cancelMigration(address(xmpl));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));
        owner.xMPL_cancelMigration(address(xmpl));
    }

    function test_cancelMigration_success() external {
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newUnderlying))));
        assertEq(xmpl.migrationScheduled(), START);

        owner.xMPL_cancelMigration(address(xmpl));

        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);
    }

    function test_performMigration_notOwner() external {
        vm.expectRevert("XMPL:NOT_OWNER");
        notOwner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_notScheduled() external {
        vm.expectRevert("XMPL:PM:NOT_SCHEDULED");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_tooEarly() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay() - 1);

        vm.expectRevert("XMPL:PM:TOO_EARLY");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_invalidArguments() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("XMPL:PM:INVALID_ARGS");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(oldUnderlying));

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_wrongToken() external {
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(oldUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("XMPL:PM:WRONG_TOKEN");
        owner.xMPL_performMigration(address(xmpl), address(migrator), address(oldUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + 2 * xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_wrongAmount() external {
        CompromisedMigrator badMigrator = new CompromisedMigrator(address(oldUnderlying), address(newUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(badMigrator), address(newUnderlying));

        vm.warp(START + xmpl.minimumDelay());

        vm.expectRevert("XMPL:PM:WRONG_AMOUNT");
        owner.xMPL_performMigration(address(xmpl), address(badMigrator), address(newUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        vm.warp(START + 2 * xmpl.minimumDelay());

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_performMigration_migrationPostVesting(uint256 amount_, uint vestingPeriod_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));
        vm.warp(START + xmpl.minimumDelay());

        oldUnderlying.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.minimumDelay() + xmpl.vestingPeriodFinish());
        
        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedHoldings = DEPOSITED + expectedRate * (xmpl.vestingPeriodFinish() - START - xmpl.minimumDelay()) / 1e30;

        assertEq(oldUnderlying.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newUnderlying.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.underlying(),    address(oldUnderlying));
        assertEq(xmpl.totalHoldings(), expectedHoldings);
        assertEq(xmpl.exchangeRate(),  expectedHoldings * 1e30 / DEPOSITED);

        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalHoldings(),                      DEPOSITED + amount_, 1);

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));

        assertEq(oldUnderlying.balanceOf(address(xmpl)), 0);
        assertEq(newUnderlying.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.underlying(),    address(newUnderlying));
        assertEq(xmpl.totalHoldings(), expectedHoldings);
        assertEq(xmpl.exchangeRate(),  expectedHoldings * 1e30 / DEPOSITED);
   
        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalHoldings(),                      DEPOSITED + amount_, 1);
    }

    function test_performMigration_migrationBeforeVestingEnds(uint256 amount_, uint256 vestingPeriod_, uint256 warpAmount_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);
        warpAmount_    = constrictToRange(warpAmount_,    1,          vestingPeriod_);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));
        vm.warp(START + xmpl.minimumDelay());

        oldUnderlying.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(START + xmpl.minimumDelay() + warpAmount_);
        
        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedHoldings = DEPOSITED + expectedRate * (block.timestamp - START - xmpl.minimumDelay()) / 1e30;

        assertEq(oldUnderlying.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newUnderlying.balanceOf(address(xmpl)), 0);

        assertEq(xmpl.underlying(),    address(oldUnderlying));
        assertEq(xmpl.totalHoldings(), expectedHoldings);
        assertEq(xmpl.exchangeRate(),  expectedHoldings * 1e30 / DEPOSITED);

        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), expectedHoldings, 1);

        owner.xMPL_performMigration(address(xmpl), address(migrator), address(newUnderlying));

        assertEq(oldUnderlying.balanceOf(address(xmpl)), 0);
        assertEq(newUnderlying.balanceOf(address(xmpl)), amount_ + DEPOSITED);

        assertEq(xmpl.underlying(),    address(newUnderlying));
        assertEq(xmpl.totalHoldings(), expectedHoldings);
        assertEq(xmpl.exchangeRate(),  expectedHoldings * 1e30 / DEPOSITED);
   
        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), expectedHoldings, 1);
    }

    function test_scheduleMigration_notOwner() external {
        vm.expectRevert("XMPL:NOT_OWNER");
        notOwner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));
    }

    function test_scheduleMigration_once() external {
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newUnderlying))));
        assertEq(xmpl.migrationScheduled(), START);
    }

    function test_scheduleMigration_withCorrection() external {
        assertEq(xmpl.migrationHash(),      0);
        assertEq(xmpl.migrationScheduled(), 0);

        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(oldUnderlying));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(oldUnderlying))));
        assertEq(xmpl.migrationScheduled(), START);

        vm.warp(START + 1);
        owner.xMPL_scheduleMigration(address(xmpl), address(migrator), address(newUnderlying));

        assertEq(xmpl.migrationHash(),      keccak256(abi.encode(address(migrator), address(newUnderlying))));
        assertEq(xmpl.migrationScheduled(), START + 1);
    }

}
