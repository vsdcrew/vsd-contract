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
import "./Setters.sol";
import "./Permission.sol";
import "../external/Require.sol";
import "../Constants.sol";

contract Bonding is Setters, Permission {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Bonding";

    event Deposit(address indexed pool, address indexed account, uint256 value);
    event Withdraw(address indexed pool, address indexed account, uint256 value);
    event Bond(address indexed pool, address indexed account, uint256 start, uint256 value);
    event Unbond(address indexed pool, address indexed account, uint256 start, uint256 value);

    function step() internal {
        Require.that(
            epochTime() > epoch(),
            FILE,
            "Still current epoch"
        );

        snapshotDollarTotalSupply();
        incrementEpoch();
    }

    function addPool(address pool) external {
        Require.that(
            msg.sender == address(this),
            FILE,
            "Must from governance"
        );

        _addPool(pool);
    }

    function claim(address pool) external {
        preClaimDollar(pool);
        postClaimDollar(pool);
    }

    function deposit(address pool, uint256 value) external {
        IERC20(pool).transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(pool, msg.sender, value);

        emit Deposit(pool, msg.sender, value);
    }

    function withdraw(address pool, uint256 value) external onlyFrozen(pool, msg.sender) {
        IERC20(pool).transfer(msg.sender, value);
        decrementBalanceOfStaged(pool, msg.sender, value);

        emit Withdraw(pool, msg.sender, value);
    }

    function bond(address pool, uint256 value) external {
        preClaimDollar(pool);
        unfreeze(pool, msg.sender);

        incrementBalanceOfBonded(pool, msg.sender, value);
        decrementBalanceOfStaged(pool, msg.sender, value);

        emit Bond(pool, msg.sender, epoch().add(1), value);
        postClaimDollar(pool);
    }

    function unbond(address pool, uint256 value) external onlyFrozenOrFluid(pool, msg.sender) {
        preClaimDollar(pool);
        unfreeze(pool, msg.sender);

        incrementBalanceOfStaged(pool, msg.sender, value);
        decrementBalanceOfBonded(pool, msg.sender, value);

        emit Unbond(pool, msg.sender, epoch().add(1), value);
        postClaimDollar(pool);
    }

    function provide(address pool, address token, address another, uint256 amount) external {
        preClaimDollar(pool);

        unfreeze(pool, msg.sender);

        uint256 bondedLP = _addLiquidity(pool, token, another, amount);
        incrementBalanceOfBonded(pool, msg.sender, bondedLP);

        emit Bond(pool, msg.sender, epoch().add(1), bondedLP);
        postClaimDollar(pool);
    }
}
