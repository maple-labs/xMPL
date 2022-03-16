// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20User }                      from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/accounts/ERC20User.sol";
import { ERC20BaseTest, ERC20PermitTest } from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/ERC20.t.sol";
import { MockERC20 }                      from "../../modules/revenue-distribution-token/modules/erc20/contracts/test/mocks/MockERC20.sol";

import { xMPL } from "../xMPL.sol";

import { MockERC20_xMPL } from "./mocks/MockERC20.xMPL.sol";  // Required for mint/burn tests

contract xMPL_ERC20Test is ERC20BaseTest {

    function setUp() override public {
        address asset = address(new MockERC20("MockToken", "MT", 18));
        _token = MockERC20(address(new MockERC20_xMPL("Token", "TKN", address(this), asset, 1e30)));
    }

}

contract xMPL_ERC20PermitTest is ERC20PermitTest {

    function setUp() override public {
        super.setUp();
        address asset = address(new MockERC20("MockToken", "MT", 18));
        _token = MockERC20(address(new xMPL("Token", "TKN", address(this), asset, 1e30)));
    }

    function test_domainSeparator() public override {
        assertEq(_token.DOMAIN_SEPARATOR(), 0xa0948b5dcf9f99364e925fbc7ed09b4fa9c2ca703920db5c3c2453442cc5dd0d);
    }

}
