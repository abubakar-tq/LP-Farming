//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LPToken} from "../src/LPToken.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {LPContract} from "../src/LPContract.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract DeployScript is Script {
    function run() public {
        deployLPContract();
    }

    function deployLPContract() public returns (HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.user);

        TokenA tokenA = new TokenA();
        TokenB tokenB = new TokenB();
        LPToken lpToken = new LPToken();
        RewardToken rewardToken = new RewardToken();
        LPContract lpContract = new LPContract(
            address(tokenA),
            address(tokenB),
            address(lpToken),
            address(rewardToken),
            config.rewardPerBlock
        );

        lpToken.setMinter(address(lpContract));

        vm.stopBroadcast();

        // update HelperConfig if needed
        config.tokenA = tokenA;
        config.tokenB = tokenB;
        config.tokenLp = lpToken;
        config.lpContract = lpContract;
        config.rewardToken = rewardToken;

        helperConfig.setConfig(block.chainid, config);

        return helperConfig;
    }
}
