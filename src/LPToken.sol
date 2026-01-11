//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Not authorized");
        _;
    }

    constructor() ERC20("LPToken", "LPT") {}

    function setMinter(address _minter) external {
        require(minter == address(0), "Minter already set");
        minter = _minter;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }
}
