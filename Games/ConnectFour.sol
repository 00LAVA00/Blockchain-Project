// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ConnectFourGame {
    // Define the players
    enum Player { None, Red, Yellow }

    // Define the game board
    Player[6][7] private board;

    // Define the current player
    Player private currentPlayer;

    // Define the winner of the game
    Player private winner;

    // Event to log the winner of the game
    event Winner(Player winner);

    // Constructor to initialize the game
    constructor() {
        // Initialize the game board
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = 0; j < 7; j++) {
                board[i][j] = Player.None;
            }
        }

        // Set the current player to Red (the first player)
        currentPlayer = Player.Red;
    }

    // Function to make a move on the game board
    function makeMove(uint256 col) external {
        // Ensure the game is ongoing and the move is valid
        require(winner == Player.None, "Game over");
        require(col < 7, "Invalid move");

        // Find the first available row in the selected column
        uint256 row = 0;
        while (row < 6 && board[row][col] != Player.None) {
            row++;
        }

        // Ensure the selected column is not full
        require(row < 6, "Column is full");

        // Make the move for the current player
        board[row][col] = currentPlayer;

        // Check for a winner
        if (checkWinner(Player.Red)) {
            winner = Player.Red;
            emit Winner(winner);
        } else if (checkWinner(Player.Yellow)) {
            winner = Player.Yellow;
            emit Winner(winner);
        } else if (isBoardFull()) {
            winner = Player.None;
            emit Winner(winner);
        } else {
            // Switch to the next player
            currentPlayer = (currentPlayer == Player.Red) ? Player.Yellow : Player.Red;
        }
    }

    // Function to check if there is a winner
    function checkWinner(Player player) internal view returns (bool) {
        // Check horizontal lines
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = 0; j < 4; j++) {
                if (board[i][j] == player &&
                    board[i][j+1] == player &&
                    board[i][j+2] == player &&
                    board[i][j+3] == player) {
                    return true;
                }
            }
        }

        // Check vertical lines
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 7; j++) {
                if (board[i][j] == player &&
                    board[i+1][j] == player &&
                    board[i+2][j] == player &&
                    board[i+3][j] == player) {
                    return true;
                }
            }
        }

        // Check diagonal lines (positive slope)
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 4; j++) {
                if (board[i][j] == player &&
                    board[i+1][j+1] == player &&
                    board[i+2][j+2] == player &&
                    board[i+3][j+3] == player) {
                    return true;
                }
            }
        }

        // Check diagonal lines (negative slope)
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 3; j < 7; j++) {
                if (board[i][j] == player &&
                    board[i+1][j-1] == player &&
                    board[i+2][j-2] == player &&
                    board[i+3][j-3] == player) {
                    return true;
                }
            }
        }

        return false;
    }

    // Function to check if the board is full
    function isBoardFull() internal view returns (bool) {
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 j = 0; j < 7; j++) {
                if (board[i][j] == Player.None) {
                    return false;
                }
            }
        }
        return true;
    }

    // Function to retrieve the current game board
    function getBoard() external view returns (Player[6][7] memory) {
        return board;
    }

    // Function to retrieve the current player
    function getCurrentPlayer() external view returns (Player) {
        return currentPlayer;
    }

    // Function to retrieve the winner of the game
    function getWinner() external view returns (Player) {
        return winner;
    }
}
