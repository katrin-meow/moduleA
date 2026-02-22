// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SystemToken is ERC20 {
    uint constant totalCap = 100000;

    constructor(address[] memory _initialUsers) ERC20("Professional", "PROFI") {
        uint valluePerPers = (totalCap * (10 ** decimals())) /
            _initialUsers.length;
        uint reminder = (totalCap * (10 ** decimals())) % _initialUsers.length;

        for (uint i = 0; i < _initialUsers.length; i++) {
            _mint(_initialUsers[i], valluePerPers);
            if (reminder > 0) {
                _mint(_initialUsers[0], reminder);
            }
        }
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) public override returns (bool) {
        _transfer(_from, _to, _value);
        return true;
    }
}
