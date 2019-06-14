pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP_Gen.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    OTP_Gen otp;
    mapping (address => TxInfo[]) TxLUT; // Recipient address => TxInfo[]
    event LogDepositCompleted(address indexed sender, address indexed recipient, uint amount, uint deadline);
    event LogWithdrawalComplete(address indexed recipient, uint amount);

    struct TxInfo {
        address sender;
        uint amount;
        uint deadline;
        bytes32 pw1Hash;
        bytes32 pw2Hash;
    }

    constructor(bool initialRunState) public Stoppable(initialRunState) {
        otp = new OTP_Gen();
    }

    modifier sufficientIncomingFunds {
        require(msg.value > 0,"E_IF");
        _;
    }

    function deposit(address dst, uint deadline, string memory password1, string memory password2)
    public payable onlyIfRunning addressNonZero(dst) sufficientIncomingFunds returns(bool success) {
        bytes32 pw1Hash = otp.generate(dst, password1);
        bytes32 pw2Hash = otp.generate(dst, password2);
        if (findTxInfo(dst, pw1Hash, pw2Hash) != 2**256-1) {
            revert("E_TAE");
        }
        TxInfo memory t = TxInfo(msg.sender, msg.value, deadline, pw1Hash, pw2Hash);
        TxLUT[dst].push(t);
        emit LogDepositCompleted(msg.sender, dst, msg.value, deadline);
        return true;
    }

    function withdraw(string memory password1, string memory password2)
    public onlyIfRunning returns (bool success) {
        uint TxIndex = findTxInfo(msg.sender, otp.generate(msg.sender, password1), otp.generate(msg.sender, password2));
        if (TxIndex == 2**256-1) {
            revert("E_TNF");
        }
        TxInfo[] storage tArray = TxLUT[msg.sender];
        TxInfo memory t = tArray[TxIndex];
        uint amount = t.amount;
        if (t.deadline != 0 && (t.deadline <= block.number)) {
            revert("E_TE");
        }
        delete tArray[TxIndex];
        emit LogWithdrawalComplete(msg.sender, amount);
        msg.sender.transfer(amount);
        return true;
    }

    function reverseDeposit(address dst, string memory password1, string memory password2)
    public onlyIfRunning addressNonZero(dst) returns (bool success) {
        uint TxIndex = findTxInfo(dst, otp.generate(dst, password1), otp.generate(dst, password2));
        if (TxIndex == 2**256-1) {
            revert("E_TNF");
        }
        TxInfo[] storage tArray = TxLUT[dst];
        TxInfo memory t = tArray[TxIndex];
        if (t.deadline > block.number) {
            revert("E_TNE");
        }
        uint amount = t.amount;
        delete tArray[TxIndex];
        emit LogWithdrawalComplete(msg.sender, amount);
        msg.sender.transfer(amount);
        return true;
    }

    function findTxInfo(address TxLUTKey, bytes32 pw1Hash, bytes32 pw2Hash)
    private view onlyIfRunning returns (uint index) {
        TxInfo[] memory tArray = TxLUT[TxLUTKey];
        for (uint i = 0; i < tArray.length; i++) {
            TxInfo memory t = tArray[i];
            if ((t.pw1Hash == pw1Hash) && (t.pw2Hash == pw2Hash)) {
                return i;
            }
        }
        return 2**256-1;
    }

}