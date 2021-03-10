pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Distributor {
    using SafeMath for uint256;

    address public address0;
    address public address1;

    constructor(address addr0, address addr1) public {
        address0 = addr0;
        address1 = addr1;
    }

    function transfer(address token) public {
        uint256 bal = IERC20(token).balanceOf(address(this));
        uint256 bal0 = bal.div(4);
        uint256 bal1 = bal.sub(bal0);
        IERC20(token).transfer(address0, bal0);
        IERC20(token).transfer(address1, bal1);
    }
}