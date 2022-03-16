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
    *  @param fromAsset_ The address of the old asset.
    *  @param toAsset_   The address of new asset migrated to.
    *  @param amount_    The amount of tokens migrated.
    */
    event MigrationPerformed(address indexed fromAsset_, address indexed toAsset_, uint256 amount_);

    /**
    *  @dev   Notifies that migration was scheduled.
    *  @param fromAsset_     The current asset address.
    *  @param toAsset_       The address of the asset to be migrated to.
    *  @param migrator_      The address of the migrator contract.
    *  @param migrationTime_ The earliest time the migration is scheduled for.
    */
    event MigrationScheduled(address indexed fromAsset_, address indexed toAsset_, address indexed migrator_, uint256 migrationTime_);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
    *  @dev Cancel the scheduled migration
    */
    function cancelMigration() external;

    /**
    *  @dev Perform a migration of the asset.
    */
    function performMigration() external;

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
    *  @dev    Get the minimum delay that a scheduled transaction needs in order to be executed.
    *  @return minimumMigrationDelay_ The delay in seconds.
    */
    function MINIMUM_MIGRATION_DELAY() external pure returns (uint256 minimumMigrationDelay_);

    /**
    *  @dev    Get the timestamp that a migration is scheduled for.
    *  @return scheduledMigrationTimestamp_ The timestamp of the migration.
    */
    function scheduledMigrationTimestamp() external view returns (uint256 scheduledMigrationTimestamp_);

    /**
    *  @dev    The address of the migrator contract to be used during the scheduled migration.
    *  @return scheduledMigrator_ The address of the migrator.
    */
    function scheduledMigrator() external view returns (address scheduledMigrator_);

    /**
    *  @dev    The address of the new asset token to be migrated to during the scheduled migration.
    *  @return scheduledNewAsset_ The address of the new asset token.
    */
    function scheduledNewAsset() external view returns (address scheduledNewAsset_);

}
