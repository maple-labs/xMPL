// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { RDTInvariants } from "../../modules/revenue-distribution-token/contracts/test/Invariants.t.sol";
import { MutableRDT }    from "../../modules/revenue-distribution-token/contracts/test/utils/MutableRDT.sol";

import { xMPLMutable } from "./mocks/xMPLMutable.sol";

contract xMPL_RDT_InvariantTest is RDTInvariants {

    function setUp() override public {
        super.setUp();
        // Match name from upstream test
        rdToken = MutableRDT(address(new xMPLMutable("Token", "TKN", address(owner), address(underlying), 1e30)));
        rdToken.setOwner(address(owner));
    }

}