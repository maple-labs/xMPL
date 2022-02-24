// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { CompromisedMigrator } from "./mocks/Mocks.sol";

import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";
import { MockERC20 } from "../../modules/mpl-migration/modules/erc20/src/test/mocks/MockERC20.sol";

import { Staker } from "../../modules/revenue-distribution-token/src/test/accounts/Staker.sol";

import { xMPL } from "../xMPL.sol";

import { xMPLOwner } from "./accounts/Owner.sol";


contract xMPLTest is TestUtils {

    uint256 constant OLD_SUPPLY = 10_000_000 ether;
    uint256 constant DEPOSITED  = 1 ether;

    uint256 start;

    Migrator  migrator;
    MockERC20 newToken;
    MockERC20 oldToken;
    Staker    staker;
    xMPL      xmpl;
    xMPLOwner notOwner;
    xMPLOwner owner;

    function setUp() external {
        // Use non-zero timestamp
        start = 10_000;
        vm.warp(start);

        oldToken = new MockERC20("Old Token", "OT", 18);
        newToken = new MockERC20("New Token", "NT", 18);

        migrator = new Migrator(address(oldToken), address(newToken));

        owner    = new xMPLOwner();
        notOwner = new xMPLOwner();

        staker = new Staker();

        newToken.mint(address(migrator), OLD_SUPPLY);
        oldToken.mint(address(staker),   DEPOSITED);

        xmpl = new xMPL("xMPL", "xMPL", address(owner), address(oldToken), 1e30);

        staker.erc20_approve(address(oldToken), address(xmpl), DEPOSITED);
        staker.rdToken_deposit(address(xmpl), DEPOSITED);
    }

    function test_migrateAll_migrationPostVesting(uint256 amount_, uint vestingPeriod_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);

        oldToken.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(xmpl.vestingPeriodFinish());
        
        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedHoldings = DEPOSITED + expectedRate * (block.timestamp - start) / 1e30;

        assertEq(oldToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newToken.balanceOf(address(xmpl)), 0);
        assertEq(xmpl.underlying(),                 address(oldToken));
        assertEq(xmpl.totalHoldings(),              expectedHoldings);
        assertEq(xmpl.exchangeRate(),               expectedHoldings * 1e30 / DEPOSITED);

        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalHoldings(),                      DEPOSITED + amount_, 1);

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(xmpl.underlying(),                 address(newToken));
        assertEq(xmpl.totalHoldings(),              expectedHoldings);
        assertEq(xmpl.exchangeRate(),               expectedHoldings * 1e30 / DEPOSITED);
   
        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), DEPOSITED + amount_, 1);
        assertWithinDiff(xmpl.totalHoldings(),                      DEPOSITED + amount_, 1);

    }

    function test_migrateAll_migrationBeforVestingEnds(uint256 amount_, uint256 vestingPeriod_, uint256 warpAmount_) external {
        amount_        = constrictToRange(amount_,        1,          OLD_SUPPLY - DEPOSITED);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days);
        warpAmount_    = constrictToRange(warpAmount_,    1,          vestingPeriod_);

        oldToken.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        vm.warp(block.timestamp + warpAmount_);
        
        uint256 expectedRate     = amount_ * 1e30 / vestingPeriod_;
        uint256 expectedHoldings = DEPOSITED + expectedRate * (block.timestamp - start) / 1e30;

        assertEq(oldToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(newToken.balanceOf(address(xmpl)), 0);
        assertEq(xmpl.underlying(),                 address(oldToken));
        assertEq(xmpl.totalHoldings(),              expectedHoldings);
        assertEq(xmpl.exchangeRate(),               expectedHoldings * 1e30 / DEPOSITED);

        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), expectedHoldings, 1);

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(xmpl.underlying(),                 address(newToken));
        assertEq(xmpl.totalHoldings(),              expectedHoldings);
        assertEq(xmpl.exchangeRate(),               expectedHoldings * 1e30 / DEPOSITED);
   
        assertWithinDiff(xmpl.balanceOfUnderlying(address(staker)), expectedHoldings, 1);
    }

    function test_migrateAll_failIfNotOwner(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY - DEPOSITED);
        oldToken.mint(address(xmpl), amount_);

        vm.expectRevert("XMPL:MA:NOT_OWNER");
        notOwner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

    function test_migrateAll_failIfWrongToken(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY - DEPOSITED);
        oldToken.mint(address(xmpl), amount_);

        vm.expectRevert("XMPL:MA:WRONG_TOKEN");
        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(oldToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

    function test_migrateAll_failIfMismatchedBalance(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY - DEPOSITED);
        oldToken.mint(address(xmpl), amount_);

        CompromisedMigrator badMigrator = new CompromisedMigrator(address(oldToken), address(newToken));

        vm.expectRevert("XMPL:MA:WRONG_AMOUNT");
        owner.xMPL_migrateAll(address(xmpl), address(badMigrator), address(newToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_ + DEPOSITED);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

}
