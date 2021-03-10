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

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 84;

    /* Oracle */
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 VSD
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START = 1612324800;
    uint256 private constant CURRENT_EPOCH_PERIOD = 28800;

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 9; // 9 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 2; // 2 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 10e16; // 10%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 VSD
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 15; // 15 epochs fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 30; // 10 days
    uint256 private constant DEBT_RATIO_CAP = 15e16; // 15%

    /* Regulator */
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 6e16; // 6%
    uint256 private constant SUPPLY_INCREASE_FUND_RATIO = 1500; // 15%
    uint256 private constant SUPPLY_INCREASE_PRICE_THRESHOLD = 105e16; // 1.05
    uint256 private constant SUPPLY_INCREASE_PRICE_TARGET = 105e16; // 1.05
    uint256 private constant SUPPLY_DECREASE_PRICE_THRESHOLD = 95e16; // 0.95
    uint256 private constant SUPPLY_DECREASE_PRICE_TARGET = 95e16; // 0.95

    /* Collateral */
    uint256 private constant REDEMPTION_RATE = 9500; // 95%
    uint256 private constant FUND_DEV_PCT = 70; // 70%
    uint256 private constant COLLATERAL_RATIO = 9000; // 90%

    /* Deployed */
    address private constant TREASURY_ADDRESS = address(0x3a640b96405eCB10782C130022e1E5a560EBcf11);
    address private constant DEV_ADDRESS = address(0x5bC47D40F69962d1a9Db65aC88f4b83537AF5Dc2);
    address private constant MINTER_ADDRESS = address(0x6Ff1DbcF2996D8960E24F16C193EA42853995d32);
    address private constant GOVERNOR = address(0xB64A5630283CCBe0C3cbF887a9f7B9154aEf38c3);

    /**
     * Getters
     */

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getDaiAddress() internal pure returns (address) {
        return DAI;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getCurrentEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: CURRENT_EPOCH_OFFSET,
            start: CURRENT_EPOCH_START,
            period: CURRENT_EPOCH_PERIOD
        });
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyIncreaseFundRatio() internal pure returns (uint256) {
        return SUPPLY_INCREASE_FUND_RATIO;
    }

    function getSupplyIncreasePriceThreshold() internal pure returns (uint256) {
        return SUPPLY_INCREASE_PRICE_THRESHOLD;
    }

    function getSupplyIncreasePriceTarget() internal pure returns (uint256) {
        return SUPPLY_INCREASE_PRICE_TARGET;
    }

    function getSupplyDecreasePriceThreshold() internal pure returns (uint256) {
        return SUPPLY_DECREASE_PRICE_THRESHOLD;
    }

    function getSupplyDecreasePriceTarget() internal pure returns (uint256) {
        return SUPPLY_DECREASE_PRICE_TARGET;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getDevAddress() internal pure returns (address) {
        return DEV_ADDRESS;
    }

    function getMinterAddress() internal pure returns (address) {
        return MINTER_ADDRESS;
    }

    function getFundDevPct() internal pure returns (uint256) {
        return FUND_DEV_PCT;
    }

    function getRedemptionRate() internal pure returns (uint256) {
        return REDEMPTION_RATE;
    }

    function getGovernor() internal pure returns (address) {
        return GOVERNOR;
    }

    function getCollateralRatio() internal pure returns (uint256) {
        return COLLATERAL_RATIO;
    }
}
