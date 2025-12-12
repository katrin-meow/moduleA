// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract WrapToken is ERC20 {
    address public  owner;
    uint totalCap = 20000000 * (10 ** decimals());
    constructor() ERC20("RTKCoin", "RTK") {
        _mint(msg.sender, totalCap);
        owner = msg.sender;
    }
    function decimals() public pure override returns (uint8) {
        return 12;
    }
    
    //переопр функции чтобы не требовать апрувы
    function transferFrom(
        address from,
        address to,
        uint value
    ) public override returns (bool) {
        _transfer(from, to, value);
        return true;
    }
}
