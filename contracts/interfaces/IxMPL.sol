// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRevenueDistributionToken } from "../../modules/revenue-distribution-token/contracts/interfaces/IRevenueDistributionToken.sol";

interface IxMPL is IRevenueDistributionToken {

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

    /**
    *  @dev   Perform a migration of the asset.
    *  @param migrator_ The address of the migrator contract.
    *  @param newAsset_ The address of the new asset token.
    */
    function performMigration(address migrator_, address newAsset_) external;

    function scheduleMigration(address migrator_, address newAsset) external;

    /**********************/
    /*** View Functions ***/
    /**********************/

    function migrationHash() external view returns (bytes32 migrationHash_);

    function migrationScheduled() external view returns (uint256 migrationScheduled_);

    function minimumDelay() external pure returns (uint256 minimumDelay_);

}
