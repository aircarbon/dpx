// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

/**
 * @title ACT Token
 * @dev ERC-20 token implementation using UUPS proxy pattern with the following features:
 * - Burnable: Token holders can burn their own tokens
 * - Mintable: Owner can mint new tokens
 * - Pausable: Owner can pause all token transfers
 * - Votable: Supports governance voting with delegation (ERC20Votes)
 * - Checkpoints: ERC20Votes provides built-in checkpointing for historical balance queries
 * - Ownable: Contract has an owner with special privileges
 * - Permit: Supports gasless approvals via EIP-2612
 * - UUPS Upgradeable: Owner can upgrade the implementation
 *
 * IMPORTANT: This contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern.
 * After deployment, you can upgrade the implementation by calling upgradeToAndCall()
 * (only the owner can perform upgrades).
 *
 * WARNING: Storage layout must be preserved across upgrades. Never:
 * - Change the order of state variables
 * - Change the type of state variables
 * - Remove state variables
 * - Add new state variables before existing ones
 * Always add new state variables at the end or use the __gap array.
 */
contract ACT is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the token contract (replaces constructor for upgradeable contracts)
     * @param name The name of the token (e.g., "ACT Token")
     * @param symbol The symbol of the token (e.g., "ACT")
     * @param initialSupply The initial supply of tokens to mint to the deployer
     *
     * NOTE: This function can only be called once during proxy deployment
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(msg.sender);
        __ERC20Permit_init(name);
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

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
     * @dev Function that authorizes an upgrade to a new implementation
     * Only callable by the owner
     * @param newImplementation Address of the new implementation contract
     *
     * IMPORTANT: This function is called by the UUPS proxy before upgrading.
     * By requiring onlyOwner, we ensure only the contract owner can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Hook that is called before any token transfer
     * Overrides required by multiple inherited contracts
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable)
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
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    /**
     * @dev Storage gap for future upgrades
     * This empty reserved space allows us to add new state variables in future upgrades
     * without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
