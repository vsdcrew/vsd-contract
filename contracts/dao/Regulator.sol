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
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "./Comptroller.sol";
import "../external/Decimal.sol";
import "../Constants.sol";

contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 price, uint256 newSell, uint256 newRedeemable, uint256 lessDebt, uint256 newSupply, uint256 newReward);
    event SupplyDecrease(uint256 indexed epoch, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch);

    function step() internal {
        Decimal.D256 memory price = oracleCapture();

        uint256 allReserve = _updateReserve();

        if (price.greaterThan(Decimal.D256({value: getSupplyIncreasePriceThreshold()}))) {
            growSupply(price, allReserve);
            return;
        }

        if (price.lessThan(Decimal.D256({value: getSupplyDecreasePriceThreshold()}))) {
            shrinkSupply(price, allReserve);
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function shrinkSupply(Decimal.D256 memory price, uint256 allReserve) private {
        uint256 newDebt = _getBuyAmount(price.value, getSupplyDecreasePriceTarget(), allReserve);
        uint256 cappedNewDebt = setDebt(newDebt);

        emit SupplyDecrease(epoch(), price.value, cappedNewDebt);
        return;
    }

    function growSupply(Decimal.D256 memory price, uint256 allReserve) private {
        uint256 lessDebt = resetDebt(Decimal.zero());

        (uint256 sellAmount, uint256 returnAmount) = _getSellAndReturnAmount(
            price.value,
            getSupplyIncreasePriceTarget(),
            allReserve
        );
        _sellAndDepositCollateral(sellAmount, allReserve);
        uint256 mintAmount = returnAmount.mul(10000).div(getCollateralRatio());
        (uint256 newRedeemable, uint256 newSupply, uint256 newReward) = increaseSupply(mintAmount.sub(sellAmount));
        emit SupplyIncrease(epoch(), price.value, sellAmount, newRedeemable, lessDebt, newSupply, newReward);
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    /* for testing purpose */
    function getSupplyIncreasePriceThreshold() internal view returns (uint256) {
        return Constants.getSupplyIncreasePriceThreshold();
    }

    function getSupplyIncreasePriceTarget() internal view returns (uint256) {
        return Constants.getSupplyIncreasePriceTarget();
    }

    function getSupplyDecreasePriceThreshold() internal view returns (uint256) {
        return Constants.getSupplyDecreasePriceThreshold();
    }

    function getSupplyDecreasePriceTarget() internal view returns (uint256) {
        return Constants.getSupplyDecreasePriceTarget();
    }
}
