// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20Permit }     from "../../modules/revenue-distribution-token/modules/erc20/contracts/ERC20Permit.sol";
import { ERC20PermitUser } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/accounts/ERC20User.sol";
import { ERC20Test }       from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/ERC20.t.sol";
import { ERC20PermitTest } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/ERC20Permit.t.sol";
import { MockERC20 }       from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";

import { xMPL } from "../xMPL.sol";

import { MockERC20_xMPL } from "./mocks/MockERC20.xMPL.sol";  // Required for mint/burn tests

contract xMPL_ERC20Test is ERC20Test {

    function setUp() override public {
        address asset = address(new MockERC20("MockToken", "MT", 18));
        token = MockERC20(address(new MockERC20_xMPL("Revenue Distribution Token", "xMPL", address(this), asset, 1e30)));
    }

}

contract xMPL_ERC20PermitTest is ERC20PermitTest {

    function setUp() override public {
        super.setUp();
        address asset = address(new MockERC20("MockToken", "MT", 18));
        token = ERC20Permit(address(new xMPL("ERC20Permit", "ERC20Permit", address(this), asset, 1e30)));
    }

    function test_domainSeparator() external override {
        assertEq(token.DOMAIN_SEPARATOR(), 0x8ea77afa92184f25cca951da8c2ffc09e16cebfe25b2e826e87a0844991706a9);
    }

}