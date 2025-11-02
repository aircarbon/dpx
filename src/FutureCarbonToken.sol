// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FutureCarbonToken
 * @dev ERC-20 token representing future carbon credits for a specific project.
 *
 * This token is deployed by the RegistryFactory when a project is approved.
 * Each project gets its own immutable token contract (non-upgradeable).
 *
 * Features:
 * - Standard ERC-20: transfer, approve, allowance functionality
 * - ERC20Permit: Gasless approvals via EIP-2612 signatures
 * - Burnable: Tokens can be burned (required for redemption via RedemptionVault)
 * - Pausable: Emergency stop for transfers
 * - Mintable: Owner can mint tokens (typically only at deployment)
 * - 18 decimals: Standard ERC-20 precision
 *
 * Lifecycle:
 * 1. Deployed by RegistryFactory upon project approval
 * 2. Initial supply minted to owner (company address)
 * 3. Tokens traded on exchange
 * 4. When project completes, tokens redeemed via RedemptionVault (burned)
 *
 * IMPORTANT: This contract is NOT upgradeable. Once deployed, its behavior
 * is immutable, providing predictability and security for token holders.
 */
contract FutureCarbonToken is ERC20, ERC20Permit, ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev Constructor initializes the token with project details
     * @param name The name of the token (e.g., "Future Carbon Credit - Project Alpha")
     * @param symbol The symbol of the token (e.g., "FCC-ALPHA")
     * @param initialSupply The initial supply of tokens to mint (with 18 decimals)
     * @param owner The owner address (typically company multisig wallet)
     *
     * NOTE: The initial supply is minted to the owner address during deployment
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(owner) {
        require(owner != address(0), "Owner cannot be zero address");
        require(initialSupply > 0, "Initial supply must be greater than 0");

        _mint(owner, initialSupply);
    }

    /**
     * @dev Mints new tokens to a specified address
     * Only callable by the owner (company multisig)
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint (with 18 decimals)
     *
     * NOTE: This function is typically only used if additional tokens need
     * to be minted after deployment (e.g., if project scope increases)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");

        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers
     * Only callable by the owner
     *
     * This is an emergency function that prevents all transfers, mints, and burns.
     * Use in case of security issues or when project needs to be frozen.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     * Only callable by the owner
     *
     * Resumes normal token operations after a pause.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any token transfer
     * Required override for multiple inheritance (ERC20 and ERC20Pausable)
     *
     * This function ensures that pause checks are performed before transfers.
     * The super._update() call chains through ERC20Pausable to ERC20.
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
