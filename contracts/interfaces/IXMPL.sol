// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IRevenueDistributionToken } from "../../modules/revenue-distribution-token/src/interfaces/IRevenueDistributionToken.sol";

interface IXMPL is IRevenueDistributionToken {

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    function migrateAll(address migrator_, address newToken_) external;

}