pragma solidity ^0.5.0;

import "./Ownable.sol";

contract Stoppable is Ownable {

    bool private isRunning;
    event LogPausedContract(address indexed sender);
    event LogResumedContract(address indexed sender);

    modifier onlyIfRunning {
        require(isRunning, "E_NR");
        _;
    }
    
    modifier onlyIfPaused {
        require(!isRunning, "E_NP");
        _;
    }

    constructor(bool initialRunState) public {
        isRunning = initialRunState;
    }

    function pauseContract() public onlyOwnerAccess onlyIfRunning returns(bool success) {
        isRunning = false;
        emit LogPausedContract(msg.sender);
        return true;
    }

    function resumeContract() public onlyOwnerAccess onlyIfPaused returns(bool success) {
        isRunning = true;
        emit LogResumedContract(msg.sender);
        return true;
    }

}