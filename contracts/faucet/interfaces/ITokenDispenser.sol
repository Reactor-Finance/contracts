pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenDispenser {
    function token() external view returns (IERC20);
    function nextRequest(address _user) external view returns (uint256);
    function amountDispensablePerUser() external view returns (uint256);
    function isBlocked(address _user) external view returns (bool);
    function dispense(address _to) external returns (bool);
    function retriever() external view returns (address);
    function initialize(address _token, uint256 _amountDispensable, address _retriever, uint256 _steps) external;
    function switchBlockStatus(address _account) external;
}
