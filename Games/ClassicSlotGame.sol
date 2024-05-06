// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RandomWordLibrary.sol";

contract ClassicSlotsGame {
    RandomWordLibrary public randomWordLibrary; 
    bool public win;
    uint256 private constant minBetAmount = 0.1 ether;
    uint256 private constant maxBetAmount = 10 ether;

    // Define the fixed set of symbols and their payouts
    enum Symbol { Cherry, Lemon, Orange, Bar, Seven }

    // Define the pay lines and their payouts
    mapping(Symbol => uint256) private payLines;

    // Event to log the result of a game round
    event GameResult(address player, Symbol[] symbols, uint256 payout);

    //Cherry: [0,0,0]; Lemon: [1,1,1]; Orange: [2,2,2]; Bar: [3,3,3]; Seven: [4,4,4].
    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with the RandomWordLibrary contract address
        // Initialize pay lines and payouts
        payLines[Symbol.Cherry] = 2;            //Symbol: 0
        payLines[Symbol.Lemon] = 3;             //Symbol: 1
        payLines[Symbol.Orange] = 4;            //Symbol: 2
        payLines[Symbol.Bar] = 6;               //Symbol: 3
        payLines[Symbol.Seven] = 10;            //Symbol: 4
    }

    // Function to get the user's MetaMask address
    function getUserAddress() public view returns (address) {
        return msg.sender;
    }

    // Function to spin the reels and play the game
    function spin() external payable returns (Symbol[] memory)  {
        // Ensure the bet amount is within the specified range
        // require(msg.value >= minBetAmount && msg.value <= maxBetAmount, "Invalid bet amount");

        // Simulate spinning the reels
        Symbol[] memory symbols = _spinReels();

        // Calculate the payout based on the symbols and pay lines
        uint256 payout = _calculatePayout(symbols);

        // Emit the game result event
        emit GameResult(msg.sender, symbols, payout);

        // Transfer the payout to the player
        if (payout > 0) {
            payable(msg.sender).transfer(0);
        }
        return symbols;
    }

    // Internal function to spin the reels and generate random symbols
    function _spinReels() public view returns (Symbol[] memory) {
        // Simulate spinning the reels and generate random symbols
        Symbol[] memory symbols = new Symbol[](3);
        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 randomNumber = randomWordLibrary.generateRandomNumber(0, uint256(Symbol.Seven));
            symbols[i] = Symbol(randomNumber);
        }
        return symbols;
    }

    // Internal function to calculate the payout based on the symbols and pay lines
    function _calculatePayout(Symbol[] memory symbols) public view returns (uint256) {
        uint256 payout = 0;
        for (uint256 i = 0; i < symbols.length; i++) {
            payout += payLines[symbols[i]];
        }
        return payout;
    }
}
