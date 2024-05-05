// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the RandomWordLibrary contract
import "contracts/lib.sol";

contract DiceRollGame {
    RandomWordLibrary public randomWordLibrary; // Library for random words

    bool public win; // Global variable to store win status

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }

    // Function to allow the user to place a bet and roll the dice
    function placeBetAndRollDice(uint256 betOutcome, uint256 betAmount) external payable returns (bool) {
        // Ensure valid bet outcome (between 1 and 6)
        require(betOutcome >= 1 && betOutcome <= 6, "Invalid bet outcome");

        // Fetch the last request ID
        uint256 requestId = randomWordLibrary.getLastRequestId();

        // Get the random number from the RandomWordLibrary
        uint256 randomRoll = randomWordLibrary.fetchRandomWord(requestId) % 6 + 1; // Get dice roll from 1-6

        // Determine if the player wins or loses based on their bet outcome
        win = (randomRoll == betOutcome);

        // Check if the correct amount was sent
        require(msg.value == betAmount, "Incorrect bet amount sent");

        // If the player wins, emit the win event and send the bet amount back to them
        if (win) {
            payable(msg.sender).transfer(0);

        }

        return win; // Return whether the player won or lost
    }

    // Function to retrieve the latest value of win
    function getWinStatus() external view returns (bool) {
        return win;
    }
}
