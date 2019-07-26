pragma solidity ^0.5.0;

library OTP {

    function stringToBytes32Hash(string memory seed) public pure returns(bytes32) {
        return keccak256(abi.encode(seed));
    }

    function generate(address remittance, address dst, bytes32 fiatSeed) public pure returns (bytes32) {
        require(remittance != address(0), "E_ER");
        require(dst != address(0), "E_ER");
        return keccak256(abi.encodePacked(remittance, dst, fiatSeed));
    }

}