// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract IPFS {
    string ipfsHash;

    string[] listofUsers;


    function sendHash(string calldata x) public {
        ipfsHash = x;

    }
    
    function getHash() public view returns (string memory) {
        return ipfsHash;
    }
}