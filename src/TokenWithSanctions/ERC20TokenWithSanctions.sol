// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @author kovalgek
contract ERC20TokenWithSanctions is ERC20, Ownable {

    mapping(address => bool) private _banned;

    event AddressBanned(address indexed account);
    event AddressUnbanned(address indexed account);

    error ErrorSenderBanned(address);
    error ErrorRecipientBanned(address);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /// @notice Bans provided address making it impossible to transfer or receive tokens.
    /// @param account Address who will be banned
    function banAddress(address account) external onlyOwner {
        _banned[account] = true;
        emit AddressBanned(account);
    }

    /// @notice Unbans provided address making it possible to transfer or receive tokens.
    /// @param account Address who will be unbanned
    function unbanAddress(address account) external onlyOwner {
        _banned[account] = false;
        emit AddressUnbanned(account);
    }

    /// @notice Checkes if account is banned to send or receive tokens.
    /// @param account Address who will tested
    function isBanned(address account) external view returns (bool) {
        return _banned[account];
    }

    /// @notice Mints tokens
    /// @param account an address tokens minted for
    /// @param value amount of minted tokens
    function mint(address account, uint256 value) external onlyOwner {
        _mint(account, value);
    }

    /// @notice Burns tokens
    /// @param account an address tokens burned for
    /// @param value amount of burned tokens
    function burn(address account, uint256 value) external onlyOwner {
        _burn(account, value);
    }
    
    /// @inheritdoc ERC20
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_banned[_msgSender()]) revert ErrorSenderBanned(_msgSender());
        if (_banned[recipient]) revert ErrorRecipientBanned(recipient);
        return super.transfer(recipient, amount);
    }

    /// @inheritdoc ERC20
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (_banned[from]) revert ErrorSenderBanned(from);
        if (_banned[to]) revert ErrorRecipientBanned(to);
        return super.transferFrom(from, to, value);
    }
}
