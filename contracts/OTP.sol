pragma solidity ^0.5.0;

library OTP {

    function stringToBytes32Hash(string memory seed) public pure returns(bytes32) {
        return keccak256(abi.encode(seed));
    }

    function generate(address remittance, address dst, bytes32 fiatSeed, bytes32 exchangeSeed) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(remittance, dst, fiatSeed, exchangeSeed));
    }

}