// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { TestUtils, InvariantTest }  from "../../modules/contract-test-utils/contracts/test.sol";
import { InvariantStakerManager }    from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";
import { InvariantERC20User }        from "../../modules/revenue-distribution-token/contracts/test/accounts/ERC20User.sol";
import { Warper }                    from "../../modules/revenue-distribution-token/contracts/test/accounts/Warper.sol";
import { MockERC20 }                 from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";
import { RDTInvariants, MutableRDT } from "../../modules/revenue-distribution-token/contracts/test/Invariants.t.sol";

import { xMPLInvariantOwner } from "./accounts/Owner.sol";

import { MutableXMPL } from "./mocks/Mocks.sol";

import { Migrator }  from "../../modules/mpl-migration/contracts/Migrator.sol";

contract xMPLInvariants is RDTInvariants {

    InvariantERC20User newErc20User;
    Migrator           migrator;
    MockERC20          newUnderlying;
    xMPLInvariantOwner owner_;

    bool migrated;

    function setUp() public override {
        underlying    = new MockERC20("MockToken", "MT", 18);
        newUnderlying = new MockERC20("NewMockToken", "NMT", 18);
        migrator      = new Migrator(address(underlying), address(newUnderlying));
        
        rdToken       = MutableRDT(address(new MutableXMPL("Revenue Distribution Token", "RDT", address(this), address(underlying), 1e30)));
        
        erc20User     = new InvariantERC20User(address(rdToken), address(underlying));
        newErc20User  = new InvariantERC20User(address(rdToken), address(underlying));
        stakerManager = new InvariantStakerManager(address(rdToken), address(underlying));
        owner_        = new xMPLInvariantOwner(address(rdToken), address(underlying), address(migrator), address(newUnderlying));
        warper        = new Warper();

        // Required to prevent `acceptOwner` from being a target function
        // TODO: Investigate hevm.store error: `hevm: internal error: unexpected failure code`
        rdToken.setOwner(address(owner_));

        // Performs random transfers of underlying into contract
        addTargetContract(address(erc20User));
        addTargetContract(address(newErc20User));

        // Performs random transfers of underlying into contract
        // Performs random updateVestingSchedule calls
        addTargetContract(address(owner_));

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

}
