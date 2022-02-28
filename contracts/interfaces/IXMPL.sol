// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRevenueDistributionToken } from "../../modules/revenue-distribution-token/contracts/interfaces/IRevenueDistributionToken.sol";

interface IXMPL is IRevenueDistributionToken {

    /**************/
    /*** Events ***/
    /**************/

    event MigrationScheduled(address from, address to, address migrator);

    event MigrationCancelled();

    event MigrationCompleted(uint256 amount);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function scheduleMigration(address migrator_, address newUnderlying_) external;

    function cancelMigration() external;

    function migrateAll(address migrator_, address newUnderlying_) external;

}
