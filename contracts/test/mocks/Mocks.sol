// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "../../xMPL.sol";

contract CompromisedMigrator {

    address public immutable newToken;
    address public immutable oldToken;

    constructor(address oldToken_, address newToken_) {
        oldToken = oldToken_;
        newToken = newToken_;
    }

    function migrate(uint256 amount_) external {
        // do nothing
    }

}

contract MutableXMPL is xMPL {

    constructor(string memory name_, string memory symbol_, address owner_, address underlying_, uint256 precision_)
        xMPL(name_, symbol_, owner_, underlying_, precision_) { }

    function setOwner(address owner_) external {
        owner = owner_;
    }

}
