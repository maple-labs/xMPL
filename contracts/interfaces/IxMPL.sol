// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRevenueDistributionToken } from "../../modules/revenue-distribution-token/contracts/interfaces/IRevenueDistributionToken.sol";

interface IxMPL is IRevenueDistributionToken {

    /**************/
    /*** Events ***/
    /**************/

    /**
    *  @dev Notifies that a scheduled migration was cancelled.
    */
    event MigrationCancelled();

    /**
    *  @dev   Notifies that a scheduled migration was executed.
    *  @param amount the amount of tokens migrated.
    */
    event MigrationPerformed(uint256 amount);

    /**
    *  @dev   Notifies that migration was scheduled.
    *  @param from     current asset address.
    *  @param to       address of the asset to be migrated to.
    *  @param migrator address of the migrator contract.
    */
    event MigrationScheduled(address from, address to, address migrator);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
    *  @dev Cancel the scheduled migration
    */
    function cancelMigration() external;

    /**
    *  @dev   Perform a migration of the asset.
    *  @param migrator_ The address of the migrator contract.
    *  @param newAsset_ The address of the new asset token.
    */
    function performMigration(address migrator_, address newAsset_) external;

    /**
    *  @dev   Schedule a migration to be executed after a delay.
    *  @param migrator_ The address of the migrator contract.
    *  @param newAsset_ The address of the new asset token.
    */
    function scheduleMigration(address migrator_, address newAsset_) external;

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
    *  @dev    Get the migration has of a scheduled migration.
    *  @return migrationHash_ The hash of the migration parameters.
    */
    function migrationHash() external view returns (bytes32 migrationHash_);

    /**
    *  @dev    Get the timestamp that a migration was scheduled.
    *  @return migrationScheduled_ The timestamp of the migration.
    */
    function migrationScheduled() external view returns (uint256 migrationScheduled_);

    /**
    *  @dev    Get the minimum delay that a schedule transactions needs to be executed.
    *  @return minimumDelay_ The delay in seconds.
    */
    function minimumDelay() external pure returns (uint256 minimumDelay_);

}
