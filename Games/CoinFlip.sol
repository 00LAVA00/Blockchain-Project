// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ProbabilityLibrary contract
import "../ProbabilityLibrary.sol";

contract CoinFlipGame {

    // Define the possible outcomes of a coin flip
    enum CoinOutcome { Heads, Tails }

    // Define the probabilities for each outcome (assuming a fair coin)
    uint256 private constant fairCoinProbability = 50;

    // Define the minimum and maximum bet amounts
    uint256 private constant minBetAmount = 0.01 ether;
    uint256 private constant maxBetAmount = 10 ether;

    // Event to log game outcomes
    event GameOutcome(address indexed player, uint256 betAmount, CoinOutcome outcome, bool win);

    // Function to place a bet on the outcome of a coin flip
    function placeBet(CoinOutcome betOutcome) external payable {
        // Validate the bet amount
        require(msg.value >= minBetAmount && msg.value <= maxBetAmount, "Invalid bet amount");

        // Simulate flipping the coin
        uint256 flipOutcomeValue = ProbabilityLibrary.simulateCoinFlip();
        CoinOutcome flipOutcome;

        if (flipOutcomeValue == 0) {
            flipOutcome = CoinOutcome.Heads;
        } else if (flipOutcomeValue == 1) {
            flipOutcome = CoinOutcome.Tails;
        } 

        // Check if the player wins
        bool win = (flipOutcome == betOutcome);

        // Emit the game outcome event
        emit GameOutcome(msg.sender, msg.value, flipOutcome, win);

        // Transfer winnings to the player if they win
        if (win) {
            payable(msg.sender).transfer(msg.value * 2);
        }
    }
}
