// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicTacToeGame {
    // Define the players
    enum Player { None, X, O }

    // Define the game board
    Player[3][3] private board;

    // Define the current player
    Player private currentPlayer;

    // Define the winner of the game
    Player private winner;

    // Event to log the winner of the game
    event Winner(Player winner);

    // Constructor to initialize the game
    constructor() {
        // Initialize the game board
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                board[i][j] = Player.None;
            }
        }

        // Set the current player to "X" (the first player)
        currentPlayer = Player.X;
    }

    // Function to make a move on the game board
    function makeMove(uint256 row, uint256 col) external {
        // Ensure the game is ongoing and the move is valid
        require(winner == Player.None, "Game over");
        require(row < 3 && col < 3, "Invalid move");
        require(board[row][col] == Player.None, "Space already occupied");

        // Make the move for the current player
        board[row][col] = currentPlayer;

        // Check for a winner
        if (checkWinner(Player.X)) {
            winner = Player.X;
            emit Winner(winner);
        } else if (checkWinner(Player.O)) {
            winner = Player.O;
            emit Winner(winner);
        } else if (isBoardFull()) {
            winner = Player.None;
            emit Winner(winner);
        } else {
            // Switch to the next player
            currentPlayer = (currentPlayer == Player.X) ? Player.O : Player.X;
        }
    }

    // Function to check if there is a winner
    function checkWinner(Player player) internal view returns (bool) {
        // Check rows and columns
        for (uint256 i = 0; i < 3; i++) {
            if ((board[i][0] == player && board[i][1] == player && board[i][2] == player) ||
                (board[0][i] == player && board[1][i] == player && board[2][i] == player)) {
                return true;
            }
        }

        // Check diagonals
        if ((board[0][0] == player && board[1][1] == player && board[2][2] == player) ||
            (board[0][2] == player && board[1][1] == player && board[2][0] == player)) {
            return true;
        }

        return false;
    }

    // Function to check if the board is full
    function isBoardFull() internal view returns (bool) {
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                if (board[i][j] == Player.None) {
                    return false;
                }
            }
        }
        return true;
    }

    // Function to retrieve the current game board
    function getBoard() external view returns (Player[3][3] memory) {
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
