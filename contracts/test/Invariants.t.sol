// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { TestUtils, InvariantTest }  from "../../modules/contract-test-utils/contracts/test.sol";
import { Migrator }                  from "../../modules/mpl-migration/contracts/Migrator.sol";
import { InvariantERC20User }        from "../../modules/revenue-distribution-token/contracts/test/accounts/ERC20User.sol";
import { InvariantStakerManager }    from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";
import { Warper }                    from "../../modules/revenue-distribution-token/contracts/test/accounts/Warper.sol";
import { RDTInvariants, MutableRDT } from "../../modules/revenue-distribution-token/contracts/test/Invariants.t.sol";
import { MockERC20 }                 from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";

import { xMPLInvariantOwner } from "./accounts/Owner.sol";

import { MutableXMPL } from "./mocks/Mocks.sol";

contract xMPLInvariants is RDTInvariants {

    InvariantERC20User internal _newErc20User;
    Migrator           internal _migrator;
    MockERC20          internal _newUnderlying;
    xMPLInvariantOwner internal _invariantOwner;  // Different from inherited _owner

    bool migrated;

    function setUp() public override {
        _underlying    = new MockERC20("MockToken", "MT", 18);
        _newUnderlying = new MockERC20("NewMockToken", "NMT", 18);
        _migrator      = new Migrator(address(_underlying), address(_newUnderlying));

        _rdToken = MutableRDT(address(new MutableXMPL("Revenue Distribution Token", "RDT", address(this), address(_underlying), 1e30)));

        _erc20User      = new InvariantERC20User(address(_rdToken), address(_underlying));
        _newErc20User   = new InvariantERC20User(address(_rdToken), address(_underlying));
        _stakerManager  = new InvariantStakerManager(address(_rdToken), address(_underlying));
        _invariantOwner = new xMPLInvariantOwner(address(_rdToken), address(_underlying), address(_migrator), address(_newUnderlying));
        _warper         = new Warper();

        // Required to prevent `acceptOwner` from being a target function
        _rdToken.setOwner(address(_invariantOwner));

        // Performs random transfers of underlying into contract
        addTargetContract(address(_erc20User));
        addTargetContract(address(_newErc20User));

        // Performs random transfers of underlying into contract
        // Performs random updateVestingSchedule calls
        addTargetContract(address(_invariantOwner));

        // Performs random instantiations of new staker users
        // Performs random deposit calls from a random instantiated staker
        // Performs random withdraw calls from a random instantiated staker
        // Performs random redeem calls from a random instantiated staker
        addTargetContract(address(_stakerManager));

        // Peforms random warps forward in time
        addTargetContract(address(_warper));

        // Create one staker to prevent underflows on index calculations
        _stakerManager.createStaker();
    }

}
