// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { MockERC20 } from "../../modules/mpl-migration/modules/erc20/src/test/mocks/MockERC20.sol";
import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";

import { xMPL } from "../xMPL.sol";

import { xMPLOwner } from "./accounts/Owner.sol";

import { CompromisedMigrator } from "./mocks/Mocks.sol";

contract xMPLTest is TestUtils {

    uint256 constant OLD_SUPPLY = 10_000_000 ether;

    Migrator  migrator;
    MockERC20 newToken;
    MockERC20 oldToken;
    xMPL      xmpl;
    xMPLOwner notOwner;
    xMPLOwner owner;

    function setUp() external {
        oldToken = new MockERC20("Old Token", "OT", 18);
        newToken = new MockERC20("New Token", "NT", 18);

        migrator = new Migrator(address(oldToken), address(newToken));

        newToken.mint(address(migrator), OLD_SUPPLY);

        owner    = new xMPLOwner();
        notOwner = new xMPLOwner();

        xmpl = new xMPL("xMPL", "xMPL", address(owner), address(oldToken), 1e30);
    }

    function test_migrateAll_migration(uint256 amount_, uint vestingPeriod_) external {
        amount_        = constrictToRange(amount_,                 1, OLD_SUPPLY);
        vestingPeriod_ = constrictToRange(vestingPeriod_, 10 seconds, 100_000 days) / 10 * 10;
        oldToken.mint(address(xmpl), amount_);
        owner.rdToken_updateVestingSchedule(address(xmpl), vestingPeriod_);

        assertEq(oldToken.balanceOf(address(xmpl)),       amount_);
        assertEq(newToken.balanceOf(address(xmpl)),       0);
        assertEq(xmpl.underlying(),                       address(oldToken));
        assertEq(xmpl.balanceOfUnderlying(address(this)), 0);
        assertEq(xmpl.totalHoldings(),                    0);
        assertEq(xmpl.exchangeRate(),                     1e30);

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)),       0);
        assertEq(newToken.balanceOf(address(xmpl)),       amount_);
        assertEq(xmpl.underlying(),                       address(newToken));
        assertEq(xmpl.balanceOfUnderlying(address(this)), 0);
        assertEq(xmpl.totalHoldings(),                    0);
        assertEq(xmpl.exchangeRate(),                     1e30);
    }

    function test_migrateAll_failIfNotOwner(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY);
        oldToken.mint(address(xmpl), amount_);

        vm.expectRevert("XMPL:MA:NOT_OWNER");
        notOwner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

    function test_migrateAll_failIfWrongToken(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY);
        oldToken.mint(address(xmpl), amount_);

        vm.expectRevert("XMPL:MA:WRONG_TOKEN");
        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(oldToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

    function test_migrateAll_failIfMismatchedBalance(uint256 amount_) external {
        amount_ = constrictToRange(amount_, 1, OLD_SUPPLY);
        oldToken.mint(address(xmpl), amount_);

        CompromisedMigrator migrator_ = new CompromisedMigrator(address(oldToken), address(newToken));

        vm.expectRevert("XMPL:MA:WRONG_AMOUNT");
        owner.xMPL_migrateAll(address(xmpl), address(migrator_), address(newToken));

        owner.xMPL_migrateAll(address(xmpl), address(migrator), address(newToken));

        assertEq(oldToken.balanceOf(address(xmpl)), 0);
        assertEq(newToken.balanceOf(address(xmpl)), amount_);
        assertEq(xmpl.underlying(),                 address(newToken));
    }

}
