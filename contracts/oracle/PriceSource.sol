pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";

abstract contract PriceSource is Ownable, IPriceSource {
    string public name;
    address public usdt;
    address public usdc;
    address public weth;

    constructor(string memory _name, address _usdt, address _usdc, address _weth) Ownable(_msgSender()) {
        name = _name;
        usdt = _usdt;
        usdc = _usdc;
        weth = _weth;
    }

    function _getUnitValueInETH(address _token) internal view virtual returns (uint256);
    function _getUnitValueInUSDT(address _token) internal view virtual returns (uint256);
    function _getUnitValueInUSDC(address _token) internal view virtual returns (uint256);

    function getAverageValueInUSD(
        address _token,
        uint256 _value
    ) public view returns (uint256 _avgExp, int256 _avgNormal) {
        uint256 usdtValue = _getUnitValueInUSDT(_token) * _value;
        uint256 usdcValue = _getUnitValueInUSDC(_token) * _value;
        uint8 _decimal = ERC20(_token).decimals();

        uint8 usdcDecimals = ERC20(usdc).decimals();
        uint8 usdtDecimals = ERC20(usdt).decimals();

        uint256 sum = (((usdcValue / 10 ** usdcDecimals) + (usdtValue / 10 ** usdtDecimals)) * 10 ** 18) /
            10 ** _decimal;
        uint256 average = usdcValue == 0 || usdtValue == 0 ? sum / 1 : sum / 2;
        int256 averageAsInt256 = int256((average * 10 ** 4) / 10 ** 18);
        _avgExp = average;
        _avgNormal = averageAsInt256;
    }

    function getValueInETH(
        address _token,
        uint256 _value
    ) external view returns (uint256 _exponentiated, int256 _normal) {
        uint256 valueInETH = _getUnitValueInETH(_token) * _value;
        uint8 _decimal = ERC20(_token).decimals();
        _exponentiated = valueInETH / 10 ** _decimal;
        _normal = int256((_exponentiated * 10 ** 4) / 10 ** 18);
    }
}
