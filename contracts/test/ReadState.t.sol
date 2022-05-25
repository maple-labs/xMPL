// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IxMPL } from "../interfaces/IxMPL.sol";
import { console } from "../../modules/contract-test-utils/contracts/log.sol";
import { TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

contract ReadState is TestUtils {
    
    IxMPL xMPL = IxMPL(0x309032B075488A201A982B1843649132864d2271);

    function setUp() public {}

    function test_readState() public {
        uint256 totalAssets = xMPL.totalAssets();
        uint256 totalSupply = xMPL.totalSupply();
        uint256 converted = xMPL.convertToAssets(totalSupply);

        console.log(totalAssets);
        console.log(totalSupply);
        console.log(converted);
        console.log("ts", block.timestamp);

        assertWithinDiff(converted, totalAssets, 1);
    }
}