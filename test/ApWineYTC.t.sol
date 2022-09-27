// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "forge-std/Test.sol";
import "../src/ApWineYTC.sol";
import "../src/interfaces/apwine/IAMM.sol";
import "./utils/SwapHelper.sol";
import {ISPSP, StakedPSPDeposit} from "../src/helpers/StakedPSPDeposit.sol";

interface ILido {
    function submit(address _refferal) external payable;
}

contract ApWineYTCTest is Test, SwapHelper {
    ApWineYTC ytc;
    StakedPSPDeposit sPSP;
    address public constant AMM_ROUTER = 0xf5ba2E5DdED276fc0f7a7637A61157a4be79C626;
    address public constant VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant CONTROLLER = 0x4bA30FA240047c17FC557b8628799068d4396790;
    address public constant PSP_ADDRESS = 0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant PSP_AMM_ADDRESS = 0xA4085c106c7a9A7AD0574865bbd7CaC5E1098195;
    ISPSP public constant SPSP4 = ISPSP(0x6b1D394Ca67fDB9C90BBd26FE692DdA4F4f53ECD);

    uint256 public constant MAX_VALUE = type(uint).max;

    uint256[] pairPath = [0];
    uint256[] tokenPath = [1,0];

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 15605560);

        ytc = new ApWineYTC(
            AMM_ROUTER,
            VAULT,
            CONTROLLER
        );
        sPSP = new StakedPSPDeposit(
            address(SPSP4),
            PSP_ADDRESS,
            address(SPSP4)
        );
    }

    function testExample() public {
        assertTrue(true);
    }
    function testYtc1(uint256 _amount) public {
        //, uint8 _n
        vm.assume(_amount > 1e18);
        vm.assume(_amount < 10e18);
        // vm.assume(_n > 0);
        // vm.assume(_n < 11);
        uint8 _n = 24;
        vm.deal(address(this), _amount);

        uint256 pspTokAmt = _swapFromEth(WETH_ADDRESS, PSP_ADDRESS, _amount);
        IAMM _amm = IAMM(PSP_AMM_ADDRESS);

        uint256 _fytMinAmtOut = 0;
        uint256 _ibtMaxAmtSpent = MAX_VALUE;
        IERC20(PSP_ADDRESS).approve(address(ytc), MAX_VALUE);

        ytc.ytc(
            _amm, 
            sPSP,
            pspTokAmt, 
            _fytMinAmtOut, 
            _ibtMaxAmtSpent, 
            _n
        );
    }

    function testYtc2(uint8 _n) public {
        //, uint8 _n
        // vm.assume(_amount > 1e18);
        // vm.assume(_amount < 10e18);
        vm.assume(_n > 0);
        vm.assume(_n < 25);
        uint256 _amount = 7 ether;

        vm.deal(address(this), _amount);

        uint256 pspTokAmt = _swapFromEth(WETH_ADDRESS, PSP_ADDRESS, _amount);
        IAMM _amm = IAMM(PSP_AMM_ADDRESS);

        uint256 _fytMinAmtOut = 0;
        uint256 _ibtMaxAmtSpent = MAX_VALUE;
        IERC20(PSP_ADDRESS).approve(address(ytc), MAX_VALUE);

        ytc.ytc(
            _amm, 
            sPSP,
            pspTokAmt, 
            _fytMinAmtOut, 
            _ibtMaxAmtSpent, 
            _n
        );
    }

    function testYtcWithFlashloan1(uint256 _amount) public {
         //, uint8 _n
        vm.assume(_amount > 1e18);
        vm.assume(_amount < 10e18);
        // vm.assume(_n > 0);
        // vm.assume(_n < 11);
        uint8 _n = 24;
        vm.deal(address(this), _amount);

        uint256 pspTokAmt = _swapFromEth(WETH_ADDRESS, PSP_ADDRESS, _amount);
        IAMM _amm = IAMM(PSP_AMM_ADDRESS);

        uint256 _fytMinAmtOut = 0;
        uint256 _ibtMaxAmtSpent = MAX_VALUE;
        IERC20(PSP_ADDRESS).approve(address(ytc), MAX_VALUE);

        ytc.ytcWithFlashloan(
            _amm, 
            sPSP,
            pspTokAmt, 
            _fytMinAmtOut, 
            _ibtMaxAmtSpent, 
            _n
        );
    }

    function testYtcWithFlashloan2(uint8 _n) public {
        //, uint8 _n
        // vm.assume(_amount > 1e18);
        // vm.assume(_amount < 10e18);
        vm.assume(_n > 0);
        vm.assume(_n < 25);
        uint256 _amount = 7 ether;

        vm.deal(address(this), _amount);

        uint256 pspTokAmt = _swapFromEth(WETH_ADDRESS, PSP_ADDRESS, _amount);
        IAMM _amm = IAMM(PSP_AMM_ADDRESS);

        uint256 _fytMinAmtOut = 0;
        uint256 _ibtMaxAmtSpent = MAX_VALUE;
        IERC20(PSP_ADDRESS).approve(address(ytc), MAX_VALUE);

        ytc.ytcWithFlashloan(
            _amm, 
            sPSP,
            pspTokAmt, 
            _fytMinAmtOut, 
            _ibtMaxAmtSpent, 
            _n
        );
    }
}
