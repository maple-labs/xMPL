// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { TestUtils, InvariantTest } from "../../modules/contract-test-utils/contracts/test.sol";

import { xMPLInvariantOwner } from "./accounts/Owner.sol";

import { MutableXMPL } from "./mocks/Mocks.sol";

import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";

import { InvariantStakerManager } from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";
import { InvariantERC20User }     from "../../modules/revenue-distribution-token/contracts/test/accounts/ERC20User.sol";
import { Warper }                 from "../../modules/revenue-distribution-token/contracts/test/accounts/Warper.sol";

import { MockERC20 } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";


contract xMPLInvariants is TestUtils, InvariantTest {

    InvariantERC20User     erc20User;
    InvariantERC20User     newErc20User;
    InvariantStakerManager stakerManager;
    Migrator               migrator;
    MockERC20              underlying;
    MockERC20              newUnderlying;
    MutableXMPL            rdToken;
    xMPLInvariantOwner     owner;
    Warper                 warper;

    bool migrated;

    function setUp() public {
        underlying    = new MockERC20("MockToken", "MT", 18);
        newUnderlying = new MockERC20("NewMockToken", "NMT", 18);
        migrator      = new Migrator(address(underlying), address(newUnderlying));
        rdToken       = new MutableXMPL("Revenue Distribution Token", "RDT", address(this), address(underlying), 1e30);
        erc20User     = new InvariantERC20User(address(rdToken), address(underlying));
        newErc20User  = new InvariantERC20User(address(rdToken), address(underlying));
        stakerManager = new InvariantStakerManager(address(rdToken), address(underlying));
        owner         = new xMPLInvariantOwner(address(rdToken), address(underlying), address(migrator), address(newUnderlying));
        warper        = new Warper();

        // Required to prevent `acceptOwner` from being a target function
        // TODO: Investigate hevm.store error: `hevm: internal error: unexpected failure code`
        rdToken.setOwner(address(owner));

        // Performs random transfers of underlying into contract
        addTargetContract(address(erc20User));
        addTargetContract(address(newErc20User));

        // Performs random transfers of underlying into contract
        // Performs random updateVestingSchedule calls
        addTargetContract(address(owner));

        // Performs random instantiations of new staker users
        // Performs random deposit calls from a random instantiated staker
        // Performs random withdraw calls from a random instantiated staker
        // Performs random redeem calls from a random instantiated staker
        addTargetContract(address(stakerManager));

        // Peforms random warps forward in time
        addTargetContract(address(warper));

        // Create one staker to prevent underflows on index calculations
        stakerManager.createStaker();
    }

    function invariant1_totalHoldings_lte_underlyingBal() public {
        assertTrue(rdToken.totalAssets() <= underlying.balanceOf(address(rdToken)));
    }

    function invariant2_sumBalanceOfUnderlying_eq_totalHoldings() public {
        // Only relevant if deposits exist
        if(rdToken.totalSupply() > 0) {
            uint256 sumBalanceOfUnderlying;
            uint256 stakerCount = stakerManager.getStakerCount();

            for(uint256 i; i < stakerCount; ++i) {
                sumBalanceOfUnderlying += rdToken.balanceOfAssets(address(stakerManager.stakers(i)));
            }

            assertTrue(sumBalanceOfUnderlying <= rdToken.totalAssets());
            assertWithinDiff(sumBalanceOfUnderlying, rdToken.totalAssets(), stakerCount);  // Rounding error of one per user
        }
    }

    function invariant3_totalSupply_lte_totalHoldings() external {
        assertTrue(rdToken.totalSupply() <= rdToken.totalAssets());
    }

    function invariant4_totalSupply_times_exchangeRate_eq_totalHoldings() external {
        if(rdToken.totalSupply() > 0) {
            assertWithinDiff(rdToken.convertToAssets(rdToken.totalSupply()) / rdToken.precision(), rdToken.totalAssets(), 1);  // One division
        }
    }

    // function invariant5_exchangeRate_gte_precision() external {
    //     assertTrue(rdToken.exchangeRate() >= rdToken.precision());
    // }

    function invariant6_freeUnderlying_lte_totalHoldings() external {
        assertTrue(rdToken.freeAssets() <= rdToken.totalAssets());
    }

    function invariant7_balanceOfUnderlying_gte_balanceOf() public {
        for(uint256 i; i < stakerManager.getStakerCount(); ++i) {
            address staker = address(stakerManager.stakers(i));
            assertTrue(rdToken.balanceOfAssets(staker) >= rdToken.balanceOf(staker));
        }
    }
}
