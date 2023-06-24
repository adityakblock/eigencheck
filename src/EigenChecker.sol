// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./IStrategyManager.sol";
import "./IDelegationManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract EigenChecker {
    IStrategyManager public strategyManager =
        IStrategyManager(0x779d1b5315df083e3F9E94cB495983500bA8E907);

    IStrategy public WETHStrategy =
        IStrategy(0x7CA911E83dabf90C90dD3De5411a10F1A6112184);

    IERC20 public WETH = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    IDelegationManager public delegate = IDelegationManager(
        0x1b7b8F6b258f95Cf9596EabB9aa18B62940Eb0a8
    );

    function deposit(uint wad) public returns (uint) {
        WETH.approve(address(strategyManager), wad);
        return (
            strategyManager.depositIntoStrategy(
                address(WETHStrategy),
                address(WETH),
                wad
            )
        );
    }

    function requestWithdraw(
        uint shares
    ) public returns (uint nonce, uint blockNum, bytes32 withdrawalHash) {
        blockNum = block.number;
        nonce = strategyManager.numWithdrawalsQueued(address(this));

        uint[] memory strategyIndexes = new uint[](1);
        strategyIndexes[0] = 0;
        address[] memory strategies = new address[](1);
        strategies[0] = address(WETHStrategy);
        uint[] memory sharesList = new uint[](1);
        sharesList[0] = shares;
        address withdrawer = address(this);
        bool undelegateIfPossible = false;

        IStrategyManager.WithdrawerAndNonce
            memory withdrawerAndNonce = IStrategyManager.WithdrawerAndNonce({
                withdrawer: address(this),
                nonce: uint96(nonce)
            });

        IStrategyManager.QueuedWithdrawal
            memory queuedWithdrawal = IStrategyManager.QueuedWithdrawal({
                strategies: strategies,
                shares: sharesList,
                depositor: address(this),
                withdrawerAndNonce: withdrawerAndNonce,
                withdrawalStartBlock: uint32(block.number),
                delegatedAddress: delegate.delegatedTo(address(this))
            });

        bytes32 calculatedhash = strategyManager.calculateWithdrawalRoot(
            queuedWithdrawal
        );

        withdrawalHash = strategyManager.queueWithdrawal(
            strategyIndexes,
            strategies,
            sharesList,
            withdrawer,
            undelegateIfPossible
        );

        assert (calculatedhash == withdrawalHash);
        console.log("calculatedhash");
        console.logBytes32(calculatedhash);
        console.log("withdrawalHash");
        console.logBytes32(withdrawalHash);
    }

    function completeWithdrawal(
        uint shareAmt,
        uint nonce,
        uint blockNum
    ) public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(WETHStrategy);

        uint[] memory tokenShares = new uint[](1);
        tokenShares[0] = shareAmt;

        IStrategyManager.WithdrawerAndNonce
            memory withdrawerAndNonce = IStrategyManager.WithdrawerAndNonce({
                withdrawer: address(this),
                nonce: uint96(nonce)
            });

        IStrategyManager.QueuedWithdrawal
            memory queuedWithdrawal = IStrategyManager.QueuedWithdrawal({
                strategies: strategies,
                shares: tokenShares,
                depositor: address(this),
                withdrawerAndNonce: withdrawerAndNonce,
                withdrawalStartBlock: uint32(blockNum),
                delegatedAddress: delegate.delegatedTo(address(this))
            });

        address[] memory tokens = new address[](1);
        tokens[0] = address(WETH);

        strategyManager.completeQueuedWithdrawal(
            queuedWithdrawal,
            tokens,
            0,
            false
        );
    }
}
