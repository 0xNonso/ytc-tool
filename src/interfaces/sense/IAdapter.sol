    
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.0;

interface IAdapter {
    /// @notice Sense core Divider address
    function divider() external returns(address);

    /// @notice Target token to divide
    function target() external returns(address);

    /// @notice Underlying for the Target
    function underlying() external returns(address);

    /// @notice Deposits underlying `amount`in return for target. Must be overriden by child contracts
    /// @param amount Underlying amount
    /// @return amount of target returned
    function wrapUnderlying(uint256 amount) external returns (uint256);

    /// @notice Deposits target `amount`in return for underlying. Must be overriden by child contracts
    /// @param amount Target amount
    /// @return amount of underlying returned
    function unwrapTarget(uint256 amount) external returns (uint256);

    // /// @notice Loan `amount` target to `receiver`, and takes it back after the callback.
    // /// @param receiver The contract receiving target, needs to implement the
    // /// `onFlashLoan(address user, address adapter, uint256 maturity, uint256 amount)` interface.
    // /// @param amount The amount of target lent.
    // /// @param data (encoded adapter address, maturity and YT amount the use has sent in)
    // function flashLoan(
    //     IERC3156FlashBorrower receiver,
    //     address, /* fee */
    //     uint256 amount,
    //     bytes calldata data
    // ) external returns (bool)
}
    
