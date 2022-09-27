// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
interface IIBTDeposit {
    function deposit(uint256 _amount) external returns(uint256);
    function getUnderlying() external returns(address);
    function getIBT() external returns(address);
}