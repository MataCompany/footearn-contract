// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library Authorization {
    function registryGuildUser(
        address owner,
        address _user,
        uint64 nonce,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) internal pure returns (bool) {
        bytes32 funcHash = keccak256("registryGuildUser");

        // digest the data to transactionHash
        bytes32 inputHash = keccak256(abi.encode(funcHash, _user, nonce));
        address checkAdress = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", inputHash)
            ),
            sigV,
            sigR,
            sigS
        );
        return checkAdress == owner;
    }
}
