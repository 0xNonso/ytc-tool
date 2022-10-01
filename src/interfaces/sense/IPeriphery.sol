// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.7.0;
interface IPeriphery {
    
    /// @notice Swap Target to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param tBal Balance of Target to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapTargetForPTs(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal);

    /// @notice Swap Underlying to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of Underlying to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapUnderlyingForPTs(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal);

    /// @notice Swap Target to Yield Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param targetIn Balance of Target to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapTargetForYTs(
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal);

    /// @notice Swap Underlying to Yield of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param underlyingIn Balance of Underlying to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapUnderlyingForYTs(
        address adapter,
        uint256 maturity,
        uint256 underlyingIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal);

    /// @notice Swap Principal Tokens for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 tBal);

    /// @notice Swap Principal Tokens for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 uBal);

    /// @notice Swap YT for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 tBal);

    /// @notice Swap YT for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 uBal);
}