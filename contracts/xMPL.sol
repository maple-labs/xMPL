// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IXMPL } from "./interfaces/IXMPL.sol";

import { ERC20, RevenueDistributionToken } from "../modules/revenue-distribution-token/contracts/RevenueDistributionToken.sol";

import { Migrator } from "../modules/mpl-migration/contracts/Migrator.sol";

contract xMPL is IXMPL, RevenueDistributionToken {

    uint256 internal constant MINIMUM_DELAY = 10 days;

    uint256 internal _migrationScheduled;
    bytes32 internal _migrationHash;

    constructor(string memory name_, string memory symbol_, address owner_, address underlying_, uint256 precision_)
        RevenueDistributionToken(name_, symbol_, owner_, underlying_, precision_) {}

    /*****************/
    /*** Modifiers ***/
    /*****************/

    modifier onlyOwner() {
        require(msg.sender == owner, "XMPL:NOT_OWNER");
        _;
    }

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function scheduleMigration(address migrator_, address newUnderlying_) external override onlyOwner() {
        _migrationScheduled = block.timestamp;
        _migrationHash      = _calculateHash(migrator_, newUnderlying_);

        emit MigrationScheduled(underlying, newUnderlying_, migrator_);
    }

    function cancelMigration() external override onlyOwner() {
        _cleanupMigration();

        emit MigrationCancelled();
    }

    function migrateAll(address migrator_, address newUnderlying_) external override onlyOwner() {
        uint256 migrationScheduled = _migrationScheduled;

        require(migrationScheduled != 0,                                     "XMPL:MA:NOT_SCHEDULED");
        require(block.timestamp >= migrationScheduled + MINIMUM_DELAY,       "XMPL:MA:TOO_EARLY");
        require(_calculateHash(migrator_, newUnderlying_) == _migrationHash, "XMPL:MA:INVALID_ARGS");

        ERC20    currentUnderlying = ERC20(underlying);
        ERC20    newUnderlying     = ERC20(newUnderlying_);
        Migrator migrator          = Migrator(migrator_);

        require(migrator.newToken() == newUnderlying_, "XMPL:MA:WRONG_TOKEN");

        uint256 balance = currentUnderlying.balanceOf(address(this));
        currentUnderlying.approve(migrator_, balance);

        migrator.migrate(balance);

        require(newUnderlying.balanceOf(address(this)) == balance, "XMPL:MA:WRONG_AMOUNT");

        underlying = newUnderlying_;

        _cleanupMigration();

        emit MigrationCompleted(balance);
    }

    /*************************/
    /*** Utility Functions ***/
    /*************************/

    function _calculateHash(address migrator_, address underlying_) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(migrator_, underlying_));
    }

    function _cleanupMigration() internal {
        delete _migrationScheduled;
        delete _migrationHash;
    }

}
