// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/token/HorizCoinToken.sol";

contract TokenTest is Test {
    HorizCoinToken token;
    address owner = address(0xA11CE);
    address user1 = address(0xBEEF);
    address user2 = address(0xC0FFEE);

    uint256 constant MAX_SUPPLY = 1_000_000 ether;

    function setUp() public {
        vm.prank(owner);
        token = new HorizCoinToken("HorizCoin", "HORIZ", MAX_SUPPLY);
    }

    function testInitialParameters() public {
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertEq(token.totalSupply(), 0);
        assertEq(token.name(), "HorizCoin");
        assertEq(token.symbol(), "HORIZ");
        assertEq(token.owner(), owner);
    }

    function testMintByOwner() public {
        vm.prank(owner);
        token.mint(user1, 100 ether);
        assertEq(token.balanceOf(user1), 100 ether);
        assertEq(token.totalSupply(), 100 ether);
    }

    function testMintRevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(); // Ownable unauthorized revert
        token.mint(user1, 1 ether);
    }

    function testCapEnforced() public {
        vm.startPrank(owner);
        token.mint(user1, MAX_SUPPLY);
        assertEq(token.totalSupply(), MAX_SUPPLY);
        vm.expectRevert(bytes("Cap exceeded"));
        token.mint(user1, 1);
        vm.stopPrank();
    }

    function testDelegateVotingPower() public {
        vm.startPrank(owner);
        token.mint(user1, 1_000 ether);
        vm.stopPrank();

        vm.prank(user1);
        token.delegate(user1);

        // After delegation, voting power should equal balance
        assertEq(token.getVotes(user1), 1_000 ether);
    }

    function testTransferUpdatesVotes() public {
        vm.startPrank(owner);
        token.mint(user1, 1_000 ether);
        vm.stopPrank();

        vm.prank(user1);
        token.delegate(user1);

        assertEq(token.getVotes(user1), 1_000 ether);

        vm.prank(user1);
        token.transfer(user2, 400 ether);

        // votes move with balance because user1 keeps delegation to self; user2 has not delegated
        assertEq(token.getVotes(user1), 600 ether);
        assertEq(token.getVotes(user2), 0);
    }

    // (Optional) A fuzz test for mint boundaries
    function testFuzz_MintWithinCap(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);
        vm.prank(owner);
        token.mint(user1, amount);
        assertEq(token.totalSupply(), amount);
    }
}