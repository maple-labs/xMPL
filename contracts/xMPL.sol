// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20Permit, RevenueDistributionToken } from "../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import { Migrator } from "../modules/mpl-migration/contracts/Migrator.sol";

import { IxMPL } from "./interfaces/IxMPL.sol";

contract xMPL is IxMPL, RevenueDistributionToken {

    uint256 public constant MINIMUM_DELAY = 10 days;

    bytes32 public override migrationHash;
    uint256 public override migrationScheduled;

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
        require(migrationScheduled != 0, "xMPL:CM:NOT_SCHEDULED");

        _cleanupMigration();

        emit MigrationCancelled();
    }

    function performMigration(address migrator_, address newAsset_) external override onlyOwner {
        uint256 migrationScheduled_ = migrationScheduled;

        require(migrationScheduled_ != 0,                               "xMPL:PM:NOT_SCHEDULED");
        require(block.timestamp >= migrationScheduled_ + MINIMUM_DELAY, "xMPL:PM:TOO_EARLY");
        require(_calculateHash(migrator_, newAsset_) == migrationHash,  "xMPL:PM:INVALID_ARGS");

        ERC20Permit currentAsset = ERC20Permit(asset);
        ERC20Permit newAsset     = ERC20Permit(newAsset_);
        Migrator    migrator     = Migrator(migrator_);

        require(migrator.newToken() == newAsset_, "xMPL:PM:WRONG_TOKEN");

        uint256 amountToMigrate        = currentAsset.balanceOf(address(this));
        uint256 balanceBeforeMigration = newAsset.balanceOf(address(this));

        currentAsset.approve(migrator_, amountToMigrate);
        migrator.migrate(amountToMigrate);

        require(newAsset.balanceOf(address(this)) - balanceBeforeMigration == amountToMigrate, "xMPL:PM:WRONG_AMOUNT");

        asset = newAsset_;

        _cleanupMigration();

        emit MigrationPerformed(amountToMigrate);
    }

    function scheduleMigration(address migrator_, address newAsset_) external override onlyOwner {
        migrationScheduled = block.timestamp;
        migrationHash      = _calculateHash(migrator_, newAsset_);

        emit MigrationScheduled(asset, newAsset_, migrator_);
    }

    /*************************/
    /*** Utility Functions ***/
    /*************************/

    function _calculateHash(address migrator_, address asset_) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(migrator_, asset_));
    }

    function _cleanupMigration() internal {
        delete migrationScheduled;
        delete migrationHash;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function minimumDelay() external pure override returns (uint256 minimumDelay_) {
        return MINIMUM_DELAY;
    }
}
