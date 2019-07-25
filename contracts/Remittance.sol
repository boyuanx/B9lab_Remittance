pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP_Gen.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    mapping (bytes32 => TxInfo) TxLUT; // Hash => TxInfo
    event LogDepositComplete(address indexed sender, address indexed dst, uint amount, uint deadline);
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

    // Helper function to find a Tx struct
    function txExistsHelper(bytes32 pwHash)
    public view onlyIfRunning returns (bool) {
        return ((TxLUT[pwHash].sender == address(0)) && (TxLUT[pwHash].dst == address(0)));
    }

    // Called by Alice.
    function deposit(address payable dst, uint deadline, bytes32 pwHash)
    public payable onlyIfRunning addressNonZero(dst) sufficientIncomingFunds returns(bool success) {
        require(!txExistsHelper(pwHash), "E_TAE");
        require((deadline == 0) || (deadline > block.number), "E_DE");
        TxLUT[pwHash] = TxInfo(msg.sender, dst, msg.value, deadline);
        emit LogDepositComplete(msg.sender, dst, msg.value, deadline);
        return true;
    }

    // Called by Carol (with Bob).
    function withdraw(string memory fiatSeed, string memory exchangeSeed)
    public onlyIfRunning returns (bool success) {
        TxInfo memory t = TxLUT[OTP_Gen.generate(msg.sender, fiatSeed, exchangeSeed)];
        require(t.dst == msg.sender, "E_UA");
        require(t.amount > 0, "E_EF");
        require((t.deadline == 0) || (t.deadline <= block.number), "E_TE");
        emit LogWithdrawComplete(t.sender, t.dst, t.amount);
        t.dst.transfer(t.amount);
        return true;
    }

    // Only called by Alice to reclaim funds.
    function reclaim(bytes32 pwHash)
    public onlyIfRunning txExists(pwHash) returns (bool success) {
        TxInfo memory t = TxLUT[pwHash];
        require(t.sender == msg.sender, "E_UA");
        require(t.amount > 0, "E_EF");
        require((t.deadline <= block.number) && (t.deadline != 0), "E_TNE");
        emit LogReclaimComplete(t.sender, t.dst, t.amount, t.deadline);
        msg.sender.transfer(t.amount);
        return true;
    }
}