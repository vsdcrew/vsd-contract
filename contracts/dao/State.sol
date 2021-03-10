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

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../token/IDollar.sol";
import "../oracle/IOracle.sol";
import "../external/Decimal.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 lockedUntil;

        mapping(uint256 => uint256) coupons;
        mapping(address => uint256) couponAllowances;
    }

    struct PoolState {
        uint256 staged;
        uint256 bonded;
        uint256 fluidUntil;
        uint256 rewardDebt;
        uint256 shareDebt;
    }
}

contract Epoch {
    struct Global {
        uint256 start;
        uint256 period;
        uint256 current;
    }

    struct Coupons {
        uint256 outstanding;
        uint256 couponRedeemed;
        uint256 vsdRedeemable;
    }

    struct State {
        uint256 totalDollarSupply;
        Coupons coupons;
    }
}

contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct VoteInfo {
        Vote vote;
        uint256 bondedVotes;
    }

    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => VoteInfo) votes;
        bool initialized;
    }
}

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
    }

    struct Balance {
        uint256 redeemable;
        uint256 clippable;
        uint256 debt;
        uint256 coupons;
    }

    struct PoolInfo {
        uint256 bonded;
        uint256 staged;
        mapping (address => Account.PoolState) accounts;
        uint256 accDollarPerLP; // Accumulated dollar per LP token, times 1e18.
        uint256 accSharePerLP; // Accumulated share per LP token, times 1e18.
        uint256 allocPoint;
        uint256 flags;
    }

    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;

        /*
         * Global state variable
         */
        uint256 totalAllocPoint;
        uint256 collateralRatio;

        mapping(uint256 => Epoch.State) epochs;
        mapping(uint256 => Candidate.State) candidates;
        mapping(address => Account.State) accounts;

        mapping(address => PoolInfo) pools;
        address[] poolList;

        address[] collateralAssetList;
    }
}

contract State {
    Storage.State _state;
}
