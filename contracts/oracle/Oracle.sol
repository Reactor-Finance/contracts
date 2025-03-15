pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceSource} from "./interfaces/IPriceSource.sol";

contract Oracle is Ownable {
    error UnrecognizedPriceSource();

    IPriceSource[] public priceSources;

    event SetPriceSources(IPriceSource[] priceSources);

    constructor(IPriceSource[] memory _priceSources) Ownable(_msgSender()) {
        setPriceSources(_priceSources);
    }

    function _checkPriceSource(IPriceSource _priceSource) internal view {
        bool isRecognizedPriceSource;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];

            if (pS == _priceSource) {
                isRecognizedPriceSource = true;
                break;
            }
        }

        if (!isRecognizedPriceSource) revert UnrecognizedPriceSource();
    }

    function setPriceSources(IPriceSource[] memory _priceSources) public onlyOwner {
        priceSources = _priceSources;
        emit SetPriceSources(_priceSources);
    }

    function getAllPriceSources() external view returns (IPriceSource[] memory) {
        return priceSources;
    }

    function getAverageValueInUSD(address _token, uint256 _value) external view returns (uint256, int256) {
        uint256 _totalValueEXP;
        int256 _totalValueNormal;

        uint256 _divisor = 1;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (uint256 _valueEXP, int256 _valueNormal) = pS.getAverageValueInUSD(_token, _value);
            (_totalValueEXP, _totalValueNormal) = (_totalValueEXP + _valueEXP, _totalValueNormal + _valueNormal);

            if (_valueEXP != 0 && i != 0) {
                _divisor += 1;
            }
        }

        return (_totalValueEXP / _divisor, _totalValueNormal / int256(_divisor));
    }

    function getAverageValueInUSDBySource(
        IPriceSource _pS,
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgEXP, int256 _avgNormal) {
        _checkPriceSource(_pS);
        (_avgEXP, _avgNormal) = _pS.getAverageValueInUSD(_token, _value);
    }

    function getAverageValueInETH(address _token, uint256 _value) external view returns (uint256, int256) {
        uint256 _totalValueEXP;
        int256 _totalValueNormal;

        uint256 _divisor = 1;

        for (uint i = 0; i < priceSources.length; i++) {
            IPriceSource pS = priceSources[i];
            (uint256 _valueEXP, int256 _valueNormal) = pS.getValueInETH(_token, _value);
            (_totalValueEXP, _totalValueNormal) = (_totalValueEXP + _valueEXP, _totalValueNormal + _valueNormal);

            if (_valueEXP != 0 && i != 0) {
                _divisor += 1;
            }
        }

        return (_totalValueEXP / _divisor, _totalValueNormal / int256(_divisor));
    }

    function getValueInETH(
        IPriceSource _pS,
        address _token,
        uint256 _value
    ) external view returns (uint256 _avgEXP, int256 _avgNormal) {
        _checkPriceSource(_pS);
        (_avgEXP, _avgNormal) = _pS.getValueInETH(_token, _value);
    }
}
