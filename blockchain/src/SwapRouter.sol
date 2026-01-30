// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {LeoGiaSwap} from "./LeoGiaSwap.sol";

/**
 * @title SwapRouter
 * @notice Single entry point for users (UI → Router → Pool)
 */
contract SwapRouter {
    LeoGiaSwap public immutable swap;

    constructor(address _swap) {
        require(_swap != address(0), "Zero address");
        swap = LeoGiaSwap(_swap);
    }

    /*//////////////////////////////////////////////////////////////
                        ROUTER SWAPS
    //////////////////////////////////////////////////////////////*/

    function swapLeoForGia(
        uint256 amountIn,
        uint256 minGiaOut
    ) external {
        // Pull LEO from user → pool
        IERC20(swap.leo()).transferFrom(
            msg.sender,
            address(swap),
            amountIn
        );

        // Execute swap with slippage protection
        swap.swapLeoForGiaWithMinOut(amountIn, minGiaOut);
    }

    function swapGiaForLeo(
        uint256 amountIn,
        uint256 minLeoOut
    ) external {
        IERC20(swap.gia()).transferFrom(
            msg.sender,
            address(swap),
            amountIn
        );

        swap.swapGiaForLeoWithMinOut(amountIn, minLeoOut);
    }
}
