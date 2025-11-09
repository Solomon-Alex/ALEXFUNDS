// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ALEXFUNDS.sol";
import "./mocks/MockERC20.sol";

contract ALEXFUNDSTest is Test {
    ALEXFUNDS public alexfunds;
    MockERC20 public token;
    
    address public owner = address(1);
    address public creator = address(2);
    address public contributor1 = address(3);
    address public contributor2 = address(4);
    
    uint256 constant INITIAL_BALANCE = 1000000 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        alexfunds = new ALEXFUNDS();
        token = new MockERC20("Test Token", "TEST", 18);
        vm.stopPrank();
        
        // Mint tokens to contributors
        token.mint(contributor1, INITIAL_BALANCE);
        token.mint(contributor2, INITIAL_BALANCE);
    }
    
    function testCreateCampaign() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            30,
            address(token)
        );
        
        assertEq(campaignId, 0);
        assertEq(alexfunds.campaignCount(), 1);
    }
    
    function testContribute() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            30,
            address(token)
        );
        
        uint256 contributeAmount = 50 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        alexfunds.contribute(campaignId, contributeAmount);
        vm.stopPrank();
        
        assertEq(alexfunds.getContribution(campaignId, contributor1), contributeAmount);
    }
    
    function testSuccessfulCampaignWithdrawal() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            1,
            address(token)
        );
        
        uint256 contributeAmount = 100 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        alexfunds.contribute(campaignId, contributeAmount);
        vm.stopPrank();
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(creator);
        alexfunds.withdrawFunds(campaignId);
        
        uint256 expectedFee = (contributeAmount * 250) / 10000; // 2.5%
        uint256 expectedAmount = contributeAmount - expectedFee;
        
        assertEq(token.balanceOf(creator), expectedAmount);
    }
    
    function test_FailedCampaignRefund() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            1,
            address(token)
        );
        
        uint256 contributeAmount = 50 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        alexfunds.contribute(campaignId, contributeAmount);
        vm.stopPrank();
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 2 days);
        
        uint256 balanceBefore = token.balanceOf(contributor1);
        
        vm.prank(contributor1);
        alexfunds.claimRefund(campaignId);
        
        assertEq(token.balanceOf(contributor1), balanceBefore + contributeAmount);
    }
    
    function test_RevertWhen_ContributingToNonexistentCampaign() public {
        uint256 contributeAmount = 50 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        
        vm.expectRevert();
        alexfunds.contribute(999, contributeAmount);
        vm.stopPrank();
    }
    
    function test_RevertWhen_WithdrawingBeforeDeadline() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            30,
            address(token)
        );
        
        uint256 contributeAmount = 100 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        alexfunds.contribute(campaignId, contributeAmount);
        vm.stopPrank();
        
        vm.prank(creator);
        vm.expectRevert();
        alexfunds.withdrawFunds(campaignId);
    }
    
    function test_RevertWhen_ClaimingRefundFromSuccessfulCampaign() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            1,
            address(token)
        );
        
        uint256 contributeAmount = 100 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contributeAmount);
        alexfunds.contribute(campaignId, contributeAmount);
        vm.stopPrank();
        
        // Fast forward past deadline
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(contributor1);
        vm.expectRevert();
        alexfunds.claimRefund(campaignId);
    }
    
    function test_MultipleContributions() public {
        vm.prank(creator);
        uint256 campaignId = alexfunds.createCampaign(
            "Test Campaign",
            "Test Description",
            100 * 10**18,
            30,
            address(token)
        );
        
        uint256 contribution1 = 30 * 10**18;
        uint256 contribution2 = 40 * 10**18;
        
        vm.startPrank(contributor1);
        token.approve(address(alexfunds), contribution1);
        alexfunds.contribute(campaignId, contribution1);
        vm.stopPrank();
        
        vm.startPrank(contributor2);
        token.approve(address(alexfunds), contribution2);
        alexfunds.contribute(campaignId, contribution2);
        vm.stopPrank();
        
        assertEq(alexfunds.getContribution(campaignId, contributor1), contribution1);
        assertEq(alexfunds.getContribution(campaignId, contributor2), contribution2);
    }
}