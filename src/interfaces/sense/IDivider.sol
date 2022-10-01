// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.0;
interface IDivider {
    function periphery() external returns(address);

    /// @notice Mint Principal & Yield Tokens of a specific Series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series [unix time]
    /// @param tBal Balance of Target to deposit
    /// @dev The balance of PTs and YTs minted will be the same value in units of underlying (less fees)
    function issue(
        address adapter,
        uint256 maturity,
        uint256 tBal
    ) external returns (uint256 uBal);

    /// @notice Reconstitute Target by burning PT and YT
    /// @dev Explicitly burns YTs before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of PT and YT to burn
    function combine(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external returns (uint256 tBal);

    /// @notice Burn PT of a Series once it's been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Amount of PT to burn, which should be equivalent to the amount of Underlying owed to the caller
    function redeem(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external returns (uint256 tBal);

    /// @notice Returns address of Principal Token
    function pt(address adapter, uint256 maturity) external view returns (address);

    /// @notice Returns address of Yield Token
    function yt(address adapter, uint256 maturity) external view returns (address);
}