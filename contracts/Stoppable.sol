pragma solidity ^0.5.0;

import "./Ownable.sol";

contract Stoppable is Ownable {

    bool private _isRunning;
    bool private _isAlive;
    event LogPausedContract(address indexed sender);
    event LogResumedContract(address indexed sender);
    event LogKilledContract(address indexed sender);

    modifier onlyIfRunning {
        require(_isRunning && _isAlive, "E_NR");
        _;
    }
    
    modifier onlyIfPaused {
        require(!_isRunning && _isAlive, "E_NP");
        _;
    }

    constructor(bool initialRunState) public {
        _isRunning = initialRunState;
        _isAlive = true;
    }

    function isRunning() public view returns(bool) {
        return _isRunning;
    }

    function isAlive() public view returns(bool) {
        return _isAlive;
    }

    function pauseContract() public onlyOwnerAccess onlyIfRunning returns(bool success) {
        _isRunning = false;
        emit LogPausedContract(msg.sender);
        return true;
    }

    function resumeContract() public onlyOwnerAccess onlyIfPaused returns(bool success) {
        _isRunning = true;
        emit LogResumedContract(msg.sender);
        return true;
    }

    function killContract() public onlyIfPaused onlyOwnerAccess returns(bool success) {
        _isAlive = false;
        emit LogKilledContract(msg.sender);
        return true;
    }

}