// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { Owner, InvariantOwner, MockERC20 } from "../../../modules/revenue-distribution-token/contracts/test/accounts/Owner.sol";

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

    address _migrator;
    address newUnderlying;

    IxMPL xmpl = IxMPL(address(_rdToken));

    constructor(address rdToken_, address underlying_, address migrator_, address newUnderlying_) InvariantOwner(rdToken_, underlying_){
        _migrator      = migrator_;
        newUnderlying = newUnderlying_;
    }

    function rdToken_scheduleAndPerformMigration() external {
        xmpl.scheduleMigration(_migrator, newUnderlying);

        vm.warp(block.timestamp + 10 days + 1);

        xmpl.performMigration();
    }

}
