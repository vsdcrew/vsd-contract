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
import "./State.sol";
import "./Getters.sol";
import "../external/UniswapV2Library.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Setters is State, Getters {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Claim(address indexed pool, address indexed account, uint256 value);

    /**
     * Global
     */

    function incrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.add(amount);
    }

    function decrementTotalDebt(uint256 amount) internal {
        _state.balance.debt = _state.balance.debt.sub(amount);
    }

    function incrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.add(amount);
    }

    function decrementTotalRedeemable(uint256 amount) internal {
        _state.balance.redeemable = _state.balance.redeemable.sub(amount);
    }

    function decrementTotalClippable(uint256 amount) internal {
        _state.balance.clippable = _state.balance.clippable.sub(amount);
    }

    function incrementTotalClippable(uint256 amount) internal {
        _state.balance.clippable = _state.balance.clippable.add(amount);
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].bonded = _state.pools[pool].accounts[account].bonded.add(amount);
        _state.pools[pool].bonded = _state.pools[pool].bonded.add(amount);
    }

    function decrementBalanceOfBonded(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].bonded = _state.pools[pool].accounts[account].bonded.sub(amount);
        _state.pools[pool].bonded = _state.pools[pool].bonded.sub(amount);
    }

    function incrementBalanceOfStaged(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].staged = _state.pools[pool].accounts[account].staged.add(amount);
        _state.pools[pool].staged = _state.pools[pool].staged.add(amount);
    }

    function decrementBalanceOfStaged(address pool, address account, uint256 amount) internal {
        _state.pools[pool].accounts[account].staged = _state.pools[pool].accounts[account].staged.sub(amount);
        _state.pools[pool].staged = _state.pools[pool].staged.sub(amount);
    }

    function incrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].add(amount);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.add(amount);
        _state.balance.coupons = _state.balance.coupons.add(amount);
    }

    function decrementBalanceOfCoupons(address account, uint256 epoch, uint256 amount) internal {
        _state.accounts[account].coupons[epoch] = _state.accounts[account].coupons[epoch].sub(amount);
        _state.epochs[epoch].coupons.outstanding = _state.epochs[epoch].coupons.outstanding.sub(amount);
        _state.balance.coupons = _state.balance.coupons.sub(amount);
    }

    function clipRedeemedCoupon(address account, uint256 epoch) internal returns (uint256 vsdRedeemable) {
        uint256 couponRedeemed = _state.accounts[account].coupons[epoch];
        _state.accounts[account].coupons[epoch] = 0;
        // require(_state.epochs[epoch].coupons.outstanding == 0);
        vsdRedeemable = _state.epochs[epoch].coupons.vsdRedeemable.mul(couponRedeemed).div(_state.epochs[epoch].coupons.couponRedeemed);
    }

    function unfreeze(address pool, address account) internal {
        _state.pools[pool].accounts[account].fluidUntil = epoch().add(Constants.getDAOExitLockupEpochs());
    }

    function updateAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] = amount;
    }

    function decrementAllowanceCoupons(address owner, address spender, uint256 amount) internal {
        _state.accounts[owner].couponAllowances[spender] =
            _state.accounts[owner].couponAllowances[spender].sub(amount);
    }

    /**
     * Epoch
     */

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
    }

    function snapshotDollarTotalSupply() internal {
        _state.epochs[epoch()].totalDollarSupply = dollar().totalSupply();
    }

    function redeemOutstandingCoupons(uint256 epoch) internal returns (uint256 couponRedeemed, uint256 vsdRedeemable) {
        uint256 outstandingCouponsForEpoch = outstandingCoupons(epoch);
        if(outstandingCouponsForEpoch == 0) {
            return (0, 0);
        }
        _state.balance.coupons = _state.balance.coupons.sub(outstandingCouponsForEpoch);

        uint256 totalRedeemable = totalRedeemable();
        vsdRedeemable = outstandingCouponsForEpoch;
        couponRedeemed = outstandingCouponsForEpoch;
        if (totalRedeemable < vsdRedeemable) {
            // Partial redemption
            vsdRedeemable = totalRedeemable;
        }

        _state.epochs[epoch].coupons.couponRedeemed = outstandingCouponsForEpoch;
        _state.epochs[epoch].coupons.vsdRedeemable = vsdRedeemable;
        _state.epochs[epoch].coupons.outstanding = 0;
    }

    /**
     * Governance
     */

    function createCandidate(uint256 candidate, uint256 period) internal {
        _state.candidates[candidate].start = epoch();
        _state.candidates[candidate].period = period;
    }

    function recordVoteInfo(address account, uint256 candidate, Candidate.VoteInfo memory voteInfo) internal {
        _state.candidates[candidate].votes[account] = voteInfo;
    }

    function incrementApproveFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.add(amount);
    }

    function decrementApproveFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.sub(amount);
    }

    function incrementRejectFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.add(amount);
    }

    function decrementRejectFor(uint256 candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.sub(amount);
    }

    function placeLock(address account, uint256 candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate).add(periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(uint256 candidate) internal {
        _state.candidates[candidate].initialized = true;
    }

    /**
     * Pool
     */

    function _addPool(address pool) internal {
        uint256 len = _state.poolList.length;
        for (uint256 i = 0; i < len; i++) {
            require(pool != _state.poolList[i], "Must not be added");
        }

        _state.pools[pool].flags = 0x1; // enable flag
        _state.poolList.push(pool);
    }

    function preClaimDollar(address pool) internal {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];
        require((poolInfo.flags & 0x1) == 0x1, "pool is disabled");

        if (user.bonded > 0) {
            uint256 pending = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                // Safe transfer to avoid resolution error.
                uint256 balance = dollar().balanceOf(address(this));
                if (pending > balance) {
                    pending = balance;
                }
                dollar().transfer(msg.sender, pending);

                emit Claim(msg.sender, pool, pending);
            }
        }
    }

    function postClaimDollar(address pool) internal {
        Storage.PoolInfo storage poolInfo = _state.pools[pool];
        Account.PoolState storage user = poolInfo.accounts[msg.sender];

        user.rewardDebt = user.bonded.mul(poolInfo.accDollarPerLP).div(1e18);
    }

    function _addLiquidity(address pool, address token, address anotherToken, uint256 amount) internal returns (uint256) {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        require(token == token0 || token == token1, "token must in pool");
        require(anotherToken == token0 || anotherToken == token1, "atoken must in pool");

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        (uint256 reserveToken, uint256 reserveAnother) = token == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 anotherAmount = UniswapV2Library.quote(amount, reserveToken, reserveAnother); // throw if reserve is zero

        IERC20(token).safeTransferFrom(msg.sender, pool, amount);
        IERC20(anotherToken).safeTransferFrom(msg.sender, pool, anotherAmount);
        return IUniswapV2Pair(pool).mint(address(this));
    }

    function _sellAndDepositCollateral(uint256 totalSellAmount, uint256 allReserve) internal {
        if (totalSellAmount == 0 || allReserve == 0) {
            return;
        }

        dollar().mint(address(this), totalSellAmount);
        uint256 len = _state.poolList.length;
        uint256 actualSold = 0;
        // Sell to pools according to their reserves
        for (uint256 i = 0; i < len; i++) {
            address pool = _state.poolList[i];
            address token0 = IUniswapV2Pair(pool).token0();
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pool).getReserves();

            uint256 reserveA = token0 == address(dollar()) ? reserve0 : reserve1;
            uint256 reserveB = token0 == address(dollar()) ? reserve1 : reserve0;

            uint256 sellAmount = totalSellAmount
                .mul(reserveA)
                .div(allReserve);
            actualSold = actualSold.add(sellAmount);

            if (reserveA == 0 || sellAmount == 0) {
                // The pool is not ready yet or insufficient lp in pool.
                continue;
            }

            uint256 assetAmount = UniswapV2Library.getAmountOut(
                sellAmount,
                reserveA,
                reserveB
            );

            dollar().transfer(pool, sellAmount);

            // Non-Reentrancy?
            IUniswapV2Pair(pool).swap(
                token0 == address(dollar()) ? 0 : assetAmount,
                token0 == address(dollar()) ? assetAmount : 0,
                address(this),
                new bytes(0)
            );
        }

        // Make sure we don't sell extra
        assert(actualSold <= totalSellAmount);
    }

    /**
     * Collateral
     */

    function _addCollateral(address asset) internal {
        uint256 len = _state.collateralAssetList.length;
        for (uint256 i = 0; i < len; i++) {
            require(asset != _state.collateralAssetList[i], "Must not be added");
        }

        _state.collateralAssetList.push(asset);
    }
}
