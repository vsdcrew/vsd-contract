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
import "./State.sol";
import "../Constants.sol";

contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 (only for snapshot voting)
     */

    function name() public view returns (string memory) {
        return "Value Set Dollar Stake";
    }

    function symbol() public view returns (string memory) {
        return "VSDS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOfBondedDollar(account);
    }

    function totalSupply() public view returns (uint256) {
        return totalBondedDollar();
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function usdc() public view returns (address) {
        return Constants.getUsdcAddress();
    }

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function totalBonded(address pool) public view returns (uint256) {
        return _state.pools[pool].bonded;
    }

    function totalStaged(address pool) public view returns (uint256) {
        return _state.pools[pool].staged;
    }

    function totalDebt() public view returns (uint256) {
        return _state.balance.debt;
    }

    function totalRedeemable() public view returns (uint256) {
        return _state.balance.redeemable;
    }

    function totalClippable() public view returns (uint256) {
        return _state.balance.clippable;
    }

    function totalCoupons() public view returns (uint256) {
        return _state.balance.coupons;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply().sub(totalDebt());
    }

    function totalBondedDollar() public view returns (uint256) {
        uint256 len = _state.poolList.length;
        uint256 bondedDollar = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            uint256 bondedLP = totalBonded(pool);
            if (bondedLP == 0) {
                continue;
            }

            (uint256 poolBonded, ) = _getDollarReserve(pool, bondedLP);

            bondedDollar = bondedDollar.add(poolBonded);
        }
        return bondedDollar;
    }

    /**
     * Account
     */

    function balanceOfStaged(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].staged;
    }

    function balanceOfBonded(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].bonded;
    }

    function balanceOfBondedDollar(address account) public view returns (uint256) {
        uint256 len = _state.poolList.length;
        uint256 bondedDollar = 0;
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            uint256 bondedLP = balanceOfBonded(pool, account);
            if (bondedLP == 0) {
                continue;
            }

            (uint256 reserve, ) = _getDollarReserve(pool, bondedLP);

            bondedDollar = bondedDollar.add(reserve);
        }
        return bondedDollar;
    }

    function balanceOfCoupons(address account, uint256 epoch) public view returns (uint256) {
        if (outstandingCoupons(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch];
    }

    function balanceOfClippable(address account, uint256 epoch) public view returns (uint256) {
        if (redeemableVSDs(epoch) == 0) {
            return 0;
        }
        return _state.accounts[account].coupons[epoch].mul(redeemableVSDs(epoch)).div(redeemedCoupons(epoch));
    }

    function statusOf(address pool, address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.pools[pool].accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address pool, address account) public view returns (uint256) {
        return _state.pools[pool].accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
    }

    function allowanceCoupons(address owner, address spender) public view returns (uint256) {
        return _state.accounts[owner].couponAllowances[spender];
    }

    function pendingReward(address pool) public view returns (uint256 pending) {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];

        if (user.bonded > 0) {
            pending = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18).sub(user.rewardDebt);
        }
    }

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        Constants.EpochStrategy memory current = Constants.getCurrentEpochStrategy();

        return epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy) private view returns (uint256) {
        return blockTimestamp()
            .sub(strategy.start)
            .div(strategy.period)
            .add(strategy.offset);
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function outstandingCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.outstanding;
    }

    function redeemedCoupons(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.couponRedeemed;
    }

    function redeemableVSDs(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].coupons.vsdRedeemable;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= Constants.getBootstrappingPeriod();
    }

    function totalDollarSupplyAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].totalDollarSupply;
    }

    /**
     * Governance
     */

    function recordedVoteInfo(address account, uint256 candidate) public view returns (Candidate.VoteInfo memory) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(uint256 candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(uint256 candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(uint256 candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(uint256 candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * Collateral
     */

    function _getDollarReserve(address pool, uint256 bonded) internal view returns (uint256 reserve, uint256 totalReserve) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pool).getReserves();
        if (IUniswapV2Pair(pool).token0() == address(dollar())) {
            totalReserve = reserve0;
        } else {
            require(IUniswapV2Pair(pool).token1() == address(dollar()), "the pool does not contain dollar");
            totalReserve = reserve1;
        }

        if (bonded == 0) {
            return (0, totalReserve);
        }

        reserve = totalReserve.mul(bonded).div(IUniswapV2Pair(pool).totalSupply());
    }

    function _getSellAndReturnAmount(
        uint256 price,
        uint256 targetPrice,
        uint256 reserve
    ) internal pure returns (uint256 sellAmount, uint256 returnAmount) {
        // price in resolution 1e18
        sellAmount = 0;
        returnAmount = 0;

        uint256 rootPoT = Babylonian.sqrt(price.mul(1e36).div(targetPrice));
        if (rootPoT > 1e18) { // res error
            sellAmount = (rootPoT - 1e18).mul(reserve).div(1e18);
        }

        uint256 rootPT = Babylonian.sqrt(price.mul(targetPrice));
        if (price > rootPT) { // res error
            returnAmount = (price - rootPT).mul(reserve).div(1e18);
        }
        if (sellAmount > returnAmount) { // res error
            sellAmount = returnAmount;
        }
    }

    function _getBuyAmount(uint256 price, uint256 targetPrice, uint256 reserve) internal pure returns (uint256 shouldBuy) {
        shouldBuy = 0;

        uint256 root = Babylonian.sqrt(price.mul(1e36).div(targetPrice));
        if (root < 1e18) { // res error
            shouldBuy = (1e18 - root).mul(reserve).div(1e18);
        }
    }

    function getCollateralRatio() internal view returns (uint256) {
        return _state.collateralRatio;
    }
}
