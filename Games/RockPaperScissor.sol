// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RandomWordLibrary.sol";

contract RockPaperScissorsGame {

    RandomWordLibrary public randomWordLibrary; 

    bool public win;

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }

    // Define the possible choices in Rock, Paper, Scissors game
    enum Choice { Rock, Paper, Scissors }

    // Event to log game outcomes
    event GameOutcome(address indexed player, uint256 betAmount, Choice choice, Choice opponentChoice, bool win);

    // Function to allow the user to place a bet and choose a move in the Rock, Paper, Scissors game
    function placeBetAndChooseMove(uint8 move) external payable returns (bool) {
        // Ensure valid move (between 0 and 2)
        require(move >= 0 && move <= 2, "Invalid move");


        uint256 requestId = randomWordLibrary.getLastRequestId();


        // Simulate choosing a random move for the opponent
        uint256 randomNumber = randomWordLibrary.fetchRandomWord(requestId) % 3;
        Choice opponentChoice = Choice(randomNumber);

        // Determine the winner based on the moves
        win = determineWinner(Choice(move), opponentChoice);

        // Emit the game outcome event
        emit GameOutcome(msg.sender, msg.value, Choice(move), opponentChoice, win);

        // Transfer winnings to the winner if there's a winner
        if (win) {
            payable(msg.sender).transfer(0);
        }

        return win; // Return whether the player won or lost
    }

    // Function to determine the winner based on the moves
    function determineWinner(Choice move, Choice opponentMove) internal pure returns (bool) {
        if (move == opponentMove) {
            return false; // Draw
        } else if ((move == Choice.Rock && opponentMove == Choice.Scissors) ||
                   (move == Choice.Paper && opponentMove == Choice.Rock) ||
                   (move == Choice.Scissors && opponentMove == Choice.Paper)) {
            return true; // Player wins
        } else {
            return false; // Player loses
        }
    }

    function getMyOutputAndRandom() public view returns (uint256) {
        uint256 requestId = randomWordLibrary.getLastRequestId();
        uint256 randomNumber=randomWordLibrary.fetchRandomWord(requestId) % 3;
        return randomNumber;
    }

    function getWinStatus() view external returns (bool) {
        return win;
    }
}
