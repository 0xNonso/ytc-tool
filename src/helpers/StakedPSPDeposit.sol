// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/apwine/IIBTDeposit.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface ISPSP{
    function enter(uint256 _pspAmount) external;
    function sPSPForPSP(uint256 _pspAmount) external view returns (uint256 sPSPAmount_);
}

contract StakedPSPDeposit is IIBTDeposit {
    using SafeERC20 for IERC20;

    ISPSP public immutable stakedPSP;
    address public immutable underlying;
    address public immutable ibtToken;

    /// most likely _stakedPSP is same as _ibtToken
    constructor(address _stakedPSP, address _underlying, address _ibtToken){
        stakedPSP = ISPSP(_stakedPSP);
        underlying = _underlying;
        ibtToken = _ibtToken;
    }
    function deposit(uint256 _amount) external override returns(uint256 sPSPAmt){
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        _maxApprove();
        stakedPSP.enter(_amount);
        sPSPAmt = stakedPSP.sPSPForPSP(_amount);
        IERC20(ibtToken).safeTransfer(msg.sender, sPSPAmt);
    }
    function _maxApprove() internal {
        if(IERC20(underlying).allowance(address(this), address(stakedPSP)) == 0)
            IERC20(underlying).safeApprove(address(stakedPSP), type(uint).max);
    }
    function getUnderlying() external view override returns(address) {
        return underlying;
    }
    function getIBT() external view override returns(address){
        return ibtToken;
    }
}