// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "forge-std/Test.sol";
import "./utils/SwapHelper.sol";
import {ISPSP, StakedPSPDeposit} from "../src/helpers/StakedPSPDeposit.sol";

contract StakedPSPDepositTest is Test, SwapHelper{
    StakedPSPDeposit sPSP;
    address public constant PSP_ADDRESS = 0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant PSP_AMM_ADDRESS = 0xA4085c106c7a9A7AD0574865bbd7CaC5E1098195;
    ISPSP public constant SPSP4 = ISPSP(0x6b1D394Ca67fDB9C90BBd26FE692DdA4F4f53ECD);

    uint256 public constant MAX_VALUE = type(uint).max;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        sPSP = new StakedPSPDeposit(
            address(SPSP4),
            PSP_ADDRESS,
            address(SPSP4)
        );
    }
}