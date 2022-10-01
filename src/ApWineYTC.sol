// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/apwine/IAMM.sol";
import "./interfaces/apwine/IAMMRouter.sol";
import "./interfaces/apwine/IIBTDeposit.sol";
import "./interfaces/apwine/IController.sol";
import "./interfaces/apwine/IFutureVault.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
import "@balancer-labs/v2-vault/contracts/interfaces/IFlashLoanRecipient.sol";

///@title Yield Token Compounding using Apwine.fi
///@author nonso
contract ApWineYTC is IFlashLoanRecipient, ReentrancyGuard {
    using SafeMath for uint256;

    ///@notice ApWine AMM Router Interface
    IAMMRouter public immutable AMM_ROUTER;
    ///@notice Balancer Vault Interface
    IVault public immutable VAULT ;
    ///@notice ApWine Controller address 
    address public immutable CONTROLLER ;
    ///@notice max value
    uint256 public constant MAX_VALUE = type(uint).max;
    ///@notice pair 0 = PT/Underling
    uint256[] public pairPath = [0];
    ///@notice token path [0,1] =  PT --> Underlying
    uint256[] public tokenPath = [0,1];

    //EVENTS
    event YieldTokenCompound(address indexed _amm, uint256 underlyingIn, uint8 numOfCompounding, uint256 fytOut);
  
    constructor(
        address _ammRouter,
        address _vault,
        address _controller
    ) ReentrancyGuard() {
        AMM_ROUTER = IAMMRouter(_ammRouter);
        VAULT = IVault(_vault);
        CONTROLLER = _controller;
    }

    ///@notice Perform yield token compounding `_n` times using `_amount`
    ///@param _amm AMM address
    ///@param _amount Amount to use
    ///@param _fytMinAmtOut minimum amount of future yield token expected 
    ///@param _n Number of times to compound
    function ytc(
        IAMM _amm,
        IIBTDeposit ibtDeposit,
        uint256 _amount,
        uint256 _fytMinAmtOut,
        uint256 _ibtMaxAmtSpent,
        uint8   _n
    ) external nonReentrant() {
        address _underlyingToken = IAMM(_amm).getUnderlyingOfIBTAddress();
        require(_underlyingToken == ibtDeposit.getUnderlying());

        IERC20(_underlyingToken).transferFrom(msg.sender, address(this), _amount);
        //ytc
        (, uint256 _remainingAmount) =  _ytc(
            _amm,
            ibtDeposit,
            _amount,
            _fytMinAmtOut,
            _ibtMaxAmtSpent,
            msg.sender,
            _n
        );
       
        if(_remainingAmount > 0) IERC20(_underlyingToken).transfer(msg.sender, _remainingAmount);
    }

    ///@notice Perform yield token compounding `_n` times using `_amount`
    ///@dev Borrow `_amount` from balancer's vault to perform yield token compounding
    ///@param _amm AMM address
    ///@param _amount Amount to borrow
    ///@param _fytMinAmtOut minimum amount of future yield token expected 
    ///@param _n Number of times to compound
    function ytcWithFlashloan(
        IAMM _amm,
        IIBTDeposit _ibtDeposit,
        uint256 _amount,
        uint256 _fytMinAmtOut,
        uint256 _ibtMaxAmtSpent,
        uint8 _n
    ) external nonReentrant() {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(IAMM(_amm).getUnderlyingOfIBTAddress());
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        bytes memory userData = abi.encode(_amm, _ibtDeposit, msg.sender, _fytMinAmtOut, _ibtMaxAmtSpent,  _n);
        // perform flashloan
        VAULT.flashLoan(this, tokens, amounts, userData);
    }

    // Handle flashloan
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory ,
        bytes memory userData
    ) external override {
        require(msg.sender == address(VAULT), "InvalidSender");
        (IAMM _amm, IIBTDeposit _ibtDeposit, address _user, uint256 _fytMinAmtOut, uint256 _ibtMaxAmtSpent, uint8 _n) = abi.decode(userData,(IAMM, IIBTDeposit, address, uint256, uint256, uint8));
        (, uint256 _remainingAmount) = _ytc(
            _amm,
            _ibtDeposit,
            amounts[0],
            _fytMinAmtOut,
            _ibtMaxAmtSpent,
            _user,
            _n
        );
        // transfer total amount of token spent from sender's account to balancer vault 
        tokens[0].transferFrom(_user, address(VAULT), amounts[0].sub(_remainingAmount));
        // transfer remaining balance of flashloaned token from this contract to balancer vault
        tokens[0].transfer(address(VAULT), _remainingAmount);
    }

    ///@notice Perform yield token compounding `_n` times using `_amount`
    ///@param _amm AMM address
    ///@param _amount Amount to use for compounding 
    ///@param _user Beneficiary' address
    ///@param _n - number of times to compound
    ///@return totalYtAccumulated Amount of future yield token accumulated 
    ///@return remainingAmount balance of `_amount` left after compounding
    function _ytc(
        IAMM _amm,
        IIBTDeposit _ibtDeposit,
        uint256 _amount,
        uint256 _fytMinAmtOut,
        uint256 _underlyingMaxSpent,
        address _user,
        uint8   _n
    ) internal returns(uint256 totalYtAccumulated, uint256 remainingAmount) {
        require(_n > 0 && _n < 25, "N_OutOfBounds");
        require(_amount > 0, "ZeroAmount");

        address futureVault = _amm.getFutureAddress();
        address ptToken = _amm.getPTAddress();
        address fytToken = _amm.getFYTAddress();
        address underlyingToken = _amm.getUnderlyingOfIBTAddress();
        address ibtToken = IFutureVault(futureVault).getIBTAddress();

        //approve deposit
        _approve(underlyingToken, address(_ibtDeposit));
        _approve(ibtToken, CONTROLLER);
        //approve swap
        _approve(ptToken, address(AMM_ROUTER));

        (totalYtAccumulated, remainingAmount) = _depositAndSwapNTimes(
            _amm,
            _ibtDeposit,
            _amount, 
            futureVault, 
            ptToken,
            fytToken, 
            _n
        );

        require(totalYtAccumulated >= _fytMinAmtOut, "TooMuchSlippage_FYT");
        require((_amount.sub(remainingAmount) <= _underlyingMaxSpent), "TooMuchSlippage_Underlying");
        
        IERC20(fytToken).transfer(_user, totalYtAccumulated);

        emit YieldTokenCompound(address(_amm), _amount, _n, totalYtAccumulated);
    }

    ///@notice Swap principal token to interest bearing token
    ///@param _amm - AMM address
    ///@param _pt - amount of principal token to swap
    function _swapPtToUnderlying(IAMM _amm, uint256 _pt, address _to) internal returns(uint256){
        return IAMMRouter(AMM_ROUTER).swapExactAmountIn(
            _amm,
            pairPath, // Pool 0 is PT/Underlying, Pool 1 is PT/FYT
            tokenPath, // Token 0 is always PT. Here, we swap from PT to Underlying
            _pt,
            1,
            _to,
            block.timestamp + 15 seconds, // Set max deadline
            address(0)
        );
    }

    ///@notice deposit interest bearing token into controller's `_futureVault`
    ///@param _futureVault - Future vault address
    ///@param _ptToken - Principal token address
    ///@param _fytToken - Future yield token address
    ///@param _amount - Amount to deposit into `_futureVault`
    ///@return _pt Amount of principal token recieved 
    ///@return _fyt Amount of future yield token recieved 
    function _deposit(
        IIBTDeposit _ibtDeposit,
        address _futureVault, 
        address _ptToken,
        address _fytToken,
        uint256 _amount
    ) internal returns(uint256 _pt, uint256 _fyt) {
        uint256 initialPtBalance = IERC20(_ptToken).balanceOf(address(this));
        uint256 initialYtBalance = IERC20(_fytToken).balanceOf(address(this));

        // convert underlying to interest bearing token
        uint256 depAmt = _ibtDeposit.deposit(_amount);    
        // deposit into future vault
        IController(CONTROLLER).deposit(_futureVault, depAmt);

        _pt = IERC20(_ptToken).balanceOf(address(this)).sub(initialPtBalance);
        _fyt = IERC20(_fytToken).balanceOf(address(this)).sub(initialYtBalance);
    }

    function _depositAndSwapNTimes(
        IAMM _amm,
        IIBTDeposit _ibtDeposit,
        uint256 _amount,
        address _futureVault,
        address _ptToken,
        address _fytToken,
        uint8 _n
    ) internal returns(uint256 totalYtAccumulated, uint256 remainingAmount) {
        uint256 _cacheAmount = _amount;
        for(uint8 i = 0; i < _n; ++i){
            (uint256 _pt, uint256 _fyt) = _deposit(_ibtDeposit, _futureVault, _ptToken, _fytToken, _cacheAmount);
            totalYtAccumulated += _fyt;
            
            _cacheAmount = _swapPtToUnderlying(_amm, _pt, address(this));
        }
        remainingAmount = _cacheAmount;
    }

    function _approve(address _token, address _to) internal {
        if (IERC20(_token).allowance(address(this), _to) == 0)
            IERC20(_token).approve(_to, MAX_VALUE);
    }

}
