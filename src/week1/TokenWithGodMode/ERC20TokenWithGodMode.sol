// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20TokenWithGodMode
/// @author kovalgek
/// @notice ERC20 token with `god` transfer method.
contract ERC20TokenWithGodMode is ERC20, Ownable {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /// @notice Mints tokens
    /// @param _account an address tokens minted for
    /// @param _value amount of minted tokens
    function mint(address _account, uint256 _value) external onlyOwner {
        _mint(_account, _value);
    }

    /// @notice Burns tokens
    /// @param _account an address tokens burned for
    /// @param _value amount of burned tokens
    function burn(address _account, uint256 _value) external onlyOwner {
        _burn(_account, _value);
    }

    /// @notice Moves a `value` amount of tokens from `from` to `to` not using the allowance mechanism.
    /// @param _from an address tokens moves from
    /// @param _to an address tokens moves to
    /// @param _value amount of moved tokens
    function godTransferFrom(address _from, address _to, uint256 _value) external onlyOwner {
        _transfer(_from, _to, _value);
    }
}
