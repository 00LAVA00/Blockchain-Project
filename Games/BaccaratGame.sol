// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RandomWordLibrary.sol";

contract BaccaratGame {

    RandomWordLibrary public randomWordLibrary; // Library for random words

    bool public win; // Global variable to store win status

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }


    // Define the minimum and maximum bet amount
    uint256 private constant minBetAmount = 0.1 ether;
    uint256 private constant maxBetAmount = 10 ether;

    // Define the card values for Baccarat
    mapping(uint256 => uint256) private cardValues;

    // Define the player bets
    mapping(address => uint256) private playerBets;

    // Define the player balances
    mapping(address => uint256) private playerBalances;

    // Define the possible outcomes of the game
    enum Outcome { Player, Banker, Tie }

    // Event to log the result of a game round
    event GameResult(address player, Outcome outcome);

    // Function to place a bet
    function placeBet(uint256 outcome) external payable {
        // Ensure the bet amount is within the specified range
        require(msg.value >= minBetAmount && msg.value <= maxBetAmount, "Invalid bet amount");

        // Ensure the outcome is valid (0: Player, 1: Banker, 2: Tie)
        require(outcome <= 2, "Invalid outcome");

        // Deduct the bet amount from the player's balance
        playerBalances[msg.sender] -= msg.value;

        // Add the bet amount to the player's bets
        playerBets[msg.sender] += msg.value;

    }

    uint256 playerScore;
    uint256 bankerScore;

    // Function to deal cards and determine the winner
    function playGame() external payable returns (bool){

        // Fetch the last request ID
        uint256 requestId = randomWordLibrary.getLastRequestId();

        // Simulate dealing cards for the player and banker
        uint256 randomNumber = randomWordLibrary.fetchRandomWord(requestId);
        playerScore = randomNumber % 13 + 2; // First half of the random number, range from 2 to 14
        bankerScore = (randomNumber / 13) % 13 + 2; // Second half of the random number, range from 2 to 14


        // Determine the winner based on the scores
        Outcome outcome;
        if (playerScore > bankerScore) {
            outcome = Outcome.Player;
            win=true;
        } else if (bankerScore > playerScore) {
            outcome = Outcome.Banker;
            win=false;
        } else {
            outcome = Outcome.Tie;
            win=true;
        }


        // // Transfer winnings to the player if they bet on the correct outcome
        // if (outcome == Outcome.Player) {
        //     playerBalances[msg.sender] += playerBets[msg.sender] * 2; // Double the bet amount for Player win
        // } else if (outcome == Outcome.Tie) {
        //    
        // }

        // Emit the game result event
        emit GameResult(msg.sender, outcome);
        return win;
    }


    function PlayerScoreValue() external view returns (uint256){
        return playerScore;
    }

    function BankerScoreValue() external view returns (uint256){
        return bankerScore;
    }

    // Function to retrieve the latest value of win
    function getWinStatus() external view returns (bool) {
        return win;
    }
}
