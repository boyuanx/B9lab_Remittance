pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Stoppable.sol";
import "./OTP_Gen.sol";

contract Remittance is Stoppable {

    using SafeMath for uint;

    mapping (address => TxInfo[]) TxLUT; // Recipient address => TxInfo[]
    event LogDepositComplete(address indexed sender, address indexed fiatRecipient, address indexed exchangeDst, uint amount, uint deadline);
    event LogWithdrawPending(address indexed fiatRecipient, address indexed exchangeDst, uint amount);
    event LogWithdrawComplete(address indexed fiatRecipient, address indexed exchangeDst, uint amount);
    event LogReclaimComplete(address indexed sender, address indexed fiatRecipient, address indexed exchangeDst, uint amount, uint deadline);

    struct TxInfo {
        address sender;
        address fiatRecipient;
        uint amount;
        uint deadline;
        bytes32 fiatRecipientPwHash;
        bytes32 exchangePwHash;
        bool pendingAuthRelease;
    }

    constructor(bool initialRunState) public Stoppable(initialRunState) {}

    modifier sufficientIncomingFunds {
        require(msg.value > 0,"E_IF");
        _;
    }

    // Called by Alice
    function deposit(address fiatRecipient, address exchangeDst, uint deadline, bytes32 fiatRecipientPwHash, bytes32 exchangePwHash)
    public payable onlyIfRunning addressNonZero(exchangeDst) sufficientIncomingFunds returns(bool success) {
        if (findTxInfoLoose(exchangeDst, fiatRecipientPwHash, exchangePwHash) != 2**256-1) {     // If tx already exists or password is already in use, abort.
            revert("E_TAE");
        }
        if (deadline != 0 && deadline < block.number) {
            revert("E_DE");
        }
        TxInfo memory t = TxInfo(msg.sender, fiatRecipient, msg.value, deadline, fiatRecipientPwHash, exchangePwHash, false);
        TxLUT[exchangeDst].push(t);
        emit LogDepositComplete(msg.sender, fiatRecipient, exchangeDst, msg.value, deadline);
        return true;
    }

    // Called by Bob and Carol, once per person.
    function withdraw(address payable exchangeDst, bytes32 pwHash)
    public onlyIfRunning returns (bool withdrawn) {
        uint TxIndex = findTxInfoStrict(exchangeDst, pwHash);
        if (TxIndex == 2**256-1) {       // If tx doesn't exist, abort.
            revert("E_TNF");
        }
        TxInfo[] storage tArray = TxLUT[exchangeDst];
        TxInfo memory t = tArray[TxIndex];
        if (t.deadline != 0 && (t.deadline <= block.number)) {      // If tx has expired, abort.
            revert("E_TE");
        }
        uint amount = t.amount;
        if (t.pendingAuthRelease) {       // If the other party has already authorized the release.
            delete tArray[TxIndex];
            emit LogWithdrawComplete(t.fiatRecipient, exchangeDst, amount);
            exchangeDst.transfer(amount);
            return true;
        } else {
            t.pendingAuthRelease = true;
            tArray[TxIndex] = t;
            emit LogWithdrawPending(t.fiatRecipient, exchangeDst, amount);
            return false;
        }
    }

    // Only called by Alice to reclaim funds
    function reclaim(address exchangeDst, bytes32 fiatRecipientPwHash, bytes32 exchangePwHash)
    public onlyIfRunning addressNonZero(exchangeDst) returns (bool success) {
        uint TxIndex = findTxInfoLoose(exchangeDst, fiatRecipientPwHash, exchangePwHash);
        if (TxIndex == 2**256-1) {
            revert("E_TNF");
        }
        TxInfo[] storage tArray = TxLUT[exchangeDst];
        TxInfo memory t = tArray[TxIndex];
        if (t.sender != msg.sender) {
            revert("E_UA");
        }
        if ((t.deadline > block.number) || (t.deadline == 0)) {
            revert("E_TNE");
        }
        uint amount = t.amount;
        delete tArray[TxIndex];
        emit LogReclaimComplete(msg.sender, t.fiatRecipient, exchangeDst, amount, t.deadline);
        msg.sender.transfer(amount);
        return true;
    }

    // Helper function to find a Tx struct
    function findTxInfoStrict(address TxLUTKey, bytes32 pwHash)
    private view onlyIfRunning returns (uint index) {
        TxInfo[] memory tArray = TxLUT[TxLUTKey];
        for (uint i = 0; i < tArray.length; i++) {
            TxInfo memory t = tArray[i];
            // If caller is fiat recipient and the hash matches stored fiat hash 
            // OR caller is exchange and hash matches stored exchange hash
            if (((msg.sender == t.fiatRecipient) && (t.fiatRecipientPwHash == pwHash)) || ((msg.sender == TxLUTKey) && (t.exchangePwHash == pwHash))) {
                return i;
            }
        }
        return 2**256-1;
    }

    function findTxInfoLoose(address TxLUTKey, bytes32 fiatRecipientPwHash, bytes32 exchangePwHash)
    private view onlyIfRunning returns (uint index) {
        TxInfo[] memory tArray = TxLUT[TxLUTKey];
        for (uint i = 0; i < tArray.length; i++) {
            TxInfo memory t = tArray[i];
            if ((t.fiatRecipientPwHash == fiatRecipientPwHash) && (t.exchangePwHash == exchangePwHash)) {
                return i;
            }
        }
        return 2**256-1;
    }

}