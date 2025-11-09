## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
# AIRDROPTOKEN (ADT)

A Solidity-based ERC20 token with built-in airdrop functionality, developed using the Foundry framework. This smart contract enables both user-initiated claims and owner-managed batch airdrops with tracking to prevent duplicate claims.

## Features

- **ERC20 Standard Compliance**: Built on OpenZeppelin's battle-tested ERC20 implementation
- **Self-Service Airdrop Claims**: Users can claim their airdrop tokens directly
- **Batch Airdrop Distribution**: Owner can distribute tokens to multiple addresses efficiently
- **Duplicate Prevention**: Robust tracking system prevents multiple claims per address
- **Toggleable Airdrop**: Owner can activate/deactivate the airdrop campaign
- **Owner Minting**: Additional tokens can be minted as needed
- **Comprehensive Events**: Full event logging for transparency and tracking

## Token Details

- **Name**: AIRDROPTOKEN
- **Symbol**: ADT
- **Decimals**: 18
- **Airdrop Amount**: 100 ADT per claim

## Smart Contract Functions

### Public Functions

#### `claimAirdrop()`
Allows users to claim their airdrop tokens. Each address can only claim once.

```solidity
function claimAirdrop() external
```

**Requirements:**
- Airdrop must be active
- Address must not have claimed previously

#### `hasClaimedAirdropView(address account)`
Check if an address has already claimed their airdrop.

```solidity
function hasClaimedAirdropView(address account) external view returns (bool)
```

### Owner Functions

#### `batchAirdrop(address[] calldata recipients)`
Distribute tokens to multiple addresses in a single transaction.

```solidity
function batchAirdrop(address[] calldata recipients) external onlyOwner
```

**Parameters:**
- `recipients`: Array of addresses to receive airdrop

**Features:**
- Skips addresses that have already claimed
- Emits individual `AirdropClaimed` events for each recipient
- Emits `BatchAirdropCompleted` event with summary

#### `setAirdropActive(bool active)`
Toggle the airdrop campaign status.

```solidity
function setAirdropActive(bool active) external onlyOwner
```

#### `mint(address to, uint256 amount)`
Mint additional tokens to a specified address.

```solidity
function mint(address to, uint256 amount) external onlyOwner
```

## Development Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd airdroptoken
```

2. Install dependencies:
```bash
forge install
```

This will install:
- `forge-std` (v1.11.0)
- `openzeppelin-contracts` (v5.4.0)

### Build

Compile the smart contracts:
```bash
forge build
```

### Test

Run the comprehensive test suite:
```bash
forge test
```

For detailed test output:
```bash
forge test -vvv
```

For gas reports:
```bash
forge test --gas-report
```

### Code Formatting

Check code formatting:
```bash
forge fmt --check
```

Apply formatting:
```bash
forge fmt
```

## Deployment

### Local Deployment (Anvil)

1. Start a local Ethereum node:
```bash
anvil
```

2. Deploy the contract:
```bash
forge script script/DeployScript.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key <anvil-private-key> --broadcast
```

### Testnet/Mainnet Deployment

1. Set up your environment variables in `.env`:
```bash
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. Deploy:
```bash
forge script script/DeployScript.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## Usage Examples

### Claiming an Airdrop

```solidity
// User claims their airdrop
airdropToken.claimAirdrop();
```

### Batch Airdrop Distribution

```solidity
// Owner distributes to multiple addresses
address[] memory recipients = new address[](3);
recipients[0] = 0x123...;
recipients[1] = 0x456...;
recipients[2] = 0x789...;

airdropToken.batchAirdrop(recipients);
```

### Checking Claim Status

```solidity
bool hasClaimed = airdropToken.hasClaimedAirdropView(userAddress);
```

### Toggling Airdrop Status

```solidity
// Deactivate airdrop
airdropToken.setAirdropActive(false);

// Reactivate airdrop
airdropToken.setAirdropActive(true);
```

## Testing

The project includes a comprehensive test suite covering:

- ✅ Initial contract state verification
- ✅ Successful airdrop claims
- ✅ Duplicate claim prevention
- ✅ Airdrop activation/deactivation
- ✅ Batch airdrop functionality
- ✅ Owner-only function restrictions
- ✅ Token transfers
- ✅ Total supply tracking

Run tests with:
```bash
forge test -vv
```

## Events

The contract emits the following events:

```solidity
event AirdropClaimed(address indexed recipient, uint256 amount);
event AirdropStatusChanged(bool active);
event BatchAirdropCompleted(uint256 recipientCount, uint256 totalAmount);
```

## Security Considerations

- Contract uses OpenZeppelin's audited contracts
- Ownership controls protect administrative functions
- Duplicate claim prevention through mapping
- Comprehensive test coverage
- Consider conducting a professional audit before mainnet deployment

## Gas Optimization

The contract is optimized for gas efficiency:
- Uses `calldata` for array parameters in batch operations
- Efficient storage patterns with mappings
- Constants for immutable values

## Continuous Integration

The project includes GitHub Actions CI that:
- Checks code formatting
- Builds the contracts
- Runs the full test suite

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Author

Solomon-Alex

## Support

For questions or issues, please open an issue on GitHub.
