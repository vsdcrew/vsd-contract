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
import "../oracle/Oracle.sol";
import "../external/Decimal.sol";

contract MockOracle is Oracle {
    Decimal.D256 private _latestPrice;
    bool private _latestValid;

    constructor (address dollar) Oracle(dollar) public {
    }

    function capture() public returns (Decimal.D256 memory, bool) {
        (_latestPrice, _latestValid) = super.capture();
        return (_latestPrice, _latestValid);
    }

    function latestPrice() external view returns (Decimal.D256 memory) {
        return _latestPrice;
    }

    function latestValid() external view returns (bool) {
        return _latestValid;
    }

    function isInitialized(address pool) external view returns (bool) {
        return _poolMap[pool]._initialized;
    }

    function cumulative(address pool) external view returns (uint256) {
        return _poolMap[pool]._cumulative;
    }

    function timestamp(address pool) external view returns (uint256) {
        return _poolMap[pool]._timestamp;
    }

    function reserve(address pool) external view returns (uint256) {
        return _poolMap[pool]._reserve;
    }
}
