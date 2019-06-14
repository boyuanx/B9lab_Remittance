pragma solidity ^0.5.0;

contract OTP_Gen {

    function generate(address dst, string memory seed) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(dst, seed)
        );
    }

}