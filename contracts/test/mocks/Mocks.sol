// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

contract CompromisedMigrator {

    address public immutable oldToken;
    address public immutable newToken;

    constructor(address oldToken_, address newToken_) {
        oldToken = oldToken_;
        newToken = newToken_;
    }

    function migrate(uint256 amount_) external {
        // do nothing
    }
    
}
