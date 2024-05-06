// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ProbabilityLibrary contract
import "./RandomWordLibrary.sol";

contract CoinFlipGame {

    RandomWordLibrary public randomWordLibrary;

    bool public win; // Global variable to store win status

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }


    // Define the possible outcomes of a coin flip
    enum CoinOutcome { Tails, Heads }

    // Define the probabilities for each outcome (assuming a fair coin)
    uint256 private constant fairCoinProbability = 50;


    // Event to log game outcomes
    event GameOutcome(address indexed player, uint256 betAmount, CoinOutcome outcome, bool win);

    // Function to place a bet on the outcome of a coin flip
    function placeBet(CoinOutcome betOutcome) external payable returns (bool){

        // Fetch the last request ID
        uint256 requestId = randomWordLibrary.getLastRequestId();

        // Simulate flipping the coin
        uint256 randomFlip = randomWordLibrary.fetchRandomWord(requestId) % 2; // Get dice roll from 1-6
        CoinOutcome flipOutcome;

        if (randomFlip == 0) {
            flipOutcome = CoinOutcome.Tails;
        } else if (randomFlip == 1) {
            flipOutcome = CoinOutcome.Heads;
        } 

        // Check if the player wins
        win = (flipOutcome == betOutcome);

        // Emit the game outcome event
        emit GameOutcome(msg.sender, msg.value, flipOutcome, win);

        // Transfer winnings to the player if they win
        if (win) {
            payable(msg.sender).transfer(0);
        }
        return win;
    }

    // Function to retrieve the latest value of win
    function getWinStatus() external view returns (bool) {
        return win;
    }

}
