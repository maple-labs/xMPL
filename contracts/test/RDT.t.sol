// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

// import { ERC20Permit }     from "../../modules/revenue-distribution-token/modules/erc20/contracts/ERC20Permit.sol";
// import { ERC20PermitUser } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/accounts/ERC20User.sol";
// import { ERC20Test }       from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/ERC20.t.sol";
// import { ERC20PermitTest } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/ERC20Permit.t.sol";
// import { MockERC20 }       from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";

import { RevenueDistributionToken as RDT } from "../../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";
import {
    AuthTest,
    DepositTest,
    DepositAndMintWithPermitTest,
    ExitTest,
    RevenueStreamingTest
} from "../../modules/revenue-distribution-token/contracts/test/RevenueDistributionToken.t.sol";

import { xMPL } from "../xMPL.sol";

import { MockERC20_xMPL } from "./mocks/MockERC20.xMPL.sol";  // Required for mint/burn tests

contract xMPL_RDT_AuthTest is AuthTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("xMPL", "xMPL", address(owner), address(asset), 1e30)));
    }

}

contract xMPL_RDT_DepositTest is DepositTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("xMPL", "xMPL", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_DepositAndMintWithPermitTest is DepositAndMintWithPermitTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("xMPL", "xMPL", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_ExitTest is ExitTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("xMPL", "xMPL", address(this), address(asset), 1e30)));
    }

}

contract xMPL_RDT_RevenueStreamingTest is RevenueStreamingTest {

    function setUp() override public {
        super.setUp();
        rdToken = RDT(address(new xMPL("xMPL", "xMPL", address(this), address(asset), 1e30)));
    }

}