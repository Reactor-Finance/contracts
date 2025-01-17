// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IPairFactory.sol";
import {IPair} from "../interfaces/IPair.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract PairFactory is IPairFactory {
    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public stakingNFTFee;
    uint256 public MAX_REFERRAL_FEE = 1200; // 12%
    uint256 public constant MAX_FEE = 25; // 0.25%

    address public feeManager;
    address public pendingFeeManager;
    address public dibs; // referral fee handler
    address public stakingFeeHandler; // staking fee handler

    address public implementation;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint);

    constructor(address _implementation) {
        pauser = msg.sender;
        isPaused = false;
        feeManager = msg.sender;
        stableFee = 4; // 0.04%
        volatileFee = 18; // 0.18%
        stakingNFTFee = 3000; // 30% of stable/volatileFee
        implementation = _implementation;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function pairs() external view returns (address[] memory) {
        return allPairs;
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, "not fee manager");
        pendingFeeManager = _feeManager;
    }

    function acceptFeeManager() external {
        require(msg.sender == pendingFeeManager, "not pending fee manager");
        feeManager = pendingFeeManager;
    }

    function setStakingFees(uint256 _newFee) external {
        require(msg.sender == feeManager, "not fee manager");
        require(_newFee <= 3000);
        stakingNFTFee = _newFee;
    }

    function setStakingFeeAddress(address _feehandler) external {
        require(msg.sender == feeManager, "not fee manager");
        require(_feehandler != address(0), "addr 0");
        stakingFeeHandler = _feehandler;
    }

    function setDibs(address _dibs) external {
        require(msg.sender == feeManager, "not fee manager");
        require(_dibs != address(0), "address zero");
        dibs = _dibs;
    }

    function setReferralFee(uint256 _refFee) external {
        require(msg.sender == feeManager, "not fee manager");
        MAX_REFERRAL_FEE = _refFee;
    }

    function setFee(bool _stable, uint256 _fee) external {
        require(msg.sender == feeManager, "not fee manager");
        require(_fee <= MAX_FEE, "fee too high");
        require(_fee != 0, "fee must be non-zero");
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
    }

    function getFee(bool _stable) public view returns (uint256) {
        return _stable ? stableFee : volatileFee;
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(tokenA != tokenB, "identical addresses");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "zero address");
        require(getPair[token0][token1][stable] == address(0), "pair exists");
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable));
        pair = Clones.cloneDeterministic(implementation, salt);
        IPair(pair).initialize(token0, token1, stable); // Initialize pair
        getPair[token0][token1][stable] = pair; // Populate mapping
        getPair[token1][token0][stable] = pair; // Populate mapping in reverse
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}
