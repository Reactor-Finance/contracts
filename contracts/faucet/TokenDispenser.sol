pragma solidity ^0.8.0;

import {ITokenDispenser} from "./interfaces/ITokenDispenser.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/TransferHelper.sol";

contract TokenDispenser is ITokenDispenser {
    using SafeERC20 for IERC20;

    address public ETHER;

    IERC20 public token;
    address public retriever;
    address public faucet;
    mapping(address => uint256) public nextRequest;
    mapping(address => bool) public isBlocked;
    uint256 public amountDispensablePerUser;
    bool public initialized;
    uint256 internal TIMESTAMP_STEPS;

    // Errors
    error AlreadyInitialized();
    error Blocked(address);
    error WaitUntilTimestamp(uint256);
    error OnlyRetriever();
    error FaucetNonZero();
    error OnlyFaucet();

    // Events
    event Dispensed(address indexed _to, uint256 indexed _amount, uint256 indexed _timestamp);

    // Modifiers
    modifier blockedNotAllowed(address _user) {
        if (isBlocked[_user]) revert Blocked(_user);
        _;
    }

    modifier untilTimestamp(address _user) {
        uint256 _nextRequest = nextRequest[_user];
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp < _nextRequest) revert WaitUntilTimestamp(_nextRequest);
        _;
    }

    modifier onlyRetriever() {
        if (msg.sender != retriever) revert OnlyRetriever();
        _;
    }

    modifier onlyFaucet() {
        if (msg.sender != faucet) revert OnlyFaucet();
        _;
    }

    constructor() {}

    function initialize(
        address _token,
        uint256 _amountDispensablePerUser,
        address _retriever,
        uint256 _steps
    ) external {
        if (initialized) revert AlreadyInitialized();
        if (faucet != address(0)) revert FaucetNonZero();

        ETHER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        token = IERC20(_token);
        amountDispensablePerUser = _amountDispensablePerUser;
        retriever = _retriever;
        TIMESTAMP_STEPS = _steps;
        faucet = msg.sender;
        initialized = true;
    }

    function dispense(
        address _to
    ) external blockedNotAllowed(_to) untilTimestamp(_to) onlyFaucet returns (bool success) {
        // Check balance of dispenser
        if (address(token) != ETHER) {
            bytes4 selector = bytes4(keccak256(bytes("balanceOf(address)")));
            (bool s, bytes memory balanceData) = address(token).staticcall(
                abi.encodeWithSelector(selector, address(this))
            );
            require(s, "Could not check faucet balance");
            uint256 balance = abi.decode(balanceData, (uint256));
            success = balance >= amountDispensablePerUser;
            if (success) {
                token.safeTransfer(_to, amountDispensablePerUser);
            }
        } else {
            uint256 balance = address(this).balance;
            success = balance >= amountDispensablePerUser;
            if (success) {
                TransferHelper._safeTransferEther(_to, amountDispensablePerUser);
            }
        }

        if (success) {
            nextRequest[_to] = block.timestamp + TIMESTAMP_STEPS;
            emit Dispensed(_to, amountDispensablePerUser, block.timestamp);
        }
    }

    function retrieveERC20(IERC20 _token, uint256 amount) external onlyRetriever {
        _token.safeTransfer(msg.sender, amount);
    }

    function retrieveETHER(uint256 amount) external onlyRetriever {
        TransferHelper._safeTransferEther(msg.sender, amount);
    }

    function setRetriever(address _retriever) external onlyRetriever {
        require(_retriever != retriever, "Already retriever");
        retriever = _retriever;
    }

    function switchBlockStatus(address _account) external onlyFaucet {
        isBlocked[_account] = !isBlocked[_account];
    }

    receive() external payable {}
}
