//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LPToken} from "../src/LPToken.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {LPContract} from "../src/LPContract.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract CodeConstants {
    uint256 public SEPOLIA_CHAIN_ID = 11155111;
    uint256 public LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        address user; // Testing or default user
        TokenA tokenA; // Testnet or mainnet address of TokenA
        TokenB tokenB; // TokenB address
        LPToken tokenLp; // LP token contract
        LPContract lpContract;
        RewardToken rewardToken; // Reward token contract
        uint256 rewardPerBlock; // Reward per block
    }

    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getAnvilNetworkConfig();
    }

    function getSepoliaNetworkConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig(
                0x8943F7348E2559C6E69eeCb0dA932424C3E6dC66,
                TokenA(address(0x0)),
                TokenB(address(0x0)),
                LPToken(address(0x0)),
                LPContract(address(0x0)),
                RewardToken(address(0x0)),
                1e18 // 1 token per block
            );
    }

    function getAnvilNetworkConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig(
                0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
                TokenA(address(0x0)),
                TokenB(address(0x0)),
                LPToken(address(0x0)),
                LPContract(address(0x0)),
                RewardToken(address(0x0)),
                1e18 // 1 token per block
            );
    }

    function getConfigByChainID(
        uint256 chainID
    ) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[chainID];

        return config;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainID(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }
}
