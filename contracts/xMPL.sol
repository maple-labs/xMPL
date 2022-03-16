// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20, RevenueDistributionToken } from "../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import { Migrator } from "../modules/mpl-migration/contracts/Migrator.sol";

import { IxMPL } from "./interfaces/IxMPL.sol";

/*
    ██╗  ██╗███╗   ███╗██████╗ ██╗
    ╚██╗██╔╝████╗ ████║██╔══██╗██║
     ╚███╔╝ ██╔████╔██║██████╔╝██║
     ██╔██╗ ██║╚██╔╝██║██╔═══╝ ██║
    ██╔╝ ██╗██║ ╚═╝ ██║██║     ███████╗
    ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝
*/

contract xMPL is IxMPL, RevenueDistributionToken {

    uint256 public constant override MINIMUM_MIGRATION_DELAY = 10 days;

    address public override scheduledMigrator;
    address public override scheduledNewAsset;

    uint256 public override scheduledMigrationTimestamp;

    constructor(string memory name_, string memory symbol_, address owner_, address asset_, uint256 precision_)
        RevenueDistributionToken(name_, symbol_, owner_, asset_, precision_) { }

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier onlyOwner {
        require(msg.sender == owner, "xMPL:NOT_OWNER");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function cancelMigration() external override onlyOwner {
        require(scheduledMigrationTimestamp != 0, "xMPL:CM:NOT_SCHEDULED");

        _cleanupMigration();

        emit MigrationCancelled();
    }

    function performMigration() external override onlyOwner {
        uint256 migrationTimestamp = scheduledMigrationTimestamp;
        address migrator           = scheduledMigrator;
        address oldAsset           = asset;
        address newAsset           = scheduledNewAsset;

        require(migrationTimestamp != 0,               "xMPL:PM:NOT_SCHEDULED");
        require(block.timestamp >= migrationTimestamp, "xMPL:PM:TOO_EARLY");

        uint256 oldAssetBalanceBeforeMigration = ERC20(oldAsset).balanceOf(address(this));
        uint256 newAssetBalanceBeforeMigration = ERC20(newAsset).balanceOf(address(this));

        require(ERC20(oldAsset).approve(migrator, oldAssetBalanceBeforeMigration), "xMPL:PM:APPROVAL_FAILED");

        Migrator(migrator).migrate(oldAssetBalanceBeforeMigration);

        require(ERC20(newAsset).balanceOf(address(this)) - newAssetBalanceBeforeMigration == oldAssetBalanceBeforeMigration, "xMPL:PM:WRONG_AMOUNT");

        emit MigrationPerformed(oldAsset, newAsset, oldAssetBalanceBeforeMigration);

        asset = newAsset;

        _cleanupMigration();
    }

    function scheduleMigration(address migrator_, address newAsset_) external override onlyOwner {
        require(migrator_ != address(0), "xMPL:SM:INVALID_MIGRATOR");
        require(newAsset_ != address(0), "xMPL:SM:INVALID_NEW_ASSET");

        scheduledMigrationTimestamp = block.timestamp + MINIMUM_MIGRATION_DELAY;
        scheduledMigrator           = migrator_;
        scheduledNewAsset           = newAsset_;

        emit MigrationScheduled(asset, newAsset_, migrator_, scheduledMigrationTimestamp);
    }

    /*************************/
    /*** Utility Functions ***/
    /*************************/

    function _cleanupMigration() internal {
        delete scheduledMigrationTimestamp;
        delete scheduledMigrator;
        delete scheduledNewAsset;
    }

}
