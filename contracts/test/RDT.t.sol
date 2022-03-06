// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { RevenueDistributionToken as RDT } from "../../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import {
    AuthTest,
    DepositAndMintTest,
    DepositAndMintWithPermitTest,
    ExitTest,
    RevenueStreamingTest
} from "../../modules/revenue-distribution-token/contracts/test/RevenueDistributionToken.t.sol";

import { xMPL } from "../xMPL.sol";

contract xMPL_RDT_AuthTest is AuthTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("Token", "TKN", address(owner), address(asset), 1e30)));
    }

}

contract xMPL_RDT_DepositAndMintTest is DepositAndMintTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("Token", "TKN", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_DepositAndMintWithPermitTest is DepositAndMintWithPermitTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("Token", "TKN", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_ExitTest is ExitTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("Token", "TKN", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_RevenueStreamingTest is RevenueStreamingTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("Token", "TKN", address(this), address(asset), 1e30)));
    }

}
