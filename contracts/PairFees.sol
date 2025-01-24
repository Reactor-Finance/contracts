// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TransferHelper} from "./libraries/TransferHelper.sol";

// Pair Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract PairFees {
    address internal immutable pair; // The pair it is bonded to
    address internal immutable token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pair, saved localy and statically for gas optimization

    constructor(address _token0, address _token1) {
        pair = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint amount0, uint amount1) external {
        require(msg.sender == pair);
        if (amount0 > 0) TransferHelper._safeTransferERC20(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper._safeTransferERC20(token1, recipient, amount1);
    }
}
