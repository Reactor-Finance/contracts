pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenDispenser.sol";

contract Faucet is Ownable {
    // Variables
    address public implementation;
    mapping(address => bool) public isLegitimateDispenser;
    address[] public dispensers;

    // Errors
    error OnlyLegitimateDispenser();
    error InsufficientDispenserBalance();

    // Modifiers
    modifier onlyLegitimateDispenser(address dispenser) {
        if (!isLegitimateDispenser[dispenser]) revert OnlyLegitimateDispenser();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function deployDispenser(
        address _token,
        uint256 _amount,
        address _retriever,
        uint256 _steps
    ) external onlyOwner returns (address dispenser) {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, _token, _steps));
        dispenser = Clones.cloneDeterministic(implementation, salt);
        // Initialize
        ITokenDispenser(dispenser).initialize(_token, _amount, _retriever, _steps);
        isLegitimateDispenser[dispenser] = true;
        dispensers.push(dispenser);
    }

    function mint(address dispenser) external onlyLegitimateDispenser(dispenser) {
        bool passedCall = true;
        string memory failureReason;
        try ITokenDispenser(dispenser).dispense(msg.sender) returns (bool success) {
            if (!success) revert InsufficientDispenserBalance();
        } catch Error(string memory reason) {
            passedCall = false;
            failureReason = reason;
        } catch {
            passedCall = false;
            failureReason = "Minting failed for unknown reasons";
        }

        require(passedCall, failureReason);
    }

    function allDispensers() external view returns (address[] memory) {
        return dispensers;
    }
}
