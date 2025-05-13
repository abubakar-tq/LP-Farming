//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LPToken} from "src/LPToken.sol";
import {TokenA} from "src/TokenA.sol";
import {TokenB} from "src/TokenB.sol";
import {LPContract} from "src/LPContract.sol";
import {RewardToken} from "src/RewardToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployScript} from "script/DeployScript.s.sol";
import {console} from "forge-std/console.sol";

contract LPContractTest is Test {
    //errors
    error LPContract_InvalidAmount();
    error LPContract_TokenATrasferFailed();
    error LPContract_TokenBTrasferFailed();
    error LPContract_TokenLpTrasferFailed();
    error LPContract_InsufficientLiquidityMinted();
    error LPContract_WithdrawNotEnough();

    address public user;
    LPContract public lpContract;
    HelperConfig public helperConfig;
    TokenA public tokenA;
    TokenB public tokenB;
    LPToken public tokenLp;
    RewardToken public rewardToken;
    uint256 public rewardPerBlock;

    function setUp() external {
        // Deploy the contracts
        DeployScript deployScript = new DeployScript();
        helperConfig = deployScript.deployLPContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        lpContract = config.lpContract;
        tokenA = config.tokenA;
        tokenB = config.tokenB;
        tokenLp = config.tokenLp;
        user = config.user;
        rewardToken = config.rewardToken;
        rewardPerBlock = config.rewardPerBlock;
    }

    function testDeposit() external {
        uint256 amountA = 1000;
        uint256 amountB = 2000;

        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), amountA);
        tokenB.approve(address(lpContract), amountB);
        // Call the deposit function
        lpContract.deposit(amountA, amountB);
        vm.stopPrank();

        console.log(
            "Token A balance of LPContract: ",
            tokenA.balanceOf(address(lpContract))
        );
        console.log(
            "Token B balance of LPContract: ",
            tokenB.balanceOf(address(lpContract))
        );
        console.log("LPToken balance of user: ", tokenLp.balanceOf(user));

        // Check the balances
        assertEq(tokenA.balanceOf(address(lpContract)), amountA);
        assertEq(tokenB.balanceOf(address(lpContract)), amountB);
    }

    function testDepositsWithZeroAmount() external {
        uint256 amountA = 0;
        uint256 amountB = 2000;

        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), amountA);
        tokenB.approve(address(lpContract), amountB);

        vm.expectRevert(LPContract_InvalidAmount.selector);
        lpContract.deposit(amountA, amountB);
        vm.stopPrank();
    }

    function testWithdraw() external {
        uint256 amountA = 1000;
        uint256 amountB = 2000;

        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), amountA);
        tokenB.approve(address(lpContract), amountB);
        // Call the deposit function
        lpContract.deposit(amountA, amountB);

        console.log(
            "Token A balance of LPContract: ",
            tokenA.balanceOf(address(lpContract))
        );
        console.log(
            "Token B balance of LPContract: ",
            tokenB.balanceOf(address(lpContract))
        );
        console.log("LPToken balance of user: ", tokenLp.balanceOf(user));

        // Withdraw the LP tokens
        uint256 lpAmount = tokenLp.balanceOf(user);
        lpContract.withdraw(lpAmount);
        vm.stopPrank();

        console.log("Token A balance of user: ", tokenA.balanceOf(user));
        console.log("Token B balance of user: ", tokenB.balanceOf(user));

        // Check the balances
        assertEq(tokenA.balanceOf(user), 1000000000000000000000000);
        assertEq(tokenB.balanceOf(user), 1000000000000000000000000);
    }

    modifier DepositTokens() {
        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), 1000);
        tokenB.approve(address(lpContract), 2000);
        // Call the deposit function
        lpContract.deposit(1000, 2000);
        vm.stopPrank();
        _;
    }

    function testWithdrawWithMoreThanBalance() external {
        uint256 amountA = 1000;
        uint256 amountB = 2000;

        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), amountA);
        tokenB.approve(address(lpContract), amountB);
        // Call the deposit function
        lpContract.deposit(amountA, amountB);

        console.log(
            "Token A balance of LPContract: ",
            tokenA.balanceOf(address(lpContract))
        );
        console.log(
            "Token B balance of LPContract: ",
            tokenB.balanceOf(address(lpContract))
        );
        console.log("LPToken balance of user: ", tokenLp.balanceOf(user));

        // Withdraw the LP tokens
        uint256 lpAmount = tokenLp.balanceOf(user) + 1;
        vm.expectRevert(LPContract_WithdrawNotEnough.selector);

        lpContract.withdraw(lpAmount);
        vm.stopPrank();
    }

    function testPendingReward() external DepositTokens {
        vm.startPrank(user);
        // Simulate some blocks passing
        console.log(
            "Pending rewards before block roll: ",
            lpContract.pendingReward(user)
        );
        vm.roll(block.number + 10);

        // Check pending rewards
        uint256 pendingRewards = lpContract.pendingReward(user);
        console.log("Pending rewards after block roll: ", pendingRewards);
        vm.stopPrank();

        // Check the pending rewards
        assertApproxEqAbs(pendingRewards, 10 * rewardPerBlock, 1); // where `1` is the acceptable delta
    }

    function testClaimReward() external DepositTokens {
        vm.startPrank(user);
        // Simulate some blocks passing
        vm.roll(block.number + 10);

        // Check pending rewards
        uint256 pendingRewards = lpContract.pendingReward(user);
        console.log("Pending rewards before claim: ", pendingRewards);

        // Claim rewards
        lpContract.claimReward();

        // Check the balance of the user
        uint256 userBalance = rewardToken.balanceOf(user);
        console.log("User balance after claim: ", userBalance);
        vm.stopPrank();

        // Check the user's balance
        assertApproxEqAbs(userBalance, 10 * rewardPerBlock, 1);
    }

    function testUpdatePoolCorrectly() external DepositTokens {
        vm.startPrank(user);
        // Simulate some blocks passing
        vm.roll(block.number + 10);

        // Check the last reward block
        uint256 lastRewardBlock = lpContract.getLastRewardBlock();
        console.log("Last reward block: ", lastRewardBlock);

        // Update the pool
        lpContract.updatePool();

        vm.stopPrank();

        uint256 updatedLastRewardBlock = lpContract.getLastRewardBlock();
        uint256 lpContractRewardBalance = rewardToken.balanceOf(
            address(lpContract)
        );
        uint256 totalLpStaked = lpContract.getTotalLpStaked();
        uint256 accumulatedReward = lpContract.getAccumulatedRewardPerShare();

        console.log("Total lp staked: ", totalLpStaked);
        console.log("balance of user lp ", tokenLp.balanceOf(user));

        assertApproxEqAbs(
            accumulatedReward,
            (10 * rewardPerBlock * 1e12) / totalLpStaked,
            1
        );

        assertApproxEqAbs(lpContractRewardBalance, 10 * rewardPerBlock, 1);
        assertApproxEqAbs(updatedLastRewardBlock, block.number, 1);
    }

    function testConstructorInitialization() external view {
        assertEq(lpContract.getLastRewardBlock(), block.number);
        assertEq(lpContract.getAccumulatedRewardPerShare(), 0);
        assertEq(lpContract.getTotalLpStaked(), 0);
    }

    function testDepositsLargeAmounts() external {
        uint256 amountA = 1e18;
        uint256 amountB = 2e18;

        vm.startPrank(user);
        tokenA.approve(address(lpContract), amountA);
        tokenB.approve(address(lpContract), amountB);
        lpContract.deposit(amountA, amountB);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(address(lpContract)), amountA);
        assertEq(tokenB.balanceOf(address(lpContract)), amountB);
    }

    function testWithdrawAllLiquidity() external DepositTokens {
        vm.startPrank(user);
        uint256 lpAmount = tokenLp.balanceOf(user);
        lpContract.withdraw(lpAmount);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user), 1000000000000000000000000);
        assertEq(tokenB.balanceOf(user), 1000000000000000000000000);
    }

    function testWithdrawWithoutLiquidity() external {
        vm.startPrank(user);
        vm.expectRevert(LPContract_WithdrawNotEnough.selector);
        lpContract.withdraw(1);
        vm.stopPrank();
    }

    function testRewardsForMultipleUsers() external DepositTokens {
        address user2 = address(0x123);

        //mint the tokens to user2
        tokenA.mint(user2, 2000);
        tokenB.mint(user2, 4000);

        vm.startPrank(user2);
        tokenA.approve(address(lpContract), 2000);
        tokenB.approve(address(lpContract), 4000);
        lpContract.deposit(2000, 4000);
        vm.stopPrank();

        vm.roll(block.number + 10);

        uint256 pendingRewardsUser1 = lpContract.pendingReward(user);
        uint256 pendingRewardsUser2 = lpContract.pendingReward(user2);

        console.log("user1 pending rewards: ", pendingRewardsUser1);
        console.log("user2 pending rewards: ", pendingRewardsUser2);

        assertApproxEqAbs(pendingRewardsUser1, (10 * rewardPerBlock) / 3, 1);
        assertApproxEqAbs(pendingRewardsUser2, (20 * rewardPerBlock) / 3, 1);
    }

    function testClaimRewardsMultipleTimes() external DepositTokens {
        vm.startPrank(user);
        vm.roll(block.number + 10);
        lpContract.claimReward();

        uint256 firstClaim = rewardToken.balanceOf(user);
        assertApproxEqAbs(firstClaim, 10 * rewardPerBlock, 1);

        vm.roll(block.number + 10);
        lpContract.claimReward();

        uint256 secondClaim = rewardToken.balanceOf(user);
        assertApproxEqAbs(secondClaim, 20 * rewardPerBlock, 1);
        vm.stopPrank();
    }

    function testUpdatePoolWithNoStakers() external {
        vm.roll(block.number + 10);
        lpContract.updatePool();

        uint256 lastRewardBlock = lpContract.getLastRewardBlock();
        assertEq(lastRewardBlock, block.number);
    }

    function testPendingRewardsNoBlocksPassed() external DepositTokens {
        uint256 pendingRewards = lpContract.pendingReward(user);
        assertEq(pendingRewards, 0);
    }

    function testPendingRewardsAreTrasferredBeforeDeposit()
        external
        DepositTokens
    {
        vm.roll(block.number + 10);
        uint256 pendingRewards = lpContract.pendingReward(user);

        vm.startPrank(user);
        // Approve the LPContract to spend tokens
        tokenA.approve(address(lpContract), 1000);
        tokenB.approve(address(lpContract), 2000);
        // Call the deposit function
        lpContract.deposit(1000, 2000);
        vm.stopPrank();

        uint256 userBalance = rewardToken.balanceOf(user);

        assertApproxEqAbs(userBalance, pendingRewards, 1);
        assertEq(lpContract.pendingReward(user), 0);
    }

    function testWithdrawWithZero() external {
        vm.expectRevert(LPContract_InvalidAmount.selector);

        vm.startPrank(user);

        lpContract.withdraw(0);

        vm.stopPrank();
    }

    
}
