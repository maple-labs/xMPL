// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ERC20, RevenueDistributionToken } from "../modules/revenue-distribution-token/src/RevenueDistributionToken.sol";

import { Migrator } from "../modules/mpl-migration/contracts/Migrator.sol";

import { IXMPL } from "./interfaces/IXMPL.sol";

contract xMPL is IXMPL, RevenueDistributionToken {

    uint256 public constant MINIMUM_DELAY = 10 days;

    bytes32 public override migrationHash;
    uint256 public override migrationScheduled;

    constructor(string memory name_, string memory symbol_, address owner_, address underlying_, uint256 precision_)
        RevenueDistributionToken(name_, symbol_, owner_, underlying_, precision_) { }

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier onlyOwner {
        require(msg.sender == owner, "XMPL:NOT_OWNER");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function cancelMigration() external override onlyOwner {
        require(migrationScheduled != 0, "XMPL:CM:NOT_SCHEDULED");

        _cleanupMigration();

        emit MigrationCancelled();
    }

    function performMigration(address migrator_, address newUnderlying_) external override onlyOwner {
        uint256 migrationScheduled_ = migrationScheduled;

        require(migrationScheduled_ != 0,                                   "XMPL:PM:NOT_SCHEDULED");
        require(block.timestamp >= migrationScheduled_ + MINIMUM_DELAY,     "XMPL:PM:TOO_EARLY");
        require(_calculateHash(migrator_, newUnderlying_) == migrationHash, "XMPL:PM:INVALID_ARGS");

        ERC20    currentUnderlying = ERC20(underlying);
        ERC20    newUnderlying     = ERC20(newUnderlying_);
        Migrator migrator          = Migrator(migrator_);

        require(migrator.newToken() == newUnderlying_, "XMPL:PM:WRONG_TOKEN");

        uint256 amountToMigrate        = currentUnderlying.balanceOf(address(this));
        uint256 balanceBeforeMigration = newUnderlying.balanceOf(address(this));

        currentUnderlying.approve(migrator_, amountToMigrate);
        migrator.migrate(amountToMigrate);

        require(newUnderlying.balanceOf(address(this)) - balanceBeforeMigration == amountToMigrate, "XMPL:PM:WRONG_AMOUNT");

        underlying = newUnderlying_;

        _cleanupMigration();

        emit MigrationPerformed(amountToMigrate);
    }

    function scheduleMigration(address migrator_, address newUnderlying_) external override onlyOwner {
        migrationScheduled = block.timestamp;
        migrationHash      = _calculateHash(migrator_, newUnderlying_);

        emit MigrationScheduled(underlying, newUnderlying_, migrator_);
    }

    /*************************/
    /*** Utility Functions ***/
    /*************************/

    function _calculateHash(address migrator_, address underlying_) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(migrator_, underlying_));
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
