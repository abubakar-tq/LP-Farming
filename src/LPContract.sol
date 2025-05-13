//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenA} from "./TokenA.sol";
import {TokenB} from "./TokenB.sol";
import {LPToken} from "./LPToken.sol";
import {RewardToken} from "./RewardToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract LPContract {
    //Errors
    error LPContract_InvalidAmount();
    error LPContract_TokenATrasferFailed();
    error LPContract_TokenBTrasferFailed();
    error LPContract_TokenLpTrasferFailed();
    error LPContract_InsufficientLiquidityMinted();
    error LPContract_WithdrawNotEnough();

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityMinted
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityBurned
    );

    // Deposit(A,B) , Withdraw() ,

    uint256 private s_amountTokenA;
    uint256 private s_amountTokenB;
    TokenA private s_tokenA;
    TokenB private s_tokenB;
    LPToken private s_tokenLp;

    RewardToken private s_rewardToken;
    uint256 private s_accRewardPerShare;
    uint256 private s_lastRewardBlock;
    uint256 private immutable i_rewardPerBlock;
    uint256 private s_totalLpStaked;

    struct UserInfo {
        uint256 amount; // LP tokens user has staked
        uint256 rewardDebt; // Bookkeeping to prevent over-rewarding
    }

    mapping(address => UserInfo) public userInfo;

    function updatePool() public {
        if (block.number <= s_lastRewardBlock) return;

        if (s_totalLpStaked == 0) {
            s_lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - s_lastRewardBlock;
        uint256 reward = multiplier * i_rewardPerBlock;

        // Mint or transfer rewards to the contract
        s_rewardToken.mint(address(this), reward); // or mint if you have mint rights

        s_accRewardPerShare += (reward * 1e12) / s_totalLpStaked;
        s_lastRewardBlock = block.number;
    }

    function deposit(uint256 amountA, uint256 amountB) public {
        if (amountA == 0 || amountB == 0) {
            revert LPContract_InvalidAmount();
        }
        updatePool();

        UserInfo storage user = userInfo[msg.sender];

        //  Send pending rewards first
        if (user.amount > 0) {
            uint256 pending = (user.amount * s_accRewardPerShare) /
                1e12 -
                user.rewardDebt;
            if (pending > 0) {
                s_rewardToken.transfer(msg.sender, pending);
            }
        }

        

        if (!s_tokenA.transferFrom(msg.sender, address(this), amountA)) {
            revert LPContract_TokenATrasferFailed();
        }
        if (!s_tokenB.transferFrom(msg.sender, address(this), amountB)) {
            revert LPContract_TokenBTrasferFailed();
        }

        uint256 liquidity;
        if (s_totalLpStaked == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            uint256 amountAInLp = (amountA * s_totalLpStaked) / s_amountTokenA;
            uint256 amountBInLp = (amountB * s_totalLpStaked) / s_amountTokenB;
            liquidity = amountAInLp < amountBInLp ? amountAInLp : amountBInLp;
        }

        if (liquidity <= 0) {
            revert LPContract_InsufficientLiquidityMinted();
        }

        s_tokenLp.mint(msg.sender, liquidity);

        //  Update pool state
        s_amountTokenA += amountA;
        s_amountTokenB += amountB;
        s_totalLpStaked += liquidity;

        //  Update user info
        user.amount += liquidity;
        user.rewardDebt = (user.amount * s_accRewardPerShare) / 1e12;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function withdraw(uint256 lpAmount) external {
        if (lpAmount == 0) {
            revert LPContract_InvalidAmount();
        }

        UserInfo storage user = userInfo[msg.sender];

        if (user.amount < lpAmount) {
            revert LPContract_WithdrawNotEnough();
        }

        updatePool();

        uint256 pending = (user.amount * s_accRewardPerShare) /
            1e12 -
            user.rewardDebt;

        if (pending > 0) {
            bool success = s_rewardToken.transfer(msg.sender, pending);
            // Optional: Add a custom error for reward transfer if needed
            if (!success) {
                revert LPContract_TokenLpTrasferFailed();
            }
        }

        // Calculate how much TokenA and TokenB to send
        uint256 amountA = (s_amountTokenA * lpAmount) / s_totalLpStaked;
        uint256 amountB = (s_amountTokenB * lpAmount) / s_totalLpStaked;

        // Burn LP tokens
        s_tokenLp.burn(msg.sender, lpAmount);

        // Update user info
        user.amount -= lpAmount;
        user.rewardDebt = (user.amount * s_accRewardPerShare) / 1e12;

        // Update total staked
        s_totalLpStaked -= lpAmount;

        // Update reserves
        s_amountTokenA -= amountA;
        s_amountTokenB -= amountB;

        // Transfer tokens to user
        if (!s_tokenA.transfer(msg.sender, amountA)) {
            revert LPContract_TokenATrasferFailed();
        }

        if (!s_tokenB.transfer(msg.sender, amountB)) {
            revert LPContract_TokenBTrasferFailed();
        }

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 tempAcc = s_accRewardPerShare;

        if (block.number > s_lastRewardBlock && s_totalLpStaked != 0) {
            uint256 multiplier = block.number - s_lastRewardBlock;
            uint256 reward = multiplier * i_rewardPerBlock;
            tempAcc += (reward * 1e12) / s_totalLpStaked;
        }

        return (user.amount * tempAcc) / 1e12 - user.rewardDebt;
    }

    function claimReward() external {
        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = (user.amount * s_accRewardPerShare) /
            1e12 -
            user.rewardDebt;
        if (pending > 0) {
            s_rewardToken.transfer(msg.sender, pending);
        }
        user.rewardDebt = (user.amount * s_accRewardPerShare) / 1e12;

        //rewardclaim event
    }

    constructor(
        address _tokenA,
        address _tokenB,
        address _lpToken,
        address _rewardToken,
        uint256 _rewardPerBlock
    ) {
        s_tokenA = TokenA(_tokenA);
        s_tokenB = TokenB(_tokenB);
        s_tokenLp = LPToken(_lpToken);
        s_rewardToken = RewardToken(_rewardToken);

        i_rewardPerBlock = _rewardPerBlock;
        s_lastRewardBlock = block.number;
    }

    function getLastRewardBlock() external view returns (uint256) {
        return s_lastRewardBlock;
    }

    function getAccumulatedRewardPerShare() external view returns (uint256) {
        return s_accRewardPerShare;
    }

    function getTotalLpStaked() external view returns (uint256) {
        return s_totalLpStaked;
    }
}
