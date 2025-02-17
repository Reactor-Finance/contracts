pragma solidity ^0.8.0;

interface IPriceSource {
    function name() external view returns (string memory);
    function usdt() external view returns (address);
    function usdc() external view returns (address);
    function weth() external view returns (address);

    function getAverageValueInUSD(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal);
    function getValueInETH(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal);
}
