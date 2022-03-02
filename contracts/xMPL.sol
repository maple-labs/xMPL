// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20, RevenueDistributionToken } from "../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import { Migrator } from "../modules/mpl-migration/contracts/Migrator.sol";

contract xMPL is RevenueDistributionToken {

    constructor(string memory name_, string memory symbol_, address owner_, address underlying_, uint256 precision_)
        RevenueDistributionToken(name_, symbol_, owner_, underlying_, precision_){ }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function migrateAll(address migrator_, address newUnderlying_) external {
        require(msg.sender == owner, "XMPL:MA:NOT_OWNER");
        
        ERC20    currentUnderlying = ERC20(underlying);
        ERC20    newUnderlying     = ERC20(newUnderlying_);
        Migrator migrator          = Migrator(migrator_);

        require(migrator.newToken() == newUnderlying_, "XMPL:MA:WRONG_TOKEN");

        uint256 balance = currentUnderlying.balanceOf(address(this));
        currentUnderlying.approve(migrator_, balance);

        migrator.migrate(balance);

        require(newUnderlying.balanceOf(address(this)) == balance, "XMPL:MA:WRONG_AMOUNT");

        underlying = newUnderlying_;
    }

}
