/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2021 vsdcrew <vsdcrew@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Comptroller.sol";
import "../external/Require.sol";

contract Collateral is Comptroller, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 private constant FILE = "Collateral";

    function redeem(uint256 value) external nonReentrant {
        uint256 actual = value;
        uint256 debt = totalDebt();
        if (debt > value) {
            // if there is debt, redeem at no cost
            debt = value;
        } else {
            // redeem with cost
            actual = value.sub((10000 - Constants.getRedemptionRate()).mul(value.sub(debt)).div(10000));
            uint256 fundReward = value.sub(actual);
            uint256 devReward = fundReward.mul(Constants.getFundDevPct()).div(100);
            uint256 treasuryReward = fundReward.sub(devReward);
            dollar().transferFrom(msg.sender, Constants.getDevAddress(), devReward);
            dollar().transferFrom(msg.sender, Constants.getTreasuryAddress(), treasuryReward);
        }

        uint256 len = _state.collateralAssetList.length;
        uint256 dollarTotalSupply = dollar().totalSupply();
        for (uint256 i = 0; i < len; i++) {
            address addr = _state.collateralAssetList[i];
            IERC20(addr).safeTransfer(
                msg.sender,
                actual.mul(IERC20(addr).balanceOf(address(this))).div(dollarTotalSupply)
            );
        }

        burnFromAccountForDebt(msg.sender, actual, debt);
    }

    function addCollateral(address asset) external {
        Require.that(
            msg.sender == address(this),
            FILE,
            "Must from governance"
        );

        _addCollateral(asset);
    }

    function _getMinterAddress() internal view returns (address) {
        return Constants.getMinterAddress();
    }
}
