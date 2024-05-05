// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the RandomWordLibrary contract
import "contracts/lib.sol";

contract Craps {
    RandomWordLibrary public randomWordLibrary; // Library for random words

    bool public win; // Global variable to store win status
    uint256 public diceResult; // Global variable to store dice result

    mapping(address => uint256) private playerBalances; // Mapping to store player balances

    // Event to log the result of a bet
    event BetResult(address indexed player, uint256 betAmount, bool win, uint256 payout, uint256 diceResult);

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }

    // Function to roll the dice and determine the outcome
    function rollDice() external {
        // Simulate rolling a 12-sided dice
        diceResult = randomWordLibrary.simulateDiceRoll(12);

        // Determine the outcome of the roll
        if (diceResult == 7 || diceResult == 11) {
            win = true;
        } else if (diceResult == 2 || diceResult == 3 || diceResult == 12) {
            win = false;
        }

        // Emit the bet result event
        emit BetResult(msg.sender, 0, win, 0, diceResult);
    }

    // Function to retrieve the latest value of win
    function getWinStatus() external view returns (bool) {
        return win;
    }
}
