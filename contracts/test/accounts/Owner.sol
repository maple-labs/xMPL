// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { Owner } from "../../../modules/revenue-distribution-token/contracts/test/accounts/Owner.sol";

import { IXMPL } from "../../interfaces/IXMPL.sol";

contract xMPLOwner is Owner {

    function xMPL_cancelMigration(address xmpl_) external {
        IXMPL(xmpl_).cancelMigration();
    }

    function xMPL_performMigration(address xmpl_, address migrator_, address newAsset_) external {
        IXMPL(xmpl_).performMigration(migrator_, newAsset_);
    }

    function xMPL_scheduleMigration(address xmpl_, address migrator_, address newAsset_) external {
        IXMPL(xmpl_).scheduleMigration(migrator_, newAsset_);
    }

}
