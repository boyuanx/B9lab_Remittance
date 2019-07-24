pragma solidity ^0.5.0;

library OTP_Gen {

    function generate(address dst, string memory fiatSeed, string memory exchangeSeed) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(dst, fiatSeed, exchangeSeed));
    }

}