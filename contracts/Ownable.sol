pragma solidity ^0.5.0;

contract Ownable {

    address private owner;
    event LogOwnerChanged(address indexed sender, address indexed newOwner);

    modifier onlyOwnerAccess {
        require(msg.sender == owner, "E_NO");
        _;
    }

    modifier addressNonZero(address recipient) {
        require(recipient != address(0), "E_IS");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public addressNonZero(newOwner) onlyOwnerAccess returns(bool success) {
        owner = newOwner;
        emit LogOwnerChanged(msg.sender, newOwner);
        return true;
    }

}