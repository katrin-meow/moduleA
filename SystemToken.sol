// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
contract SystemToken is ERC20 {
    constructor(address[] memory initialUsers) ERC20("Professional", "PROFI") {
        uint totalCap = 100000 * (10 ** decimals());
        uint amountPerPerson = totalCap / initialUsers.length;
        uint reminder = totalCap % initialUsers.length; //расчет остатка

        for (uint i = 0; i < initialUsers.length; i++) {
            _mint(initialUsers[i], amountPerPerson);
        }
        if (reminder > 0) {
            _mint(initialUsers[0], reminder); //при наличии остатка заминтить его 1-ому юзеру
        }
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
