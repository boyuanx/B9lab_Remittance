pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    bool public canDeposit;
    uint public defaultDeadlineDelay;
    mapping (bytes32 => TxInfo) public remittances;
    event LogDeposited(address indexed sender, uint amount, uint deadline, bytes32 indexed hash);
    event LogWithdrew(address indexed sender, uint amount, bytes32 indexed hash);
    event LogReclaimed(address indexed sender, uint amount, uint deadline, bytes32 indexed hash);

    struct TxInfo {
        address payable sender;
        uint amount;
        uint deadline;
    }

    constructor(bool initialRunState, uint deadlineDelay) public Stoppable(initialRunState) {
        canDeposit = true;
        defaultDeadlineDelay = deadlineDelay;
    }

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
        return remittances[pwHash].sender != address(0);
    }

    function setDefaultDeadlineDelay(uint newDeadlineDelay)
    public onlyIfRunning onlyOwnerAccess returns(bool success) {
        defaultDeadlineDelay = newDeadlineDelay;
        return true;
    }

    function depositSwitch(bool _canDeposit)
    public onlyIfRunning onlyOwnerAccess returns(bool status) {
        canDeposit = _canDeposit;
        return canDeposit;
    }

    // Called by Alice.
    function deposit(uint deadline, bytes32 pwHash)
    public payable onlyIfRunning sufficientIncomingFunds returns(bool success) {
        require(canDeposit, "E_DD");
        require(pwHash != 0, "E_EH");
        require(!txExists(pwHash), "E_TAE");
        require((deadline > block.number) || (deadline == 0), "E_DE");
        uint actualDeadline;
        if (deadline == 0) {
            actualDeadline = block.number.add(defaultDeadlineDelay);
        } else {
            actualDeadline = deadline;
        }
        remittances[pwHash] = TxInfo({
            sender: msg.sender,
            amount: msg.value,
            deadline: actualDeadline
        });
        emit LogDeposited(msg.sender, msg.value, actualDeadline, pwHash);
        return true;
    }

    // Called by Carol (with Bob).
    function withdraw(bytes32 fiatSeed)
    public onlyIfRunning returns (bool success) {
        bytes32 hash = OTP.generate(address(this), msg.sender, fiatSeed);
        TxInfo memory t = remittances[hash];
        require(t.amount > 0, "E_EF");
        require(t.deadline > block.number, "E_TE");
        remittances[hash].amount = 0;
        remittances[hash].deadline = 0;
        emit LogWithdrew(t.sender, t.amount, hash);
        msg.sender.transfer(t.amount);
        return true;
    }

    // Only called by Alice to reclaim funds.
    function reclaim(bytes32 pwHash)
    public onlyIfRunning onlyIfTxExists(pwHash) returns (bool success) {
        TxInfo memory t = remittances[pwHash];
        require(t.sender == msg.sender, "E_UA");
        require(t.amount > 0, "E_EF");
        require((t.deadline <= block.number) && (t.deadline != 0), "E_TNE");
        remittances[pwHash].amount = 0;
        remittances[pwHash].deadline = 0;
        emit LogReclaimed(t.sender, t.amount, t.deadline, pwHash);
        msg.sender.transfer(t.amount);
        return true;
    }
}