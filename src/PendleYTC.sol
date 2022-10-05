// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/pendle/IPendleRouter.sol";
import "./interfaces/pendle/IPendleData.sol";
import {IUniswapV2Router02} from "./interfaces/uniswap/IUniswapRouterV2.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

///@title Yield Token Compounding using pendle.finance
///@author nonso
contract PendleYTC {
    using SafeMath for uint256;

    ///@notice Pendle Router interface
    IPendleRouter public immutable pendleRouter;
    ///@notice Pendle Data interface
    IPendleData public immutable pendleData;
    ///@notice Uniswap v2 interface
    IUniswapV2Router02 public immutable sushiRouter;
    ///@notice max value
    uint256 public constant MAX_VALUE = type(uint).max;
    
    //EVENT
    event YieldTokenCompound(bytes32 indexed forgeId, uint256 indexed _expiry, uint256 amountIn, uint8 numOfCompounding, uint256 xytOut);

    constructor(address _pData, address _sushiRouter) {
        pendleData = IPendleData(_pData);
        pendleRouter = IPendleRouter(
            IPendleData(_pData).router()
        );
        sushiRouter = IUniswapV2Router02(_sushiRouter);
    }

    function ytc(
        bytes32 _forgeId,
        address _ot,
        uint256 _expiry,
        uint256 _amount,
        uint256 _minXytOut,
        uint256 _underlyingMaxSpent,
        uint8 _n
    ) external {
        address _underlyingAsset = IPendleYieldToken(_ot).underlyingAsset();
        IERC20(_underlyingAsset).transferFrom(msg.sender, address(this), _amount);

        (, uint256 _remainingAmount) = _ytc(
            _forgeId, 
            _underlyingAsset, 
            _expiry, 
            _amount, 
            _minXytOut, 
            _underlyingMaxSpent, 
            _n
        );

        if(_remainingAmount > 0) IERC20(_underlyingAsset).transfer(msg.sender, _remainingAmount);
    }
    function getOT(bytes32 _forgeId, address _underlyingAsset, uint256 _expiry) public view returns(address){
        address _underlyingYieldToken = pendleData.xytTokens(
            _forgeId, 
            _underlyingAsset, 
            _expiry
        ).underlyingYieldToken();

        return address(
            pendleData.otTokens(
                _forgeId, 
                _underlyingYieldToken, 
                _expiry
            )
        );
    }
    function _ytc(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        uint256 _amount,
        uint256 _minXytOut,
        uint256 _underlyingMaxSpent,
        uint8 _n
    ) internal returns(uint256 totalXytAccumulated, uint256 remainingAmount){
        require(_n > 0 && _n < 25, "N_OutOfBounds");
        require(_amount > 0, "ZeroAmount");
        //approve ot to sushi router
        _approve(getOT(_forgeId, _underlyingAsset, _expiry), address(sushiRouter));
        //approve underlying to pendle router 
        _approve(_underlyingAsset, address(pendleRouter));
        address xyt;
        (xyt, totalXytAccumulated, remainingAmount) = _depositAndSwapNTimes(
            _forgeId, 
            _underlyingAsset, 
            _expiry, 
            _amount, 
            _n
        );

        require(totalXytAccumulated >= _minXytOut, "TooMuchSlippage_XYT");
        require((_amount.sub(remainingAmount) <= _underlyingMaxSpent), "TooMuchSlippage_Underlying");
        
        IERC20(xyt).transfer(msg.sender, totalXytAccumulated);
        emit YieldTokenCompound(_forgeId, _expiry, _amount, _n, totalXytAccumulated);
    }
    function _depositAndSwapNTimes(
        bytes32 _forgeId,
        address _underlying,
        uint256 _expiry,
        uint256 _amount,
        uint8 _n
    ) internal returns(address xyt, uint256 totalXytAccumulated, uint256 remainingAmount) {
        uint256 uAmount;
        for(uint8 i = 0; i < _n; ++i){
            //split underlying into ot and xyt
            (address _ot,address _xyt,
            uint256 amountMinted) = pendleRouter.tokenizeYield(
                _forgeId,
                _underlying,
                _expiry,
                _amount,
                address(this)
            );
            // assumes equal amount of xpt and ot are minted
            totalXytAccumulated += amountMinted;
            if(xyt == address(0)) xyt = _xyt;
            //swap ot for underlying on sushiswap
            address[] memory path = new address[](2);
            path[0] = _ot;
            path[1] = _underlying;
            uint[] memory amounts = sushiRouter.swapExactTokensForTokens(
                amountMinted,
                0,
                path,
                address(this),
                block.timestamp + MAX_VALUE
            );
            uAmount = amounts[1];
        }
        remainingAmount = uAmount;
    }
    function _approve(address _token, address _to) internal {
        if (IERC20(_token).allowance(address(this), _to) == 0)
            IERC20(_token).approve(_to, MAX_VALUE);
    }
}