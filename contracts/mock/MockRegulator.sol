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

import "../dao/Regulator.sol";
import "../oracle/IOracle.sol";
import "./MockComptroller.sol";
import "./MockState.sol";

contract MockRegulator is MockComptroller, Regulator {

    constructor (address oracle) MockComptroller() public {
        _state.provider.oracle = IOracle(oracle);
    }

    function stepE() external {
        super.step();
    }

    function stepOldE() external {
        Decimal.D256 memory price = oracleCapture();

        _updateReserve();

        if (price.greaterThan(Decimal.one())) {
            growSupplyOld(price);
            return;
        }

        if (price.lessThan(Decimal.one())) {
            shrinkSupplyOld(price);
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function shrinkSupplyOld(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limitOld(Decimal.one().sub(price), price);
        uint256 newDebt = delta.mul(totalNet()).asUint256();
        uint256 cappedNewDebt = increaseDebt(newDebt);

        emit SupplyDecrease(epoch(), price.value, cappedNewDebt);
        return;
    }

    function growSupplyOld(Decimal.D256 memory price) private {
        uint256 lessDebt = resetDebt(Decimal.zero());

        Decimal.D256 memory delta = limitOld(price.sub(Decimal.one()), price);
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 newBonded, uint256 newReward) = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), price.value, newSupply, newRedeemable, lessDebt, newBonded, newReward);
    }

    function limitOld(Decimal.D256 memory delta, Decimal.D256 memory price) private view returns (Decimal.D256 memory) {

        Decimal.D256 memory supplyChangeLimit = Decimal.D256({value: 3e16});

        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (price.greaterThan(Decimal.one()) && (totalRedeemable < totalCoupons)) {
            supplyChangeLimit = Constants.getCouponSupplyChangeLimit();
        }

        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;

    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= 5;
    }

    function claimE(address pool) public {
        preClaimDollar(pool);
        postClaimDollar(pool);
    }

    function getSupplyIncreasePriceThreshold() internal view returns (uint256) {
        return 1e18;
    }

    function getSupplyIncreasePriceTarget() internal view returns (uint256) {
        return 1e18;
    }

    function getSupplyDecreasePriceThreshold() internal view returns (uint256) {
        return 1e18;
    }

    function getSupplyDecreasePriceTarget() internal view returns (uint256) {
        return 1e18;
    }

    function getSupplyIncreaseFundRatio() internal view returns (uint256) {
        return 2250;
    }
}
