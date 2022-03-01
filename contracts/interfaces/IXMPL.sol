// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRevenueDistributionToken } from "../../modules/revenue-distribution-token/contracts/interfaces/IRevenueDistributionToken.sol";

interface IXMPL is IRevenueDistributionToken {

    /**************/
    /*** Events ***/
    /**************/

    event MigrationCancelled();

    event MigrationPerformed(uint256 amount);

    event MigrationScheduled(address from, address to, address migrator);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function cancelMigration() external;

    function performMigration(address migrator_, address newUnderlying_) external;

    function scheduleMigration(address migrator_, address newUnderlying_) external;

    /**********************/
    /*** View Functions ***/
    /**********************/

    function migrationHash() external view returns (bytes32 migrationHash_);

    function migrationScheduled() external view returns (uint256 migrationScheduled_);

    function minimumDelay() external pure returns (uint256 minimumDelay_);

}
