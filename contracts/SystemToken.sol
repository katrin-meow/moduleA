// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract SystemToken is ERC20 {
    constructor(address[] memory _initialUsers) ERC20("Professional", "PROFI") {
        uint totalSupply = 100000 * (10 ** decimals());
        uint valuePerPerson = totalSupply / _initialUsers.length;
        uint reminder = totalSupply % _initialUsers.length;
        for (uint i = 0; i < _initialUsers.length; i++) {
            _mint(_initialUsers[i], valuePerPerson);
        }
        if (reminder > 0) {
            _mint(_initialUsers[0], reminder);
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
