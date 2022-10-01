// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./interfaces/sense/IAdapter.sol";
import "./interfaces/sense/IDivider.sol";
import "./interfaces/sense/IPeriphery.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@title Yield Token Compounding using sense.finance
///@author nonso
contract SenseYTC {
    using SafeMath for uint256;

    ///@notice Sense Divider interface
    IDivider public immutable divider;
    ///@notice Sense Periphery Interface
    IPeriphery public immutable periphery;
    ///@notice max value
    uint256 public constant MAX_VALUE = type(uint).max;

    //EVENTS
    event YieldTokenCompound(address adapter, uint256 maturity, uint256 underlyingIn, uint8 numOfCompounding, uint256 ytOut);

    constructor(address _divider){
        divider = IDivider(_divider);
        periphery = IPeriphery(
            IDivider(_divider).periphery()
        );
    }

    function ytc(
        address _adapter,
        uint256 _maturity,
        uint256 _amount,
        uint256 _minYtAmountOut,
        uint256 _maxUnderlyingSpent,
        uint8 _n
    ) external {
        IERC20 underlying = IERC20(IAdapter(_adapter).underlying());
        underlying.transferFrom(msg.sender, address(this), _amount);

        (, uint256 remainingAmount) = _ytc(
            _adapter, 
            _maturity, 
            _amount, 
            _minYtAmountOut, 
            _maxUnderlyingSpent, 
            msg.sender, 
            _n
        );

        if(remainingAmount > 0) underlying.transfer(msg.sender, remainingAmount);
    }

    function _ytc(
        address _adapter,
        uint256 _maturity,
        uint256 _amount,
        uint256 _minYtAmountOut,
        uint256 _maxUnderlyingSpent,
        address _user,
        uint8 _n
    ) internal returns(uint256 totalYtAccumulated, uint256 remainingAmount){
        require(_n > 0 && _n < 25, "N_OutOfBounds");
        require(_amount > 0, "ZeroAmount");

        address _pt = divider.pt(_adapter, _maturity);
        address _yt = divider.yt(_adapter, _maturity);
        
        //approve periphery to perform swap
        _approve(_pt, address(periphery));
        //approve divider to strip target
        _approve(IAdapter(_adapter).underlying(), address(divider));

        (totalYtAccumulated, remainingAmount) = _depositAndSwapNTimes(
            _adapter, 
            _pt, 
            _yt, 
            _maturity, 
            _amount, 
            _n
        );

        require(totalYtAccumulated >= _minYtAmountOut, "TooMuchSlippage_FYT");
        require((_amount.sub(remainingAmount) <= _maxUnderlyingSpent), "TooMuchSlippage_Underlying");
        
        IERC20(_yt).transfer(_user, totalYtAccumulated);
        emit YieldTokenCompound(_adapter, _maturity, _amount, _n, totalYtAccumulated);
    }
    function _depositAndSwapNTimes(
        address _adapter,
        address _pt,
        address _yt,
        uint256 _maturity,
        uint256 _amount,
        uint8 _n
    ) internal returns(uint256 totalYtAccumulated, uint256 remainingAmount){
        uint256 targetAmount = IAdapter(_adapter).wrapUnderlying(_amount);
        for(uint256 i=0; i<_n; ++i){
            (uint256 _ptAmt, uint256 _ytAmt) = _deposit(_adapter, _pt, _yt, _maturity, targetAmount);
            totalYtAccumulated += _ytAmt;
            //swap principal to target tokens
            targetAmount = periphery.swapPTsForTarget(_adapter, _maturity, _ptAmt, 0);
        }
        //convert target to underlying tokens
        remainingAmount = IAdapter(_adapter).unwrapTarget(targetAmount);
    }

    function _deposit(
        address _adapter,
        address _pt,
        address _yt,
        uint256 _maturity,
        uint256 _amount
    ) internal returns(uint256 _ptAmount, uint256 _ytAmount){
        uint256 initialPtBalance = IERC20(_pt).balanceOf(address(this));
        uint256 initialYtBalance = IERC20(_yt).balanceOf(address(this));
        //mint principal and yield token
        divider.issue(_adapter, _maturity, _amount);

        _ptAmount = IERC20(_pt).balanceOf(address(this)).sub(initialPtBalance);
        _ytAmount = IERC20(_yt).balanceOf(address(this)).sub(initialYtBalance);
    }

    // approve token
    function _approve(address _token, address _to) internal {
        if (IERC20(_token).allowance(address(this), _to) == 0)
            IERC20(_token).approve(_to, MAX_VALUE);
    }
}