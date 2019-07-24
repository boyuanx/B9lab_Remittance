pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP_Gen.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    mapping (bytes32 => TxInfo) TxLUT; // Hash => TxInfo
    event LogDepositComplete(address indexed sender, address indexed dst, uint amount, uint deadline);
    event LogWithdrawPending(address indexed sender, address indexed dst, uint amount);
    event LogWithdrawComplete(address indexed sender, address indexed dst, uint amount);
    event LogReclaimComplete(address indexed sender, address indexed dst, uint amount, uint deadline);

    struct TxInfo {
        address payable sender;
        address payable dst;
        uint amount;
        uint deadline;
    }

    constructor(bool initialRunState) public Stoppable(initialRunState) {}

    modifier sufficientIncomingFunds {
        require(msg.value > 0,"E_IF");
        _;
    }

    modifier txExists(bytes32 pwHash) {
        require(txExistsHelper(pwHash), "E_TNF");
        _;
    }

    // Called by Alice.
    function deposit(address payable dst, uint deadline, bytes32 pwHash)
    public payable onlyIfRunning addressNonZero(dst) sufficientIncomingFunds returns(bool success) {
        if (txExistsHelper(pwHash)) {     // If tx already exists or password is already in use, abort.
            revert("E_TAE");
        }
        if (deadline != 0 && deadline < block.number) {
            revert("E_DE");
        }
        TxInfo memory t = TxInfo(msg.sender, dst, msg.value, deadline);
        TxLUT[pwHash] = t;
        emit LogDepositComplete(msg.sender, dst, msg.value, deadline);
        return true;
    }

    // Called by Carol (with Bob).
    // Use OTP_Gen to get hash.
    function withdraw(bytes32 pwHash)
    public onlyIfRunning txExists(pwHash) returns (bool success) {
        TxInfo memory t = TxLUT[pwHash];
        if (t.dst != msg.sender) {
            revert("E_UA");
        }
        if (t.deadline != 0 && (t.deadline <= block.number)) {      // If tx has expired, abort.
            revert("E_TE");
        }
        emit LogWithdrawComplete(t.sender, t.dst, t.amount);
        t.dst.transfer(t.amount);
        return true;
    }

    // Only called by Alice to reclaim funds.
    function reclaim(address dst, bytes32 pwHash)
    public onlyIfRunning txExists(pwHash) addressNonZero(dst) returns (bool success) {
        TxInfo memory t = TxLUT[pwHash];
        if (t.sender != msg.sender) {
            revert("E_UA");
        }
        if ((t.deadline > block.number) || (t.deadline == 0)) {
            revert("E_TNE");
        }
        emit LogReclaimComplete(t.sender, t.dst, t.amount, t.deadline);
        msg.sender.transfer(t.amount);
        return true;
    }

    // Helper function to find a Tx struct
    function txExistsHelper(bytes32 pwHash)
    private view onlyIfRunning returns (bool) {
        return ((TxLUT[pwHash].sender == address(0)) && (TxLUT[pwHash].dst == address(0)));
    }
}