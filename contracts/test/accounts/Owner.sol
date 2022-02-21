// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;


import { Owner, InvariantOwner, MockERC20 } from "../../../modules/revenue-distribution-token/src/test/accounts/Owner.sol";

import { IxMPL } from "../../interfaces/IxMPL.sol";

contract xMPLOwner is Owner {

    function xMPL_cancelMigration(address xmpl_) external {
        IxMPL(xmpl_).cancelMigration();
    }

    function xMPL_performMigration(address xmpl_) external {
        IxMPL(xmpl_).performMigration();
    }

    function xMPL_scheduleMigration(address xmpl_, address migrator_, address newAsset_) external {
        IxMPL(xmpl_).scheduleMigration(migrator_, newAsset_);
    }

}

contract xMPLInvariantOwner is InvariantOwner {

    address migrator;
    address newUnderlying;

    IXMPL xmpl = IXMPL(address(rdToken));

    constructor(address rdToken_, address underlying_, address migrator_, address newUnderlying_) InvariantOwner(rdToken_, underlying_){
        migrator      = migrator_;
        newUnderlying = newUnderlying_; 
    }

    function rdToken_migrateAll() external {
        MockERC20(newUnderlying).mint(migrator, underlying.balanceOf(migrator));
        xmpl.migrateAll(migrator, newUnderlying);
    }

}
