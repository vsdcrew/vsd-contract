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
import "./Curve.sol";
import "./Comptroller.sol";
import "../Constants.sol";

contract Market is Comptroller, Curve {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Market";

    event CouponRedemption(uint256 indexed epoch, uint256 couponRedeemed, uint256 vsdRedeemable);
    event CouponPurchase(address indexed account, uint256 indexed epochExpire, uint256 dollarAmount, uint256 couponAmount);
    event CouponClip(address indexed account, uint256 indexed epoch, uint256 couponAmount);
    event CouponTransfer(address indexed from, address indexed to, uint256 indexed epoch, uint256 value);
    event CouponApproval(address indexed owner, address indexed spender, uint256 value);
    event CouponExtended(address indexed owner, uint256 indexed epoch, uint256 couponAmount, uint256 newCouponAmount, uint256 newExpiration);

    function step() internal {
        // Automatically redeem prior coupons
        redeemCouponsForEpoch(epoch());
    }

    function redeemCouponsForEpoch(uint256 epoch) private {
        (uint256 couponRedeemed, uint256 vsdRedeemable) = redeemOutstandingCoupons(epoch);

        redeemToClippable(vsdRedeemable);

        emit CouponRedemption(epoch, couponRedeemed, vsdRedeemable);
    }

    function couponPremium(uint256 amount) public view returns (uint256) {
        return calculateCouponPremium(dollar().totalSupply(), totalDebt(), amount);
    }

    function purchaseCoupons(uint256 dollarAmount) external returns (uint256) {
        Require.that(
            dollarAmount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        Require.that(
            totalDebt() >= dollarAmount,
            FILE,
            "Not enough debt"
        );

        uint256 epoch = epoch();
        uint256 couponAmount = dollarAmount.add(couponPremium(dollarAmount));
        burnFromAccount(msg.sender, dollarAmount);
        incrementBalanceOfCoupons(msg.sender, epoch.add(Constants.getCouponExpiration()), couponAmount);

        emit CouponPurchase(msg.sender, epoch.add(Constants.getCouponExpiration()), dollarAmount, couponAmount);

        return couponAmount;
    }

    /*
     * @dev Extend the expiration of a coupon by VSDs.
     */
    function extendCoupon(uint256 couponExpireEpoch, uint256 couponAmount, uint256 dollarAmount) external {
        Require.that(
            dollarAmount > 0,
            FILE,
            "Must purchase non-zero amount"
        );

        uint256 epoch = epoch();

        decrementBalanceOfCoupons(msg.sender, couponExpireEpoch, couponAmount);
        uint256 liveness = couponAmount.mul(couponExpireEpoch.sub(epoch));

        uint256 debtAmount = totalDebt();
        if (debtAmount > dollarAmount) {
            debtAmount = dollarAmount;
        }
        burnFromAccountForDebt(msg.sender, dollarAmount, debtAmount);

        liveness = liveness.add(dollarAmount.mul(Constants.getCouponExpiration()));

        uint256 newExpiration = liveness.div(couponAmount).add(epoch);
        Require.that(
            newExpiration > epoch,
            FILE,
            "Must new exp. > current epoch"
        );

        incrementBalanceOfCoupons(msg.sender, newExpiration, couponAmount);
        emit CouponExtended(msg.sender, couponExpireEpoch, couponAmount, couponAmount, newExpiration);
    }

    function clipCoupons(uint256 couponExpireEpoch) external {
        Require.that(
            outstandingCoupons(couponExpireEpoch) == 0,
            FILE,
            "Coupon is not redeemed"
        );
        uint256 vsdAmount = clipRedeemedCoupon(msg.sender, couponExpireEpoch);
        clipToAccount(msg.sender, vsdAmount);

        emit CouponClip(msg.sender, couponExpireEpoch, vsdAmount);
    }

    function approveCoupons(address spender, uint256 amount) external {
        Require.that(
            spender != address(0),
            FILE,
            "Coupon approve to 0x0"
        );

        updateAllowanceCoupons(msg.sender, spender, amount);

        emit CouponApproval(msg.sender, spender, amount);
    }

    function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external {
        Require.that(
            sender != address(0),
            FILE,
            "Coupon transfer from 0x0"
        );
        Require.that(
            recipient != address(0),
            FILE,
            "Coupon transfer to 0x0"
        );

        decrementBalanceOfCoupons(sender, epoch, amount);
        incrementBalanceOfCoupons(recipient, epoch, amount);

        if (msg.sender != sender && allowanceCoupons(sender, msg.sender) != uint256(-1)) {
            decrementAllowanceCoupons(sender, msg.sender, amount);
        }

        emit CouponTransfer(sender, recipient, epoch, amount);
    }
}
