// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "forge-std/console.sol";

contract Splitwise { 
    address[] public users;
    mapping(address => mapping(address => uint32)) public debts; // debtor: {creditor: amount}
    mapping(address => bool) public knownUsers;
    mapping(address => uint32) public lastActives;

    function lookup(address debtor, address creditor) public view returns (uint32) {
        return debts[debtor][creditor];
    }

    function add_IOU(address creditor, uint32 amount, address[] memory path) public {
        require(amount > 0); // it's uint32, but for convenience. plus 0 amount is useless. 
        require(msg.sender != creditor);

        uint32 time = uint32(block.timestamp);

        if (!knownUsers[creditor]) {
            knownUsers[creditor] = true;
            users.push(creditor);
        }

        if (!knownUsers[msg.sender]) {
            knownUsers[msg.sender] = true;
            users.push(msg.sender);
        }

        debts[msg.sender][creditor] += amount;

        // cycle resolution

        if (path.length >= 2) {
            require(path[0] == creditor);
            require(path[path.length - 1] == msg.sender);

            uint32 minDebt = debts[msg.sender][creditor];
            for (uint i = 0; i < path.length - 1; i++) {
                uint32 debt = debts[path[i]][path[i + 1]];
                require(debt > 0);

                if (debt < minDebt) minDebt = debt;
            }

            for (uint i = 0; i < path.length - 1; i++) {
                debts[path[i]][path[i + 1]] -= minDebt;
            }
            debts[msg.sender][creditor] -= minDebt;
        }

        lastActives[msg.sender] = time;
        lastActives[creditor] = time;
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

}
