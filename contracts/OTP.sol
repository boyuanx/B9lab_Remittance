pragma solidity ^0.5.0;

library OTP {

    function generate(address remittance, address dst, string memory fiatSeed, string memory exchangeSeed) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(remittance, dst, fiatSeed, exchangeSeed));
    }

}