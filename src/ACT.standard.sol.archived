// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title ACT Token
 * @dev Advanced ERC-20 token implementation with the following features:
 * - Burnable: Token holders can burn their own tokens
 * - Mintable: Owner can mint new tokens
 * - Pausable: Owner can pause all token transfers
 * - Votable: Supports governance voting with delegation (ERC20Votes)
 * - Checkpoints: ERC20Votes provides built-in checkpointing for historical balance queries
 * - Ownable: Contract has an owner with special privileges
 * - Permit: Supports gasless approvals via EIP-2612
 *
 * NOTE: ERC20Snapshot was removed in OpenZeppelin v5.x. ERC20Votes provides similar
 * functionality through its checkpoint mechanism. You can query past votes using
 * getPastVotes(account, blockNumber) and getPastTotalSupply(blockNumber).
 */
contract ACT is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    Ownable,
    ERC20Permit,
    ERC20Votes
{
    /**
     * @dev Constructor that sets up the token with all features
     * @param name The name of the token (e.g., "My Token")
     * @param symbol The symbol of the token (e.g., "MTK")
     * @param initialSupply The initial supply of tokens to mint to the deployer
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC20(name, symbol)
        Ownable(msg.sender)
        ERC20Permit(name)
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mints new tokens to a specified address
     * Only callable by the owner
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers
     * Only callable by the owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     * Only callable by the owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any token transfer
     * Overrides required by multiple inherited contracts
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /**
     * @dev Returns the current nonce for an address
     * Overrides required by ERC20Permit and Nonces
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
