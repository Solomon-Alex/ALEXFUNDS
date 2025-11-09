// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ALEXFUNDS
 * @notice A token-based crowdfunding platform for creating and managing fundraising campaigns
 * @dev Supports ERC20 tokens for contributions with deadline and goal-based campaigns
 */
contract ALEXFUNDS is ReentrancyGuard, Ownable {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        address tokenAddress;
        bool withdrawn;
        bool active;
        mapping(address => uint256) contributions;
    }

    // State variables
    uint256 public campaignCount;
    uint256 public platformFeePercentage = 250; // 2.5% (basis points)
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256[]) public creatorCampaigns;
    
    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goalAmount,
        uint256 deadline,
        address tokenAddress
    );
    
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event CampaignWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount,
        uint256 fee
    );
    
    event RefundClaimed(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event CampaignCancelled(uint256 indexed campaignId);
    event PlatformFeeUpdated(uint256 newFee);

    // Errors
    error InvalidDeadline();
    error InvalidGoalAmount();
    error CampaignNotActive();
    error CampaignEnded();
    error CampaignNotEnded();
    error GoalNotReached();
    error GoalReached();
    error AlreadyWithdrawn();
    error NoContribution();
    error TransferFailed();
    error Unauthorized();
    error InvalidFeePercentage();

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Creates a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goalAmount Funding goal in token units
     * @param _durationDays Campaign duration in days
     * @param _tokenAddress ERC20 token address for contributions
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays,
        address _tokenAddress
    ) external returns (uint256) {
        if (_goalAmount == 0) revert InvalidGoalAmount();
        if (_durationDays == 0) revert InvalidDeadline();

        uint256 campaignId = campaignCount++;
        Campaign storage campaign = campaigns[campaignId];
        
        campaign.creator = msg.sender;
        campaign.title = _title;
        campaign.description = _description;
        campaign.goalAmount = _goalAmount;
        campaign.deadline = block.timestamp + (_durationDays * 1 days);
        campaign.tokenAddress = _tokenAddress;
        campaign.active = true;
        
        creatorCampaigns[msg.sender].push(campaignId);
        
        emit CampaignCreated(
            campaignId,
            msg.sender,
            _title,
            _goalAmount,
            campaign.deadline,
            _tokenAddress
        );
        
        return campaignId;
    }

    /**
     * @notice Contribute tokens to a campaign
     * @param _campaignId Campaign ID to contribute to
     * @param _amount Amount of tokens to contribute
     */
    function contribute(uint256 _campaignId, uint256 _amount) external nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (!campaign.active) revert CampaignNotActive();
        if (block.timestamp >= campaign.deadline) revert CampaignEnded();
        if (_amount == 0) revert InvalidGoalAmount();
        
        IERC20 token = IERC20(campaign.tokenAddress);
        
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }
        
        campaign.contributions[msg.sender] += _amount;
        campaign.raisedAmount += _amount;
        
        emit ContributionMade(_campaignId, msg.sender, _amount);
    }

    /**
     * @notice Withdraw funds from a successful campaign
     * @param _campaignId Campaign ID to withdraw from
     */
    function withdrawFunds(uint256 _campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (msg.sender != campaign.creator) revert Unauthorized();
        if (block.timestamp < campaign.deadline) revert CampaignNotEnded();
        if (campaign.raisedAmount < campaign.goalAmount) revert GoalNotReached();
        if (campaign.withdrawn) revert AlreadyWithdrawn();
        
        campaign.withdrawn = true;
        campaign.active = false;
        
        uint256 fee = (campaign.raisedAmount * platformFeePercentage) / FEE_DENOMINATOR;
        uint256 amountToCreator = campaign.raisedAmount - fee;
        
        IERC20 token = IERC20(campaign.tokenAddress);
        
        if (!token.transfer(campaign.creator, amountToCreator)) {
            revert TransferFailed();
        }
        
        if (fee > 0 && !token.transfer(owner(), fee)) {
            revert TransferFailed();
        }
        
        emit CampaignWithdrawn(_campaignId, campaign.creator, amountToCreator, fee);
    }

    /**
     * @notice Claim refund from a failed campaign
     * @param _campaignId Campaign ID to claim refund from
     */
    function claimRefund(uint256 _campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (block.timestamp < campaign.deadline) revert CampaignNotEnded();
        if (campaign.raisedAmount >= campaign.goalAmount) revert GoalReached();
        
        uint256 contribution = campaign.contributions[msg.sender];
        if (contribution == 0) revert NoContribution();
        
        campaign.contributions[msg.sender] = 0;
        
        IERC20 token = IERC20(campaign.tokenAddress);
        
        if (!token.transfer(msg.sender, contribution)) {
            revert TransferFailed();
        }
        
        emit RefundClaimed(_campaignId, msg.sender, contribution);
    }

    /**
     * @notice Cancel an active campaign (creator only, before deadline)
     * @param _campaignId Campaign ID to cancel
     */
    function cancelCampaign(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        if (msg.sender != campaign.creator) revert Unauthorized();
        if (!campaign.active) revert CampaignNotActive();
        if (block.timestamp >= campaign.deadline) revert CampaignEnded();
        
        campaign.active = false;
        
        emit CampaignCancelled(_campaignId);
    }

    /**
     * @notice Update platform fee percentage (owner only)
     * @param _newFee New fee in basis points (e.g., 250 = 2.5%)
     */
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        if (_newFee > 1000) revert InvalidFeePercentage(); // Max 10%
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    // View functions
    function getCampaignDetails(uint256 _campaignId) 
        external 
        view 
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goalAmount,
            uint256 raisedAmount,
            uint256 deadline,
            address tokenAddress,
            bool withdrawn,
            bool active
        ) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.tokenAddress,
            campaign.withdrawn,
            campaign.active
        );
    }

    function getContribution(uint256 _campaignId, address _contributor) 
        external 
        view 
        returns (uint256) 
    {
        return campaigns[_campaignId].contributions[_contributor];
    }

    function getCreatorCampaigns(address _creator) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return creatorCampaigns[_creator];
    }

    function isCampaignSuccessful(uint256 _campaignId) 
        external 
        view 
        returns (bool) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return campaign.raisedAmount >= campaign.goalAmount && 
               block.timestamp >= campaign.deadline;
    }
}