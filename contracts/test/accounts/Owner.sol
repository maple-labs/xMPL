// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { Owner } from "../../../modules/revenue-distribution-token/src/test/accounts/Owner.sol";

import { IXMPL } from "../../interfaces/IXMPL.sol";

contract xMPLOwner is Owner {

    function xMPL_migrateAll(address rdt_, address migrator_, address newToken_) external {
        IXMPL(rdt_).migrateAll(migrator_, newToken_);
    }

}  