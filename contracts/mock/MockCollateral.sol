/*
    Copyright 2020 vsdcrew <vsdcrew@protonmail.com>
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

import "../dao/Collateral.sol";
import "../token/Dollar.sol";
import "./MockComptroller.sol";

contract MockCollateral is Collateral, MockComptroller {
    address private _usdc;
    address private _dai;

    constructor(address usdc, address dai) public {
        _state.provider.dollar = new Dollar();
        _usdc = usdc;
        _dai = dai;
    }

    function getSellAndReturnAmount(uint256 price, uint256 targetPrice, uint256 reserve) public pure returns (uint256 shouldSell, uint256 shouldMint) {
        return _getSellAndReturnAmount(price, targetPrice, reserve);
    }

    function getBuyAmount(uint256 price, uint256 targetPrice, uint256 reserve) public pure returns (uint256 shouldBuy) {
        return _getBuyAmount(price, targetPrice, reserve);
    }

    function usdc() public view returns (address) {
        return _usdc;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function addCollateralE(address asset) public {
        _addCollateral(asset);
    }

    function updateReserveE() public {
        _updateReserve();
    }

    function sellAndDepositCollateralE(uint256 totalSellAmount, uint256 allReserve) public {
        _sellAndDepositCollateral(totalSellAmount, allReserve);
    }

    function _getMinterAddress() internal view returns (address) {
        return msg.sender; // anyone
    }
}
