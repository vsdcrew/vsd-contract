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

import "../dao/Setters.sol";

contract MockState is Setters {
    uint256 internal _blockTimestamp;

    constructor () public {
        _blockTimestamp = block.timestamp;
    }

    /**
     * Global
     */

    function incrementTotalDebtE(uint256 amount) external {
        super.incrementTotalDebt(amount);
    }

    function decrementTotalDebtE(uint256 amount, string calldata reason) external {
        super.decrementTotalDebt(amount);
    }

    function incrementTotalRedeemableE(uint256 amount) external {
        super.incrementTotalRedeemable(amount);
    }

    function decrementTotalRedeemableE(uint256 amount, string calldata reason) external {
        super.decrementTotalRedeemable(amount);
    }

    /**
     * Account
     */

    function incrementBalanceOfBondedE(address pool, address account, uint256 amount) external {
        super.incrementBalanceOfBonded(pool, account, amount);
    }

    function decrementBalanceOfBondedE(address pool, address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfBonded(pool, account, amount);
    }

    function incrementBalanceOfStagedE(address pool, address account, uint256 amount) external {
        super.incrementBalanceOfStaged(pool, account, amount);
    }

    function decrementBalanceOfStagedE(address pool, address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfStaged(pool, account, amount);
    }

    function incrementBalanceOfCouponsE(address account, uint256 epoch, uint256 amount) external {
        super.incrementBalanceOfCoupons(account, epoch, amount);
    }

    function decrementBalanceOfCouponsE(address account, uint256 epoch, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfCoupons(account, epoch, amount);
    }

    function unfreezeE(address pool, address account) external {
        super.unfreeze(pool, account);
    }

    function updateAllowanceCouponsE(address owner, address spender, uint256 amount) external {
        super.updateAllowanceCoupons(owner, spender, amount);
    }

    function decrementAllowanceCouponsE(address owner, address spender, uint256 amount, string calldata reason) external {
        super.decrementAllowanceCoupons(owner, spender, amount);
    }

    /**
     * Epoch
     */

    function setEpochParamsE(uint256 start, uint256 period) external {
        _state.epoch.start = start;
        _state.epoch.period = period;
    }

    function incrementEpochE() external {
        super.incrementEpoch();
    }

    function redeemOutstandingCouponsE(uint256 epoch) external {
       super.redeemOutstandingCoupons(epoch);
    }

    /**
     * Governance
     */

    function createCandidateE(uint256 candidate, uint256 period) external {
        super.createCandidate(candidate, period);
    }

    function recordVoteInfoE(address account, uint256 candidate, Candidate.VoteInfo calldata voteInfo) external {
        super.recordVoteInfo(account, candidate, voteInfo);
    }

    function incrementApproveForE(uint256 candidate, uint256 amount) external {
        super.incrementApproveFor(candidate, amount);
    }

    function decrementApproveForE(uint256 candidate, uint256 amount, string calldata reason) external {
        super.decrementApproveFor(candidate, amount);
    }

    function incrementRejectForE(uint256 candidate, uint256 amount) external {
        super.incrementRejectFor(candidate, amount);
    }

    function decrementRejectForE(uint256 candidate, uint256 amount, string calldata reason) external {
        super.decrementRejectFor(candidate, amount);
    }

    function placeLockE(address account, uint256 candidate) external {
        super.placeLock(account, candidate);
    }

    function initializedE(uint256 candidate) external {
        super.initialized(candidate);
    }

    /**
     * Mock
     */

    function setBlockTimestamp(uint256 timestamp) external {
        _blockTimestamp = timestamp;
    }

    function blockTimestamp() internal view returns (uint256) {
        return _blockTimestamp;
    }
}
