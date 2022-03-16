// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { xMPL } from "../../xMPL.sol";

contract MockERC20_xMPL is xMPL {

    constructor(string memory name_, string memory symbol_, address owner_, address asset_, uint256 precision_)
        xMPL(name_, symbol_, owner_, asset_, precision_) { }

    function mint(address recipient_, uint256 amount_) external {
        _mint(recipient_, amount_);
    }

    function burn(address owner_, uint256 amount_) external {
        _burn(owner_, amount_);
    }

}
