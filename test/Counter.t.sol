// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "src/EigenChecker.sol";

contract CounterTest is Test {
    EigenChecker checker = new EigenChecker();

    function setUp() public {
        
        deal(address(checker.WETH()), address(checker), 1000);
        console.log('balance',checker.WETH().balanceOf(address(checker)));
        console.log('here');
    }

    function testFlow() public {
        uint shares = checker.deposit(1000);
        console.log('Shares received', shares);
        (uint nonce, uint blockNum, bytes32 withdrawalHash) = checker.requestWithdraw(1000);

        console.log('withdrawalHash');
        console.logBytes32(withdrawalHash);

        vm.roll(blockNum + 11);

        checker.completeWithdrawal(1000, nonce, blockNum);
    }

    

}
