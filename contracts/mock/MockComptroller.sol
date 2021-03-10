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

import "../dao/Comptroller.sol";
import "../token/Dollar.sol";
import "./MockState.sol";

contract MockComptroller is Comptroller, MockState {
    uint256 private _collateralRatio = 10000;

    constructor() public {
        _state.provider.dollar = new Dollar();
    }

    function mintToAccountE(address account, uint256 amount) external {
        super.mintToAccount(account, amount);
    }

    function burnFromAccountE(address account, uint256 amount) external {
        super.burnFromAccount(account, amount);
    }

    function clipToAccountE(address account, uint256 amount) external {
        super.clipToAccount(account, amount);
    }

    function redeemToClippableE(uint256 amount) external {
        super.redeemToClippable(amount);
    }

    function increaseDebtE(uint256 amount) external {
        super.increaseDebt(amount);
    }

    function decreaseDebtE(uint256 amount) external {
        super.decreaseDebt(amount);
    }

    function resetDebtE(uint256 percent) external {
        super.resetDebt(Decimal.ratio(percent, 100));
    }

    function incrementBalanceOfBondedE(address pool, uint256 amount) external {
        super.incrementBalanceOfBonded(pool, msg.sender, amount);
    }

    function decrementBalanceOfBondedE(address pool, uint256 amount) external {
        super.decrementBalanceOfBonded(pool, msg.sender, amount);
    }

    /* For testing only */
    function mintToE(address account, uint256 amount) external {
        dollar().mint(account, amount);
    }

    function addPoolE(address pool) external {
        _addPool(pool);
    }

    function getCollateralRatio() internal view returns (uint256) {
        return _collateralRatio;
    }

    function setCollateralRatio(uint256 ratio) public returns (uint256) {
        _collateralRatio = ratio;
    }
}
