// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { xMPL } from "../../xMPL.sol";

contract MockERC20_xMPL is xMPL {

    constructor(string memory name_, string memory symbol_, address owner_, address asset_, uint256 precision_)
        xMPL(name_, symbol_, owner_, asset_, precision_) { }

    function mint(address to_, uint256 value_) external {
        _mint(to_, value_);
    }

    function burn(address from_, uint256 value_) external {
        _burn(from_, value_);
    }

}