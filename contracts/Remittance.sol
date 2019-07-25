pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    mapping (bytes32 => TxInfo) remittances;
    event LogDeposited(address indexed sender, address indexed dst, uint amount, uint deadline);
    event LogWithdrew(address indexed sender, address indexed dst, uint amount);
    event LogReclaimed(address indexed sender, address indexed dst, uint amount, uint deadline);

    struct TxInfo {
        address payable sender;
        address payable dst;
        uint amount;
        uint deadline;
    }

    constructor(bool initialRunState) public Stoppable(initialRunState) {}

    modifier sufficientIncomingFunds {
        require(msg.value > 0, "E_IF");
        _;
    }

    modifier onlyIfTxExists(bytes32 pwHash) {
        require(txExists(pwHash), "E_TNF");
        _;
    }

    // Helper function to find a Tx struct
    function txExists(bytes32 pwHash)
    public view onlyIfRunning returns (bool) {
        return ((remittances[pwHash].sender != address(0)) && (remittances[pwHash].dst != address(0)));
    }

    // Called by Alice.
    function deposit(address payable dst, uint deadline, bytes32 pwHash)
    public payable onlyIfRunning addressNonZero(dst) sufficientIncomingFunds returns(bool success) {
        require(pwHash != 0, "E_EH");
        require(!txExists(pwHash), "E_TAE");
        require((deadline == 0) || (deadline > block.number), "E_DE");
        remittances[pwHash] = TxInfo(msg.sender, dst, msg.value, deadline);
        emit LogDeposited(msg.sender, dst, msg.value, deadline);
        return true;
    }

    // Called by Carol (with Bob).
    function withdraw(bytes32 fiatSeed, bytes32 exchangeSeed)
    public onlyIfRunning returns (bool success) {
        bytes32 hash = OTP.generate(address(this), msg.sender, fiatSeed, exchangeSeed);
        TxInfo memory t = remittances[hash];
        require(t.amount > 0, "E_EF");
        require((t.deadline == 0) || (t.deadline <= block.number), "E_TE");
        uint amountToTransfer = t.amount;
        t.amount = 0;
        remittances[hash] = t;
        emit LogWithdrew(t.sender, t.dst, amountToTransfer);
        t.dst.transfer(amountToTransfer);
        return true;
    }

    // Only called by Alice to reclaim funds.
    function reclaim(bytes32 pwHash)
    public onlyIfRunning onlyIfTxExists(pwHash) returns (bool success) {
        TxInfo memory t = remittances[pwHash];
        require(t.sender == msg.sender, "E_UA");
        require(t.amount > 0, "E_EF");
        require((t.deadline <= block.number) && (t.deadline != 0), "E_TNE");
        uint amountToTransfer = t.amount;
        t.amount = 0;
        remittances[pwHash] = t;
        emit LogReclaimed(t.sender, t.dst, amountToTransfer, t.deadline);
        msg.sender.transfer(amountToTransfer);
        return true;
    }
}