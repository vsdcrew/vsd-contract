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
import "./Setters.sol";
import "../external/Require.sol";

contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        increaseDebt(amount);

        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        burnFromAccountForDebt(account, amount, amount);
    }

    function burnFromAccountForDebt(address account, uint256 amount, uint256 debtAmount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);
        decrementTotalDebt(debtAmount);

        balanceCheck();
    }
    
    function clipToAccount(address account, uint256 amount) internal {
        dollar().transfer(account, amount);
        decrementTotalClippable(amount);

        balanceCheck();
    }

    function redeemToClippable(uint256 amount) internal {
        decrementTotalRedeemable(amount);
        incrementTotalClippable(amount);

        balanceCheck();
    }

    function setDebt(uint256 amount) internal returns (uint256) {
        _state.balance.debt = amount;
        uint256 lessDebt = resetDebt(Constants.getDebtRatioCap());

        balanceCheck();

        return lessDebt > amount ? 0 : amount.sub(lessDebt);
    }

    function increaseDebt(uint256 amount) internal returns (uint256) {
        incrementTotalDebt(amount);
        uint256 lessDebt = resetDebt(Constants.getDebtRatioCap());

        balanceCheck();

        return lessDebt > amount ? 0 : amount.sub(lessDebt);
    }

    function decreaseDebt(uint256 amount) internal {
        decrementTotalDebt(amount);

        balanceCheck();
    }

    function _updateReserve() internal returns (uint256 allReserve) {
        uint256 totalAllocPoint = 0;
        uint256 len = _state.poolList.length;
        allReserve = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            Storage.PoolInfo storage poolInfo = _state.pools[pool];

            uint256 poolReserve;
            (poolInfo.allocPoint, poolReserve) = _getDollarReserve(pool, _state.pools[pool].bonded);
            totalAllocPoint = totalAllocPoint.add(poolInfo.allocPoint);
            allReserve = allReserve.add(poolReserve);
        }
        _state.totalAllocPoint = totalAllocPoint;
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256, uint256) {
        // 0. Pay out to Fund
        uint256 rewards = newSupply.mul(getSupplyIncreaseFundRatio()).div(10000);
        uint256 devReward = rewards.mul(Constants.getFundDevPct()).div(100);
        uint256 treasuryReward = rewards.sub(devReward);
        if (devReward != 0) {
            dollar().mint(Constants.getDevAddress(), devReward);
        }
        if (treasuryReward != 0) {
            dollar().mint(Constants.getTreasuryAddress(), treasuryReward);
        }

        newSupply = newSupply > rewards ? newSupply.sub(rewards) : 0;

        // 1. True up redeemable pool
        uint256 newRedeemable = 0;
        uint256 totalRedeemable = totalRedeemable();
        uint256 totalCoupons = totalCoupons();
        if (totalRedeemable < totalCoupons) {
            newRedeemable = totalCoupons.sub(totalRedeemable);
            newRedeemable = newRedeemable > newSupply ? newSupply : newRedeemable;
            mintToRedeemable(newRedeemable);
            newSupply = newSupply.sub(newRedeemable);
        }

        // 2. Payout to LPs
        if (!mintToLPs(newSupply)) {
            newSupply = 0;
        }

        balanceCheck();

        return (newRedeemable, newSupply.add(rewards), newSupply);
    }

    function resetDebt(Decimal.D256 memory targetDebtRatio) internal returns (uint256) {
        uint256 targetDebt = targetDebtRatio.mul(dollar().totalSupply()).asUint256();
        uint256 currentDebt = totalDebt();

        if (currentDebt > targetDebt) {
            uint256 lessDebt = currentDebt.sub(targetDebt);
            decreaseDebt(lessDebt);

            return lessDebt;
        }

        return 0;
    }

    function balanceCheck() private {
        // Require.that(
        //     dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()).add(totalRedeemable()).add(totalClippable()),
        //     FILE,
        //     "Inconsistent balances"
        // );
    }

    function mintToLPs(uint256 amount) private returns (bool) {
        if (amount == 0) {
            return false;
        }

        if (_state.totalAllocPoint == 0) {
            return false;
        }

        dollar().mint(address(this), amount);
        uint256 len = _state.poolList.length;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            Storage.PoolInfo storage poolInfo = _state.pools[pool];

            if (poolInfo.bonded == 0) {
                continue;
            }
            uint256 poolAmount = amount.mul(poolInfo.allocPoint).div(_state.totalAllocPoint);
            poolInfo.accDollarPerLP = poolInfo.accDollarPerLP.add(poolAmount.mul(1e18).div(poolInfo.bonded));
        }

        return true;
    }

    function mintToRedeemable(uint256 amount) private {
        dollar().mint(address(this), amount);
        incrementTotalRedeemable(amount);

        balanceCheck();
    }

    /* for testing purpose */
    function getSupplyIncreaseFundRatio() internal view returns (uint256) {
        return Constants.getSupplyIncreaseFundRatio();
    }
}
