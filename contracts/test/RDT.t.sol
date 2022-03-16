// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { RevenueDistributionToken as RDT } from "../../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import { Staker } from "../../modules/revenue-distribution-token/contracts/test/accounts/Staker.sol";

import {
    AuthTest,
    DepositAndMintTest,
    DepositAndMintWithPermitTest,
    ExitTest,
    RevenueStreamingTest
} from "../../modules/revenue-distribution-token/contracts/test/RevenueDistributionToken.t.sol";

import { MockERC20 } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";

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

        // Deposit the minimum amount of the asset to allow the vesting schedule updates to occur.
        asset.mint(address(firstStaker), startingAssets);
        firstStaker.erc20_approve(address(asset), address(rdToken), startingAssets);
        firstStaker.rdToken_deposit(address(rdToken), startingAssets);
    }

}
