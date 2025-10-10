# ACT Token

Advanced ERC-20 token implementation with comprehensive features built using Foundry and OpenZeppelin Contracts.

## Features

- **ERC20 Standard**: Full ERC-20 compliance
- **Burnable**: Token holders can burn their own tokens
- **Mintable**: Owner can mint new tokens (with safe supply limits)
- **Pausable**: Owner can pause/unpause all token transfers
- **Voting/Governance**: Supports on-chain governance with vote delegation (ERC20Votes)
- **Checkpoints**: Built-in historical balance tracking via ERC20Votes
- **Ownable**: Owner-based access control
- **Permit (ERC-2612)**: Gasless approvals via off-chain signatures

## Token Details

- **Name**: ACT Token
- **Symbol**: ACT
- **Decimals**: 18
- **Initial Supply**: 1,000,000 tokens (configurable in deployment script)

## Setup

### 1. Install Dependencies

```bash
forge install
```

### 2. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and add your configuration:

```bash
# Private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here
# MNEMONIC="your twelve word seed phrase goes here if used instead of private key"

# RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key

# Etherscan API key for verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

**⚠️ IMPORTANT**: Never commit your `.env` file! It's already in `.gitignore`.

## Usage

### Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test contract
forge test --match-contract ACTTest

# Run with gas reporting
forge test --gas-report
```

### Build

```bash
forge build
```

### Deploy

**Important Notes:**
- **Token Configuration**: Pass token parameters as environment variables in the command:
  - `TOKEN_NAME` (default: "ACT Token")
  - `TOKEN_SYMBOL` (default: "ACT")
  - `INITIAL_SUPPLY` (default: 1000000)
- **Contract Verification**: Add `--verify` flag only if you have set `ETHERSCAN_API_KEY` in `.env`
- **Always source .env first**: Run `source .env` before deployment commands to load RPC URLs and mnemonics

### Local Deployment (Anvil)

```bash
# Terminal 1: Start local node
anvil

# Terminal 2: Deploy with default parameters
forge script script/ACT.s.sol --rpc-url anvil --broadcast

# Deploy with custom token parameters
TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 \
  forge script script/ACT.s.sol --rpc-url anvil --broadcast
```

### Testnet Deployment (Sepolia)

**Basic Deployment (without verification):**
```bash
source .env

# Deploy with default parameters (ACT Token, ACT, 1000000)
forge script script/ACT.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Deploy with custom token parameters
TOKEN_NAME="My Custom Token" TOKEN_SYMBOL="MCT" INITIAL_SUPPLY=5000000 \
  forge script script/ACT.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

**With Contract Verification (requires ETHERSCAN_API_KEY):**
```bash
source .env

# Deploy and verify with default parameters
forge script script/ACT.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Deploy and verify with custom parameters
TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 \
  forge script script/ACT.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

### Avalanche Fuji Testnet Deployment

**Basic Deployment (without verification):**
```bash
source .env

# Deploy with default parameters
forge script script/ACT.s.sol \
  --rpc-url fuji \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Deploy with custom token parameters
TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 \
  forge script script/ACT.s.sol \
  --rpc-url fuji \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

**With Contract Verification (using Blockscout):**
```bash
source .env

# Deploy and verify with default parameters
forge script script/ACT.s.sol \
  --rpc-url fuji \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://api.routescan.io/v2/network/testnet/evm/43113/etherscan \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Deploy and verify with custom parameters
TOKEN_NAME="My Token" TOKEN_SYMBOL="MTK" INITIAL_SUPPLY=5000000 \
  forge script script/ACT.s.sol \
  --rpc-url fuji \
  --broadcast \
  --verify \
  --verifier blockscout \
  --verifier-url https://api.routescan.io/v2/network/testnet/evm/43113/etherscan \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

**Note**: For Avalanche Fuji, you need testnet AVAX. Get it from the [Avalanche Faucet](https://faucet.avax.network/).

#### Quick Reference

| Network | RPC Alias | Faucet | Block Explorer |
|---------|-----------|--------|----------------|
| **Sepolia** | `sepolia` | [Sepolia Faucet](https://sepoliafaucet.com/) | [Etherscan](https://sepolia.etherscan.io/) |
| **Avalanche Fuji** | `fuji` | [Avalanche Faucet](https://faucet.avax.network/) | [SnowTrace](https://testnet.snowtrace.io/) |
| **Local Anvil** | `anvil` | N/A (built-in) | N/A |

### Interacting with the Contract

After deployment, you can interact with your deployed contract using Foundry's `cast` command-line tool.

**Understanding the parameters:**
- **`<TOKEN_ADDRESS>`**: The deployed contract address (you get this from the deployment output)
- **Specifying which account calls the function**: Use either:
  - `--private-key $PRIVATE_KEY` - Use a specific private key from .env
  - `--mnemonics "$MNEMONIC" --mnemonic-indexes 0` - Use mnemonic from .env (account at index 0)
- **Read operations** (`cast call`): Don't require an account, just query the blockchain
- **Write operations** (`cast send`): Require an account specification and will create a transaction

**Always source .env first:**
```bash
source .env
```

#### Understanding Output Decoding

**Important**: `cast call` returns raw ABI-encoded hex data from the blockchain. To get human-readable output, you need to decode it using one of these methods:

1. **Use `xargs cast abi-decode`** - Most reliable method for all types
2. **Use `xargs cast --to-ascii`** - Quick method for strings
3. **Use `cast --to-dec`** - Quick method for numbers (works directly with pipe)

#### Read Operations (No Account Required)

These commands query the contract state without creating transactions.

**Get Token Name (String)**

```bash
# Raw output (hex-encoded)
cast call <TOKEN_ADDRESS> "name()" --rpc-url sepolia
# Returns: 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000009414354...

# Decoded output (human-readable) - RECOMMENDED
cast call <TOKEN_ADDRESS> "name()" --rpc-url sepolia | xargs cast --to-ascii
# Returns: ACT Token

# Alternative: Using abi-decode for proper ABI decoding
cast call <TOKEN_ADDRESS> "name()" --rpc-url sepolia | xargs cast abi-decode "name()(string)"
# Returns: "ACT Token"
```

**Get Token Symbol (String)**

```bash
# Decoded output
cast call <TOKEN_ADDRESS> "symbol()" --rpc-url sepolia | xargs cast --to-ascii
# Returns: ACT
```

**Get Decimals (Number)**

```bash
# Decoded output - Quick method
cast call <TOKEN_ADDRESS> "decimals()" --rpc-url sepolia | cast --to-dec
# Returns: 18

# Alternative: Using abi-decode
cast call <TOKEN_ADDRESS> "decimals()" --rpc-url sepolia | xargs cast abi-decode "decimals()(uint8)"
# Returns: 18
```

**Get Total Supply (Number)**

```bash
# Get total supply in wei (decoded)
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url sepolia | cast --to-dec
# Returns: 1000000000000000000000000

# Convert to human-readable token amount
cast call <TOKEN_ADDRESS> "totalSupply()" --rpc-url sepolia | cast --from-wei
# Returns: 1000000.000000000000000000
```

**Check Balance of an Address (Number)**

```bash
# Get balance in wei
cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb --rpc-url sepolia | cast --to-dec

# Convert to human-readable token amount (RECOMMENDED)
cast call <TOKEN_ADDRESS> "balanceOf(address)(uint256)" 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb --rpc-url sepolia | cast --from-wei
# Returns balance in tokens (e.g., 1000.5)
```

**Check Contract Owner (Address)**

```bash
# Decoded output - returns checksummed address
cast call <TOKEN_ADDRESS> "owner()" --rpc-url sepolia | xargs cast abi-decode "owner()(address)"
# Returns: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
```

**Check if Contract is Paused (Boolean)**

```bash
# Decoded output
cast call <TOKEN_ADDRESS> "paused()" --rpc-url sepolia | xargs cast abi-decode "paused()(bool)"
# Returns: false (or true if paused)
```

**Get Voting Power of an Address (Number)**

```bash
# Get voting power in wei
cast call <TOKEN_ADDRESS> "getVotes(address)(uint256)" 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb --rpc-url sepolia | cast --to-dec

# Convert to human-readable token amount (RECOMMENDED)
cast call <TOKEN_ADDRESS> "getVotes(address)(uint256)" 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb --rpc-url sepolia | cast --from-wei
```

**Pro Tips for Read Operations:**

```bash
# Create shell aliases for convenience (add to ~/.bashrc or ~/.zshrc)
alias token-name='cast call $TOKEN_ADDRESS "name()" --rpc-url sepolia | xargs cast --to-ascii'
alias token-symbol='cast call $TOKEN_ADDRESS "symbol()" --rpc-url sepolia | xargs cast --to-ascii'
alias token-balance='cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $1 --rpc-url sepolia | cast --from-wei'
alias token-supply='cast call $TOKEN_ADDRESS "totalSupply()" --rpc-url sepolia | cast --from-wei'
alias token-owner='cast call $TOKEN_ADDRESS "owner()" --rpc-url sepolia | xargs cast abi-decode "owner()(address)"'

# Then use them like:
# export TOKEN_ADDRESS=0xYourTokenAddress
# token-name
# token-symbol
# token-balance 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
# token-supply
# token-owner
```

#### Write Operations (Require Account)

These commands create transactions and modify the contract state:

**Mint Tokens (Owner Only)**

```bash
# Using private key
cast send <TOKEN_ADDRESS> \
  "mint(address,uint256)" \
  0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
  1000000000000000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Using mnemonic
cast send <TOKEN_ADDRESS> \
  "mint(address,uint256)" \
  0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
  1000000000000000000000 \
  --rpc-url sepolia \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0

# Note: Amount is in wei (18 decimals)
# 1000000000000000000000 = 1000 tokens
```

**Pause Contract (Owner Only)**

```bash
# Pause all token transfers
cast send <TOKEN_ADDRESS> "pause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Unpause token transfers
cast send <TOKEN_ADDRESS> "unpause()" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

**Transfer Ownership (Owner Only)**

```bash
# Transfer ownership to a new address
cast send <TOKEN_ADDRESS> \
  "transferOwnership(address)" \
  0xNewOwnerAddress \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

**Burn Tokens (Any Token Holder)**

```bash
# Burn your own tokens
cast send <TOKEN_ADDRESS> \
  "burn(uint256)" \
  500000000000000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Note: 500000000000000000000 = 500 tokens
```

**Transfer Tokens (Any Token Holder)**

```bash
# Transfer tokens to another address
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
  1000000000000000000 \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Note: 1000000000000000000 = 1 token
```

**Delegate Voting Power (Any Token Holder)**

```bash
# Delegate your voting power to another address
cast send <TOKEN_ADDRESS> \
  "delegate(address)" \
  0xDelegateAddress \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY

# Self-delegate to activate checkpoints for your own address
cast send <TOKEN_ADDRESS> \
  "delegate(address)" \
  <YOUR_OWN_ADDRESS> \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

**Pro Tip - Token Amount Conversion:**

The token uses 18 decimals. To convert human-readable amounts to wei:
- 1 token = 1000000000000000000 (1 * 10^18)
- 100 tokens = 100000000000000000000 (100 * 10^18)
- 1000 tokens = 1000000000000000000000 (1000 * 10^18)

You can use `cast` to convert:
```bash
# Convert 1000 tokens to wei
cast --to-wei 1000

# Convert wei to ether (tokens)
cast --from-wei 1000000000000000000000
```

## Contract Functions

### Standard ERC20

- `transfer(address to, uint256 amount)` - Transfer tokens
- `approve(address spender, uint256 amount)` - Approve spending
- `transferFrom(address from, address to, uint256 amount)` - Transfer from approved address

### Owner Functions

- `mint(address to, uint256 amount)` - Mint new tokens
- `pause()` - Pause all token transfers
- `unpause()` - Unpause token transfers
- `transferOwnership(address newOwner)` - Transfer contract ownership
- `renounceOwnership()` - Renounce ownership (makes contract ownerless)

### Burnable Functions

- `burn(uint256 amount)` - Burn your own tokens
- `burnFrom(address account, uint256 amount)` - Burn tokens from approved account

### Voting Functions

- `delegate(address delegatee)` - Delegate voting power
- `getVotes(address account)` - Get current voting power
- `getPastVotes(address account, uint256 blockNumber)` - Get historical voting power
- `getPastTotalSupply(uint256 blockNumber)` - Get historical total supply

### Permit (Gasless Approvals)

- `permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)` - Approve via signature

## Important Notes

### ERC20Snapshot Removed

**Note**: ERC20Snapshot was removed in OpenZeppelin v5.x. This project uses **ERC20Votes** instead, which provides similar functionality through its checkpoint mechanism:

- Instead of `balanceOfAt(address, snapshotId)`, use `getPastVotes(address, blockNumber)`
- Instead of `totalSupplyAt(snapshotId)`, use `getPastTotalSupply(blockNumber)`
- **Important**: Users must call `delegate(address(this))` to self-delegate and activate checkpoints

### Supply Limits

ERC20Votes has a safe supply limit of `type(uint208).max` (~4.1e62) to prevent checkpoint overflow. This is still an astronomically large number for practical purposes.

## Security Considerations

1. **Private Key Management**: Never commit your `.env` file or share your private key
2. **Owner Privileges**: The contract owner has significant power (minting, pausing). Consider using a multisig or timelock
3. **Auditing**: This contract has not been audited. Use at your own risk.
4. **Testing**: Always test on testnet before mainnet deployment

## Project Structure

```
├── src/
│   └── ACT.sol             # ACT Token contract
├── script/
│   └── ACT.s.sol           # Deployment script
├── test/
│   ├── ACT.t.sol           # Comprehensive test suite
│   └── ACTBasic.t.sol      # Basic test suite
├── lib/                    # Dependencies
├── foundry.toml            # Foundry configuration
├── .env.example            # Example environment variables
└── README.md               # This file
```

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## License

MIT
