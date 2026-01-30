// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "openzeppelin/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Capped} from "openzeppelin/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

contract GIA is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Permit,
    ERC20Capped,
    Ownable
{
    constructor(
        uint256 initialSupply,
        uint256 maxSupply
    )
        ERC20("GIA Token", "GIA")
        ERC20Permit("GIA Token")
        ERC20Capped(maxSupply)
        Ownable()
    {
        require(initialSupply <= maxSupply, "Initial supply exceeds cap");
        _mint(msg.sender, initialSupply);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        REQUIRED OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(
        address account,
        uint256 amount
    )
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
