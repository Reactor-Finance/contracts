pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library TransferHelper {
    using Address for address;

    // Selectors
    bytes4 private transferSelector = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private transferFromSelector = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function _safeTransferEther(address to, uint256 amount) internal returns (bool success) {
        (success, ) = to.call{value: amount}(new bytes(0));
        require(success, "failed to transfer ether");
    }

    function _safeTransferERC20(
        address token,
        address to,
        uint256 amount
    ) internal return (bytes memory _returnData) {
        require(token.isContract(), "non contract call");
        _returnData = token.functionCall(
            abi.encodeWithSelector(transferSelector, to, amount)
        );
    }

    function _safeTransferFromERC20(
        address token,
        address spender,
        address recipient,
        uint256 amount
    ) internal returns (bytes memory _returnData) {
        require(token.isContract(), "non contract call");
        _returnData = token.functionCall(
            abi.encodeWithSelector(
                transferFromSelector,
                spender,
                recipient,
                amount
            )
        )
    }
}