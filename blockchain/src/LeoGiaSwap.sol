// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

/**
 * @title LeoGiaSwap
 * @notice AMM pool for LEO ↔ GIA with 0.3% fee, slippage protection, and events
 * @dev Router pulls tokens, this contract NEVER uses transferFrom in swaps
 */
contract LeoGiaSwap is Ownable {
    /*//////////////////////////////////////////////////////////////
                                TOKENS
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable leo;
    IERC20 public immutable gia;

    /*//////////////////////////////////////////////////////////////
                               RESERVES
    //////////////////////////////////////////////////////////////*/

    uint256 public leoReserve;
    uint256 public giaReserve;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LiquidityAdded(
        address indexed provider,
        uint256 leoAmount,
        uint256 giaAmount
    );

    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _leo, address _gia) Ownable() {
        require(_leo != address(0) && _gia != address(0), "Zero address");

        leo = IERC20(_leo);
        gia = IERC20(_gia);
    }

    /*//////////////////////////////////////////////////////////////
                          LIQUIDITY (OWNER)
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(
        uint256 leoAmount,
        uint256 giaAmount
    ) external onlyOwner {
        require(leoAmount > 0 && giaAmount > 0, "Invalid amounts");

        // Owner must approve this contract beforehand
        leo.transferFrom(msg.sender, address(this), leoAmount);
        gia.transferFrom(msg.sender, address(this), giaAmount);

        leoReserve += leoAmount;
        giaReserve += giaAmount;

        emit LiquidityAdded(msg.sender, leoAmount, giaAmount);
    }

    /*//////////////////////////////////////////////////////////////
                       SWAPS WITH SLIPPAGE PROTECTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Swap LEO → GIA with minimum output protection
     * @dev Router must transfer LEO to this contract BEFORE calling
     */
    function swapLeoForGiaWithMinOut(
        uint256 leoIn,
        uint256 minGiaOut
    ) external {
        require(leoIn > 0, "Invalid input");

        uint256 giaOut = getAmountOut(leoIn, leoReserve, giaReserve);
        require(giaOut >= minGiaOut, "Slippage exceeded");

        // Send GIA to user
        gia.transfer(msg.sender, giaOut);

        // Update reserves
        leoReserve += leoIn;
        giaReserve -= giaOut;

        emit SwapExecuted(
            msg.sender,
            address(leo),
            address(gia),
            leoIn,
            giaOut
        );
    }

    /**
     * @notice Swap GIA → LEO with minimum output protection
     * @dev Router must transfer GIA to this contract BEFORE calling
     */
    function swapGiaForLeoWithMinOut(
        uint256 giaIn,
        uint256 minLeoOut
    ) external {
        require(giaIn > 0, "Invalid input");

        uint256 leoOut = getAmountOut(giaIn, giaReserve, leoReserve);
        require(leoOut >= minLeoOut, "Slippage exceeded");

        leo.transfer(msg.sender, leoOut);

        giaReserve += giaIn;
        leoReserve -= leoOut;

        emit SwapExecuted(
            msg.sender,
            address(gia),
            address(leo),
            giaIn,
            leoOut
        );
    }

    /*//////////////////////////////////////////////////////////////
                        AMM MATH (0.3% FEE)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates output amount using constant-product formula
     * @dev Includes 0.3% fee (997 / 1000)
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "No liquidity");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }
}
