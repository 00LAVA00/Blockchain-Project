// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the RandomWordLibrary contract
import "contracts/lib.sol"; // Adjust this path to your actual library location

contract DiceRollGame {
    RandomWordLibrary public randomWordLibrary; // Library for random words
    address public owner; // Address of the owner
    bool public gameStarted; // Flag to indicate if the game has started
    uint256 public ownerRewardPercentage = 5; // Owner reward percentage (5%)
    uint256 public predefinedBettingAmount = 0.0000000000000001 ether; // Predefined betting amount (100 wei)
    uint256 public maxPlayers = 5; // Maximum number of players allowed

    // Mappings to store player data
    mapping(address => uint256) public playerBalances; // Stores initial cash of each player
    mapping(address => bool) public hasPlacedBet; // Tracks if a player has placed a bet
    mapping(address => uint256) public playerBets; // Stores the bet placed by each player
    mapping(address => uint256) public playerBetOutcomes; // Stores the outcome each player bets on

    // Struct for individual game results
    struct GameResult {
        address participant; // Player address
        uint256 playerDiceValue; // Dice value chosen by the player
        uint256 rolledDiceValue; // Dice value rolled during the game
        bool didWin; // Whether the player won
        uint256 amountWon; // Amount won by the player
        uint256 balanceAtEnd; // Balance of the player at the end of the game
    }

    // Struct for game history
    struct GameHistory {
        uint256 gameId; // Game ID
        GameResult[] results; // Results for all participants
        uint256 ownerRewardPercentage; // Owner's reward percentage for this game
        uint256 predefinedBettingAmount; // Predefined betting amount for this game
        uint256 maxPlayers; // Maximum number of players allowed in this game
    }

    GameHistory[] public gameHistories; // Array to store game histories
    
    // Array to store player addresses
    address payable[] public players;
    uint256 public totalBetAmount; // Total amount bet by players in the game
    uint256 public gameCounter; // Counter for game history





    // Event to log dice roll results
    event DiceRollResult(address indexed player, uint256 betOutcome, uint256 randomRoll, bool win, uint256 rewardAmount, uint256 balanceAmountSent);

    // Event for game started
    event GameStarted(uint256 gameId);

    // Event for game started
    event GameEnded(uint256 gameId);

    // Event to log owner transactions
    event OwnerTransaction(address indexed owner, uint256 amount);




    constructor(address _randomWordLibraryAddress) {
        randomWordLibrary = RandomWordLibrary(_randomWordLibraryAddress); // Initialize with RandomWordLibrary contract address
        owner = msg.sender; // Set the owner address
        gameCounter = 0; // Initialize the game counter
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Modifier to restrict access when the game has not started
    modifier gameNotStarted() {
        require(!gameStarted, "Game has already started");
        _;
    }

    // Modifier to restrict access when the game has started
    modifier gameStartedOnly() {
        require(gameStarted, "Game has not started yet");
        _;
    }

    // Function to start the game
    function startGame() public onlyOwner gameNotStarted {
        gameStarted = true;
        gameCounter++;
        // Emit the GameStarted event
        emit GameStarted(gameCounter);
    }

    // Function to get the predefined betting amount
    function getPredefinedBettingAmount() public view returns (uint256) {
        return predefinedBettingAmount;
    }
    

    // Function to enter the game with cash
    function enter() public payable gameNotStarted {
        require(msg.value >= 0.0000000000000001 ether && msg.value <= 10 ether, "Invalid entry amount");
        require(players.length < maxPlayers, "Maximum number of players reached");
        require(playerBalances[msg.sender] == 0, "Player has already entered the game with a balance"); // Check if player has already entered

        players.push(payable(msg.sender)); // Add player to the players array
        playerBalances[msg.sender] = msg.value; // Record the initial cash
    }

    // Function for a player to exit the game before it starts
    function exitGame() external gameNotStarted {
        require(playerBalances[msg.sender] > 0, "Player is not in the game"); // Ensure the player is part of the game

        uint256 playerBalance = playerBalances[msg.sender]; // Get the player's balance

        // Refund the player
        payable(msg.sender).transfer(playerBalance);

        // Remove the player from the `players` array
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                players[i] = players[players.length - 1]; // Move the last element to the current index
                players.pop(); // Remove the last element
                break;
            }
        }

        // Clear player-related mappings
        delete playerBalances[msg.sender]; // Reset their balance
        delete hasPlacedBet[msg.sender]; // Reset their bet status
        delete playerBets[msg.sender]; // Reset their bet amount
        delete playerBetOutcomes[msg.sender]; // Reset their bet outcome
    }


    // Function to place a bet
    function placeBet(uint256 betOutcome) external gameStartedOnly {
        require(betOutcome >= 1 && betOutcome <= 6, "Invalid bet outcome");
        require(!hasPlacedBet[msg.sender], "Player has already placed a bet"); // Ensure player hasn't bet yet
        require(playerBalances[msg.sender] >= predefinedBettingAmount, "Insufficient balance to place bet");

        playerBalances[msg.sender] -= predefinedBettingAmount; // Deduct the betting amount from player's balance
        playerBets[msg.sender] = predefinedBettingAmount; // Store the bet amount
        playerBetOutcomes[msg.sender] = betOutcome; // Record the player's bet outcome
        totalBetAmount += predefinedBettingAmount; // Increase total bet amount
        hasPlacedBet[msg.sender] = true; // Mark that the player has placed a bet
    }

    // Function to cancel a bet
    function cancelBet() external gameStartedOnly {
        require(hasPlacedBet[msg.sender], "Player hasn't placed a bet"); // Ensure the player has placed a bet
        
        playerBalances[msg.sender] += predefinedBettingAmount; // Refund the betting amount to the player
        totalBetAmount -= predefinedBettingAmount; // Decrease total bet amount
        hasPlacedBet[msg.sender] = false; // Reset the player's bet status
        delete playerBetOutcomes[msg.sender];
    }

    // Function to roll the dice and distribute rewards
    function rollDiceAndDistributeRewards() external onlyOwner gameStartedOnly{
        uint256 requestId = randomWordLibrary.getLastRequestId(); // Fetch the last request ID
        uint256 randomRoll = randomWordLibrary.fetchRandomWord(requestId) % 6 + 1; // Get dice roll from 1-6
        
        uint256 ownerReward = 0; // Default owner reward
        uint256 totalWinners = 0;
        uint256 rewardPool = 0;


        GameHistory storage currentGame = gameHistories.push(); // Create a new game history
        currentGame.gameId = gameCounter - 1; // Increment game ID
        currentGame.ownerRewardPercentage = ownerRewardPercentage; // Store owner's reward percentage for this game
        currentGame.predefinedBettingAmount = predefinedBettingAmount; // Store the predefined betting amount
        currentGame.maxPlayers = maxPlayers; // Store the maximum number of players for this game


        for (uint256 i = 0; i < players.length; i++) {
            address payable player = players[i];
            if (hasPlacedBet[player]) { // Only consider players who have placed bets
                uint256 betOutcome = playerBetOutcomes[player]; // Get player's bet outcome
                if (randomRoll == betOutcome) { // If player won
                    totalWinners += 1; // Increment total winners
                }
                else { // If player lost
                    emit DiceRollResult(player, betOutcome, randomRoll, false, 0, playerBalances[player]); // Emit event
                }
            } else { // If player didn't bet or cancelled
                // Emit event with appropriate default values for betOutcome
                emit DiceRollResult(player, 0, randomRoll, false, 0, playerBalances[player]); // Emit event
                GameResult memory result = GameResult(player,7,randomRoll,false,0,playerBalances[player]); // Game result for losers, specidal value of bet on dice: 7 to track who is cancelling or not placing bet
                currentGame.results.push(result); // Store game history
            }
        }

        if (totalWinners == 0) { // If everyone loses, owner takes the entire bet amount
            payable(owner).transfer(totalBetAmount); // Transfer to owner
            emit OwnerTransaction(owner, totalBetAmount); // Emit event for owner transaction

            for (uint256 i = 0; i < players.length; i++) {
                address payable player = players[i];

                uint256 refund = playerBalances[player]; // Unused cash to refund
                player.transfer(refund); // Refund unused cash to loser
                playerBalances[player] = 0; // Reset player's balance
                GameResult memory result = GameResult(player,playerBetOutcomes[player],randomRoll,false,0,refund); // Game result for losers
                currentGame.results.push(result); // Store game history
            }
        } 
        
        else {
            ownerReward = (totalBetAmount * ownerRewardPercentage) / 100; // Owner's reward
            rewardPool = totalBetAmount - ownerReward; // Deduct owner's reward from the pool
            
            if (totalWinners == totalPlayersWhoBetted()) { // If everyone wins, owner doesn't take a cut
                rewardPool = totalBetAmount; // All rewards go to players
                ownerReward = 0; // No owner cut if everyone wins
                emit OwnerTransaction(owner, ownerReward); // Emit event for owner transaction

            } else {
                payable(owner).transfer(ownerReward); // Transfer owner's reward
                emit OwnerTransaction(owner, ownerReward); // Emit event for owner transaction

            }

            // Distribute rewards among winners
            uint256 rewardPerWinner = rewardPool / totalWinners; // Divide reward among winners
            for (uint256 i = 0; i < players.length; i++) {
                address payable player = players[i];
                if (hasPlacedBet[player]) {         // Only consider players who have placed bets

                    uint256 betOutcome = playerBetOutcomes[player]; // Get player's bet outcome

                    if (randomRoll == betOutcome) { // If player won
                        uint256 reward = rewardPerWinner + playerBalances[player]; // Reward plus unused cash
                        player.transfer(reward); // Transfer to winner
                        GameResult memory result = GameResult(player,betOutcome,randomRoll,true,rewardPerWinner,playerBalances[player]); // Game result for winners
                        currentGame.results.push(result); // Store game history
                        emit DiceRollResult(player, betOutcome, randomRoll, true, rewardPerWinner, playerBalances[player]); // Emit event

                    } else { // If player lost
                        uint256 refund = playerBalances[player]; // Unused cash to refund
                        player.transfer(refund); // Refund unused cash to loser
                        playerBalances[player] = 0; // Reset player's balance
                        
                        GameResult memory result = GameResult(player,betOutcome,randomRoll,false,0,refund); // Game result for losers
                        currentGame.results.push(result); // Store game history
                    }
                } else { // If player didn't bet or canceled
                    player.transfer(playerBalances[player]); // Return unused cash
                }
            }
        }

        // Emit the GameEnded event
        emit GameEnded(currentGame.gameId);

        // Reset game state
        resetGameState();
        //totalBetAmount = 0; // Reset total bet amount
        //gameStarted = false; // Reset game status
        //delete players; // Reset players array
    }


    // Helper function to count players who placed bets
    function totalPlayersWhoBetted() internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (hasPlacedBet[players[i]]) {
                count++;
            }
        }
        return count;
    }


    // Function to set the owner reward percentage
    function setOwnerRewardPercentage(uint256 _ownerRewardPercentage) external onlyOwner gameNotStarted{
        require(_ownerRewardPercentage >= 0 && _ownerRewardPercentage <= 10, "Invalid reward percentage");
        ownerRewardPercentage = _ownerRewardPercentage;
    }

    // Function to set the predefined betting amount
    function setPredefinedBettingAmount(uint256 _predefinedBettingAmount) external onlyOwner gameNotStarted{
        predefinedBettingAmount = _predefinedBettingAmount;
    }

    // Function to set the maximum number of players
    function setMaxPlayers(uint256 _maxPlayers) external onlyOwner gameNotStarted{
        require(_maxPlayers > 0, "Maximum players must be greater than zero");
        maxPlayers = _maxPlayers;
    }



    // Function to retrieve the contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to retrieve the list of players
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }


    // Function to retrieve game history by game ID
    function getGameResults(uint256 _gameId) public view returns (GameResult[] memory) {
        require(_gameId < gameHistories.length, "Invalid game ID");

        // Get the game history for the specified game ID
        GameHistory memory gameHistory = gameHistories[_gameId];

        // Return the list of game results for this game
        return gameHistory.results;
    }

    // Function to reset the game state after the game ends
    function resetGameState() internal {
        // Clear player-related mappings by deleting each player's entry
        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i]; // Get each player in the game
            delete playerBalances[player]; // Reset their balance
            delete hasPlacedBet[player]; // Reset their bet status
            delete playerBets[player]; // Reset their bet amount
            delete playerBetOutcomes[player]; // Reset their bet outcome
        }

        // Clear the players array
        delete players; // This removes all player references

        // Reset other state variables
        totalBetAmount = 0; // Reset the total bet amount
        gameStarted = false; // Reset the game status
    }


}



// updated version of multi_9.sol



// checklist for running:
// check if all are losers, game history sstores it

//to add:
// add emit message for owner transactions


//modified:
// on calcelling the bet, make the bet outcome of that player = 0
// resolve same player entry in game
// added new fields in game history
// in game history, result array for players, if bet outcome is 7 player canceled or didn't betted in the game