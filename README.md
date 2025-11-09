# ALEXFUNDS

A decentralized token-based crowdfunding platform built on Ethereum using Solidity and the Foundry framework. ALEXFUNDS enables creators to launch fundraising campaigns with goal-based outcomes and automatic refund mechanisms for failed campaigns.

## Features

- **Token-Based Crowdfunding**: Support for any ERC20 token as the contribution currency
- **Goal-Oriented Campaigns**: Set funding goals and deadlines
- **Automatic Refunds**: Contributors automatically get refunds if campaigns fail to meet goals
- **Platform Fees**: Configurable fee structure (default 2.5%) for successful campaigns
- **Campaign Management**: Creators can cancel campaigns before the deadline
- **Transparent Tracking**: Full contribution history and campaign status visibility
- **Security**: Built with OpenZeppelin contracts and reentrancy protection

## How It Works

### For Campaign Creators

1. **Create a Campaign**: Set title, description, funding goal, duration, and accepted token
2. **Promote Your Campaign**: Share with potential contributors
3. **Withdraw Funds**: After deadline, if goal is met, withdraw raised funds (minus platform fee)
4. **Cancel if Needed**: Cancel campaigns before deadline if circumstances change

### For Contributors

1. **Browse Campaigns**: Find campaigns you want to support
2. **Contribute Tokens**: Send ERC20 tokens to campaigns
3. **Automatic Outcomes**:
   - **Success**: Funds go to creator (you helped!)
   - **Failure**: Claim full refund of your contribution

## Smart Contract Architecture

### Core Components

- **Campaign Management**: Create, track, and manage multiple campaigns
- **Contribution System**: Secure token transfers with reentrancy protection
- **Withdrawal Logic**: Automated distribution with fee calculation
- **Refund Mechanism**: Safe refund processing for failed campaigns

### Campaign Lifecycle

```
Create Campaign → Active (accepting contributions) → Deadline Reached
                                                           ↓
                                    ┌─────────────────────┴─────────────────────┐
                                    ↓                                           ↓
                            Goal Met (Success)                          Goal Not Met (Failed)
                                    ↓                                           ↓
                        Creator Withdraws Funds                    Contributors Claim Refunds
```

## Contract Details

### Key Parameters

- **Platform Fee**: 2.5% (250 basis points) - configurable by owner
- **Maximum Fee**: 10% (1000 basis points)
- **Fee Denominator**: 10,000 (for precise percentage calculations)

### Campaign Structure

```solidity
struct Campaign {
    address creator;           // Campaign creator
    string title;             // Campaign title
    string description;       // Campaign description
    uint256 goalAmount;       // Funding goal
    uint256 raisedAmount;     // Amount raised so far
    uint256 deadline;         // Campaign end timestamp
    address tokenAddress;     // ERC20 token for contributions
    bool withdrawn;           // Whether funds were withdrawn
    bool active;              // Campaign status
    mapping(address => uint256) contributions;  // Contributor balances
}
```

## Installation & Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git
- An ERC20 token for testing (or use the included MockERC20)

### Clone and Install

```bash
git clone <your-repo-url>
cd alexfunds
forge install
```

Dependencies installed:
- `forge-std` (v1.11.0) - Foundry standard library
- `openzeppelin-contracts` (v5.5.0) - Security and ERC20 standards

### Build

```bash
forge build
```

### Test

Run the complete test suite:
```bash
forge test
```

Run with detailed output:
```bash
forge test -vvv
```

Run with gas reporting:
```bash
forge test --gas-report
```

### Format Code

```bash
forge fmt
```

## Deployment

### Local Deployment (Anvil)

1. Start local node:
```bash
anvil
```

2. Deploy contract:
```bash
forge script script/DeployScript.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

### Testnet/Mainnet Deployment

1. Create `.env` file:
```bash
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

2. Deploy and verify:
```bash
source .env
forge script script/DeployScript.s.sol:DeployScript \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify
```

## Usage Examples

### Creating a Campaign

```solidity
// Create a 30-day campaign with 1000 USDC goal
uint256 campaignId = alexfunds.createCampaign(
    "Build a DApp",
    "Funding to build our revolutionary DApp",
    1000 * 10**6,  // 1000 USDC (6 decimals)
    30,            // 30 days duration
    usdcTokenAddress
);
```

### Contributing to a Campaign

```solidity
// Approve tokens first
token.approve(address(alexfunds), 100 * 10**18);

// Contribute 100 tokens
alexfunds.contribute(campaignId, 100 * 10**18);
```

### Withdrawing Funds (Successful Campaign)

```solidity
// After deadline, if goal is met
alexfunds.withdrawFunds(campaignId);
// Creator receives raised amount minus 2.5% platform fee
```

### Claiming Refund (Failed Campaign)

```solidity
// After deadline, if goal was not met
alexfunds.claimRefund(campaignId);
// Contributor receives full contribution back
```

### Cancelling a Campaign

```solidity
// Creator can cancel before deadline
alexfunds.cancelCampaign(campaignId);
// Contributors can then claim refunds
```

### Viewing Campaign Details

```solidity
(
    address creator,
    string memory title,
    string memory description,
    uint256 goalAmount,
    uint256 raisedAmount,
    uint256 deadline,
    address tokenAddress,
    bool withdrawn,
    bool active
) = alexfunds.getCampaignDetails(campaignId);
```

## API Reference

### Write Functions

#### `createCampaign`
```solidity
function createCampaign(
    string memory _title,
    string memory _description,
    uint256 _goalAmount,
    uint256 _durationDays,
    address _tokenAddress
) external returns (uint256)
```
Creates a new crowdfunding campaign.

#### `contribute`
```solidity
function contribute(uint256 _campaignId, uint256 _amount) external
```
Contribute tokens to an active campaign.

#### `withdrawFunds`
```solidity
function withdrawFunds(uint256 _campaignId) external
```
Withdraw funds from a successful campaign (creator only).

#### `claimRefund`
```solidity
function claimRefund(uint256 _campaignId) external
```
Claim refund from a failed campaign.

#### `cancelCampaign`
```solidity
function cancelCampaign(uint256 _campaignId) external
```
Cancel an active campaign before deadline (creator only).

#### `updatePlatformFee`
```solidity
function updatePlatformFee(uint256 _newFee) external onlyOwner
```
Update platform fee percentage (owner only, max 10%).

### View Functions

#### `getCampaignDetails`
Returns all campaign information including status.

#### `getContribution`
```solidity
function getContribution(uint256 _campaignId, address _contributor) external view returns (uint256)
```
Get contribution amount for a specific contributor.

#### `getCreatorCampaigns`
```solidity
function getCreatorCampaigns(address _creator) external view returns (uint256[] memory)
```
Get all campaign IDs created by an address.

#### `isCampaignSuccessful`
```solidity
function isCampaignSuccessful(uint256 _campaignId) external view returns (bool)
```
Check if a campaign met its goal after deadline.

## Events

```solidity
event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 goalAmount, uint256 deadline, address tokenAddress);
event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
event CampaignWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount, uint256 fee);
event RefundClaimed(uint256 indexed campaignId, address indexed contributor, uint256 amount);
event CampaignCancelled(uint256 indexed campaignId);
event PlatformFeeUpdated(uint256 newFee);
```

## Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **Ownable**: Secure ownership management
- **Custom Errors**: Gas-efficient error handling
- **OpenZeppelin Standards**: Battle-tested contract implementations
- **Comprehensive Testing**: Full test coverage including edge cases

## Testing

The project includes comprehensive tests covering:

- ✅ Campaign creation and validation
- ✅ Contribution processing
- ✅ Successful campaign withdrawals with fee calculation
- ✅ Failed campaign refunds
- ✅ Multiple contributors
- ✅ Access control (creator/owner permissions)
- ✅ Edge cases and error conditions
- ✅ Campaign cancellation
- ✅ Deadline enforcement

### Test Coverage

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testSuccessfulCampaignWithdrawal

# Run with coverage
forge coverage
```

## Gas Optimization

- Uses custom errors instead of require strings
- Efficient storage patterns with mappings
- Minimal storage updates
- Batch operations where possible

## Continuous Integration

GitHub Actions CI automatically:
- Checks code formatting
- Builds the contracts
- Runs the complete test suite
- Reports on any failures

See `.github/workflows/test.yml` for configuration.

## Project Structure

```
alexfunds/
├── src/
│   └── ALEXFUNDS.sol          # Main crowdfunding contract
├── script/
│   └── DeployScript.s.sol     # Deployment script
├── test/
│   ├── ALEXFUNDS.t.sol        # Comprehensive tests
│   └── mocks/
│       └── MockERC20.sol      # Mock ERC20 for testing
├── lib/                       # Dependencies
├── .github/
│   └── workflows/
│       └── test.yml           # CI configuration
├── foundry.toml               # Foundry configuration
└── README.md                  # This file
```

## Roadmap

- [ ] Frontend interface (React + Web3)
- [ ] Multi-token support in single campaign
- [ ] Milestone-based funding releases
- [ ] Campaign updates and comments
- [ ] IPFS integration for media
- [ ] Governance features
- [ ] Campaign categories and search
- [ ] Social features and sharing

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass (`forge test`)
- Code is formatted (`forge fmt`)
- New features include tests

## Security Considerations

⚠️ **Important Security Notes**:

- This contract has not been professionally audited
- Use at your own risk in production
- Test thoroughly on testnets before mainnet deployment
- Consider a professional security audit for production use
- Be aware of token approval risks
- Understand the platform fee mechanism

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Ethereum Development](https://ethereum.org/en/developers/)

## Author

Solomon-Alex

## Support

For questions, issues, or feature requests, please open an issue on GitHub.

---

**Built with ❤️ using Foundry and OpenZeppelin**
For questions or issues, please open an issue on GitHub.
