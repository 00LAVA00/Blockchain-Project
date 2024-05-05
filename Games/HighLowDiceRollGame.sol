// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the RandomWordLibrary contract
import "contracts/lib.sol";

contract HighLowDiceRollGame {
    RandomWordLibrary public randomWordLibrary; // Library for random words

    bool public win; // Global variable to store win status

    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }

    // Function to place a bet on the outcome of the High-Low dice game [0 for High or 1 for Low]
    function placeBetAndRollDice(uint256 targetNumber, uint256 betAmount, HighLowChoice choice) external payable {
        // Validate the bet amount
        require(msg.value >= betAmount, "Insufficient bet amount");

        // Get the random number from the RandomWordLibrary
        uint256 rollOutcome = randomWordLibrary.simulateDiceRoll(6);

        // Determine the outcome of the game
        HighLowOutcome gameOutcome;
        if (rollOutcome > targetNumber) {
            gameOutcome = HighLowOutcome.High;
        } else if (rollOutcome < targetNumber) {
            gameOutcome = HighLowOutcome.Low;
        } else {
            gameOutcome = HighLowOutcome.Draw;
        }

        // Set win status (0 for High or 1 for Low) 
        win = (uint256(gameOutcome) == uint256(choice));


        // Emit the game outcome event
        emit GameOutcome(msg.sender, betAmount, gameOutcome);

        // Transfer winnings to the player if they win
        if (win) {
            payable(msg.sender).transfer(betAmount * 2);
        }
    }

    // Function to retrieve the latest value of win
    function getWinStatus() external view returns (bool) {
        return win;
    }

    // Enum to define the possible outcomes of the High-Low dice game
    enum HighLowOutcome { High, Low, Draw }

    // Enum to define the player's choice (High or Low)
    enum HighLowChoice { High, Low }

    // Event to log game outcomes
    event GameOutcome(address indexed player, uint256 betAmount, HighLowOutcome outcome);
}
