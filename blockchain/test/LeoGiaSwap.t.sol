// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LeoGiaSwap.sol";
import "../src/SwapRouter.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

/*//////////////////////////////////////////////////////////////
                    MOCK TOKEN FOR TESTING
//////////////////////////////////////////////////////////////*/
contract MockERC20 is ERC20 {
    constructor(string memory n, string memory s) ERC20(n, s) {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract LeoGiaSwapTest is Test {
    MockERC20 leo;
    MockERC20 gia;
    LeoGiaSwap swap;
    SwapRouter router;

    address user = address(0x123);

    function setUp() public {
        leo = new MockERC20("LEO", "LEO");
        gia = new MockERC20("GIA", "GIA");

        swap = new LeoGiaSwap(address(leo), address(gia));
        router = new SwapRouter(address(swap));

        // Owner adds liquidity
        leo.approve(address(swap), 100_000 ether);
        gia.approve(address(swap), 50_000 ether);
        swap.addLiquidity(100_000 ether, 50_000 ether);

        // Fund user
        leo.transfer(user, 10_000 ether);
        gia.transfer(user, 10_000 ether);
    }

    function testSwapLeoForGiaWithSlippage() public {
        vm.startPrank(user);

        leo.approve(address(router), 1_000 ether);

        uint256 minOut = 480 ether;

        router.swapLeoForGia(1_000 ether, minOut);

        vm.stopPrank();

        assertGt(gia.balanceOf(user), minOut);
    }

    function testSwapRevertsOnHighMinOut() public {
        vm.startPrank(user);

        leo.approve(address(router), 1_000 ether);

        vm.expectRevert("Slippage exceeded");
        router.swapLeoForGia(1_000 ether, 600 ether);

        vm.stopPrank();
    }
}
