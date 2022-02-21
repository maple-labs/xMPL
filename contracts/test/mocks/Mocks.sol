// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

<<<<<<< HEAD
=======
import "../../xMPL.sol";

>>>>>>> 9bf9b21 (fix: basic invariant testing)
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

contract MutableXMPL is xMPL {

    constructor(string memory name_, string memory symbol_, address owner_, address underlying_, uint256 precision_)
        xMPL(name_, symbol_, owner_, underlying_, precision_)
    { }

    function setOwner(address owner_) external {
        owner = owner_;
    }

}