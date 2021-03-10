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
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../external/UniswapV2OracleLibrary.sol';
import '../external/UniswapV2Library.sol';
import "../external/Require.sol";
import "../external/Decimal.sol";
import "./IOracle.sol";
import "./IUSDC.sol";
import "../Constants.sol";

/* Only works for stablecoin at the monent */
contract Oracle is IOracle {
    struct PairData {
        uint256 _cumulative;
        uint256 _index;
        uint256 _reserve;
        uint256 _decMultiplier;
        uint32 _timestamp;
        bool _initialized;
    }

    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    bytes32 private constant FILE = "Oracle";

    mapping(address => PairData) _poolMap;
    address[] _poolList;
    address _dollar;
    address _owner;

    constructor(address dollar) public {
        _owner = msg.sender;
        _dollar = dollar;
    }

    /**
     * Owner
     */

    function addPool(address pool, uint256 decMultiplier) onlyOwner public {
        uint256 len = _poolList.length;
        for (uint256 i = 0; i < len; i++) {
            Require.that(
                pool != _poolList[i],
                FILE,
                "Must not in the pool"
            );
        }
        _poolList.push(pool);
        _poolMap[pool]._decMultiplier = decMultiplier;
    }

    function transferOwner(address newOwner) onlyOwner public {
        _owner = newOwner;
    }

    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture() public onlyOwner returns (Decimal.D256 memory, bool) {
        uint256 length = _poolList.length;
        uint256 totalReserve = 0;
        uint256 prevTotalReserve = 0;
        Decimal.D256 memory totalPriceRerseve = Decimal.zero();
        bool valid = false;
        for (uint256 i = 0; i < length; i++) {
            address pair = _poolList[i];
            if (_poolMap[pair]._initialized) {
                (
                    Decimal.D256 memory price,
                    uint256 prevReserve,
                    uint256 reserve,
                    bool valid0
                ) = updateOracleFor(IUniswapV2Pair(pair));
                if (valid0) {
                    totalReserve = totalReserve.add(reserve);
                    totalPriceRerseve = totalPriceRerseve.add(price.mul(reserve));
                    prevTotalReserve = prevTotalReserve.add(prevReserve);
                    valid = true;
                }
            } else {
                initializeOracleFor(IUniswapV2Pair(pair));
            }
        }

        if (valid && totalReserve >= Constants.getOracleReserveMinimum() && prevTotalReserve >= Constants.getOracleReserveMinimum()) {
            return (totalPriceRerseve.div(totalReserve), true);
        }

        return (Decimal.one(), false);
    }

    function getPrice() public view returns (Decimal.D256 memory, bool) {
        uint256 length = _poolList.length;
        uint256 totalReserve = 0;
        uint256 prevTotalReserve = 0;
        Decimal.D256 memory totalPriceRerseve = Decimal.zero();
        bool valid = false;
        for (uint256 i = 0; i < length; i++) {
            address pair = _poolList[i];
            if (_poolMap[pair]._initialized) {
                (
                    Decimal.D256 memory price,
                    ,
                    ,
                    uint256 reserve
                ) = getPriceFor(IUniswapV2Pair(pair));
                totalReserve = totalReserve.add(reserve);
                totalPriceRerseve = totalPriceRerseve.add(price.mul(reserve));
                prevTotalReserve = prevTotalReserve.add(_poolMap[pair]._reserve);
                valid = true;
            }
        }

        if (valid && totalReserve >= Constants.getOracleReserveMinimum() && prevTotalReserve >= Constants.getOracleReserveMinimum()) {
            return (totalPriceRerseve.div(totalReserve), true);
        }

        return (Decimal.one(), false);
    }

    function initializeOracleFor(IUniswapV2Pair pair) private {
        uint256 index = pair.token0() == address(_dollar) ? 0 : 1;
        uint256 priceCumulative = index == 0 ?
            pair.price0CumulativeLast() :
            pair.price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        if(reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            PairData storage data = _poolMap[address(pair)];
            data._cumulative = priceCumulative;
            data._timestamp = blockTimestampLast;
            data._initialized = true;
            data._reserve = index == 0 ? reserve0 : reserve1;
            data._index = index;
        }
    }

    function updateOracleFor(IUniswapV2Pair pair) private returns (Decimal.D256 memory, uint256, uint256, bool) {
        (Decimal.D256 memory price, uint32 blockTimestamp, uint256 priceCumulative, uint112 reserve) = getPriceFor(pair);

        PairData storage data = _poolMap[address(pair)];

        // Make sure the timestamp diff is large enough to avoid price manipulation.
        if (blockTimestamp <= Constants.getCurrentEpochStrategy().period.div(2).add(data._timestamp)) {
            return (Decimal.one(), 0, 0, false);
        }

        uint256 prevReserve = data._reserve;
        data._reserve = reserve;
        data._timestamp = blockTimestamp;
        data._cumulative = priceCumulative;

        return (price, prevReserve, reserve, true);
    }

    function getPriceFor(IUniswapV2Pair pair) private view returns (Decimal.D256 memory, uint32, uint256, uint112) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp, uint112 reserve0, uint112 reserve1) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        PairData storage data = _poolMap[address(pair)];

        uint32 timeElapsed = blockTimestamp - data._timestamp; // overflow is desired
        uint256 priceCumulative = data._index == 0 ? price0Cumulative : price1Cumulative;
        uint112 reserve = data._index == 0 ? reserve0 : reserve1;
        Decimal.D256 memory price = Decimal.ratio((priceCumulative - data._cumulative) / timeElapsed, 2**112);

        return (price.mul(data._decMultiplier), blockTimestamp, priceCumulative, reserve);
    }

    modifier onlyOwner() {
        Require.that(
            msg.sender == address(_owner),
            FILE,
            "Not owner"
        );

        _;
    }
}