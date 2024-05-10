import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import "bootstrap/dist/css/bootstrap.min.css"; // Import Bootstrap
import "bulma/css/bulma.css";
import diceRollGameAbi from "./DiceRollGame.json";
import "../App.css";

const DICE_ROLL_GAME_ADDRESS = "0x68cb81F58db50F9A79355900c5C2114f49B39Be0"; // Your contract address

function App() {
  const [walletAddress, setWalletAddress] = useState("");
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [gameContract, setGameContract] = useState(null);
  const [gameStarted, setGameStarted] = useState(false); // Game status
  const [playerCount, setPlayerCount] = useState(0); // Number of players
  const [gameBalance, setGameBalance] = useState(""); // Contract balance
  const [entryValue, setEntryValue] = useState("");
  const [betOutcome, setBetOutcome] = useState("");
  const [isPlacingBet, setIsPlacingBet] = useState(false);
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");
  const [isFetchingResult, setIsFetchingResult] = useState(false); // Flag for fetching game result
  const [gameResult, setGameResult] = useState(null); // Only store the user's game result
  const [showEnterExitButtons, setShowEnterExitButtons] = useState(true);
  const [showExitButton, setShowExitButton] = useState(false); // To show the Exit Game button

  useEffect(() => {
    connectWallet(); // Connect wallet on component mount
  }, []);

// Function to update game status
const updateGameStatus = async (contract) => {
  if (contract) {
    try {
      const hasStarted = await contract.gameStarted(); // Check if game has started
      setGameStarted(hasStarted);

      const players = await contract.getPlayers(); // Get the players
      setPlayerCount(players.length);

      const balance = await contract.getBalance(); // Get contract balance
      setGameBalance(ethers.utils.formatEther(balance)); // Convert to ETH

    
    } catch (err) {
      setError(`Error fetching game status: ${err.message}`);
    }
  }
};

  
  // Function to connect to MetaMask and initialize the contract
  const connectWallet = async () => {
    if (typeof window.ethereum !== "undefined") {
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        const walletAddr = accounts[0];
        // Check if the wallet address has changed or MetaMask is disconnected
        if (walletAddr !== walletAddress || !provider) {
          setWalletAddress(walletAddr);
          // Fetch and display game results if the address has changed or MetaMask is reconnected
          if (provider) {
            fetchGameResults();
          }
        }
  
        const newProvider = new ethers.providers.Web3Provider(window.ethereum);
        const newSigner = newProvider.getSigner();
        setProvider(newProvider);
        setSigner(newSigner);
  
        const newContract = new ethers.Contract(
          DICE_ROLL_GAME_ADDRESS,
          diceRollGameAbi.abi,
          newSigner
        );
        setGameContract(newContract); // Set the contract
  
        // Fetch and display game status on connect
        updateGameStatus(newContract);
  
        // Event listener for the "Game Started" event
        newContract.on("GameStarted", () => {
          setGameStarted(true); // Update the game status to started
          setShowEnterExitButtons(false); // Hide enter and exit buttons when game starts
          setShowExitButton(false); // Hide Exit Game button when game starts
          // Refresh the game state
          updateGameStatus(newContract);
        });
  
        // Event listener for the "DiceRollResult" event
        newContract.on("DiceRollResult", handleDiceRollResult);
  
        window.ethereum.on("accountsChanged", async (newAccounts) => {
          const updatedWalletAddr = newAccounts[0];
          // Check if the wallet address has changed
          if (updatedWalletAddr !== walletAddress) {
            setWalletAddress(updatedWalletAddr);
            // Fetch and display game results if the address has changed
            if (provider) {
              fetchGameResults();
            }
          }
  
          const updatedSigner = newProvider.getSigner(); // Get the new signer
          setSigner(updatedSigner);
  
          setGameContract(
            new ethers.Contract(DICE_ROLL_GAME_ADDRESS, diceRollGameAbi.abi, updatedSigner)
          ); // Re-initialize the contract with the new signer
  
          // Fetch and display game status on account change
          updateGameStatus(newContract);
        });
      } catch (err) {
        setError(`Error connecting to wallet: ${err.message}`);
      }
    } else {
      setError("MetaMask is not installed.");
    }
  };

  // Function to enter the game with an initial value
  const enterGame = async () => {
    if (gameContract && entryValue) {
      try {
        const tx = await gameContract.enter({
          value: ethers.utils.parseUnits(entryValue, "ether"),
          gasLimit: 100000,
        });
        await tx.wait(); // Wait for transaction confirmation
        setSuccessMsg("Entered the game successfully!");
        setShowExitButton(true); // Show Exit Game button after entering the game
      } catch (err) {
        setError(`Error entering the game: ${err.message}`);
        setShowExitButton(false); // Ensure Exit Game is hidden on error

      }
    } else {
      setError("Contract not initialized or invalid input.");
    }
  };

    // Function to exit the game
    const exitGame = async () => {
      if (gameContract && !gameStarted) {
        try {
          const tx = await gameContract.exitGame();
          await tx.wait(); // Wait for transaction confirmation
          setSuccessMsg("Exited the game successfully!");
          setShowEnterExitButtons(true); // Show enter and exit buttons after exiting the game
          setShowExitButton(false); // Hide Exit Game button after exiting the game
          updateGameStatus(gameContract); // Update the game status

        } catch (err) {
          setError(`Error exiting the game: ${err.message}`);
        }
      } else {
        setError("Cannot exit the game once it has started.");
      }
    };

  const placeBet = async () => {
    if (gameContract && betOutcome >= 1 && betOutcome <= 6) {
      try {
        setIsPlacingBet(true);
        const tx = await gameContract.placeBet(betOutcome);
        await tx.wait();
        setSuccessMsg("Bet placed successfully!");
        setIsPlacingBet(false); // Resetting too early?
        updateGameStatus(gameContract); // This call might trigger fetchGameResults()
      } catch (err) {
        setError(`Error placing bet: ${err.message}`);
        setIsPlacingBet(false); // Resetting here is correct
      }
    } else {
      setError("Invalid bet outcome.");
    }
  };
  



  // Function to cancel the bet
  const cancelBet = async () => {
    if (gameContract && gameStarted) {
      try {
        const tx = await gameContract.cancelBet();
        await tx.wait(); // Wait for transaction confirmation
        setSuccessMsg("Bet cancelled successfully!");
      } catch (err) {
        setError(`Error cancelling bet: ${err.message}`);
      }
    } else {
      setError("Cannot cancel the bet before the game starts.");
    }
  };


  const fetchGameResults = async () => {
    if (gameContract) {
      setIsFetchingResult(true); // Set flag to indicate fetching result
      try {
        const gameId = await gameContract.gameCounter(); // Get the latest game ID
        console.log("Latest Game ID:", gameId); // Debugging statement
        const latestGameRes = await gameContract.getGameResults(gameId - 1); // Get game results for the latest game ID
        console.log("Game Results for Latest ID:", latestGameRes); // Debugging statement
        
        if (!latestGameRes || latestGameRes.length === 0) {
          setGameResult(null); // Set gameResult to null if no results found
          console.log("No game results found.");
          return;
        }
  
        // Find the correct array for the current user
        const currentUserResult = latestGameRes.find(resultArray => resultArray[0].toLowerCase() === walletAddress.toLowerCase());
        
        // Check if the current user participated in the latest game
        if (currentUserResult) {
          // Extract values from the array
          const [participant, playerDiceValue, rolledDiceValue, didWin, amountWon, balanceAtEnd] = currentUserResult;
  
          // Convert BigNumber values to strings
          const filteredResult = {
            participant: participant,
            didWin: didWin,
            betOutcome: playerDiceValue.toString(),
            randomRoll: rolledDiceValue.toString(),
            reward: amountWon.toString(),
            playerBalance: balanceAtEnd.toString()
          };
          setGameResult(filteredResult); // Set gameResult to the modified object
        } else {
          setGameResult(null); // Set gameResult to null if current user did not participate
        }
  
        console.log("Game results fetched successfully!");
      } catch (err) {
        setError(`Error fetching game results: ${err.message}`);
      } finally {
        setIsFetchingResult(false); // Reset flag after fetching result
      }
    }
  };
  
  
  




  // Event listener for the "DiceRollResult" event
  const handleDiceRollResult = (player, betOutcome, randomRoll, win, reward, playerBalance) => {
    console.log("Event received:", { player, betOutcome, randomRoll, win, reward, playerBalance }); // Debugging statement
    // Convert BigNumber values to strings
    const betOutcomeStr = betOutcome.toString();
    const randomRollStr = randomRoll.toString();
    const rewardStr = reward.toString();
    const playerBalanceStr = playerBalance.toString();
    // Update the UI state based on the event data
    if (gameContract && player.toLowerCase() === walletAddress.toLowerCase()) {
      setGameResult({ participant: player, didWin: win, betOutcome: betOutcomeStr, randomRoll: randomRollStr, reward: rewardStr, playerBalance: playerBalanceStr });
    }
  };


  useEffect(() => {
    if (gameContract) {
      // Listen for the GameEnded event to update game status
      const handleGameEnded = async () => {
        await updateGameStatus(gameContract); // Update the game status
        setShowEnterExitButtons(true); // Show "Enter Game" when game ends
        setShowExitButton(false); // Hide "Exit Game" when game ends
        fetchGameResults();
      };
  
      gameContract.on("GameEnded", handleGameEnded);
  
      return () => {
        gameContract.off("GameEnded", handleGameEnded); // Clean up the event listener
      };
    }
  }, [gameContract]);
  
  

  // Function to handle page refresh
  const handlePageRefresh = () => {
    window.location.reload(); // Reload the page
  };

  // Function to handle Metamask address click
  const handleAddressClick = () => {
    if (provider) {
      fetchGameResults(); // Call fetchGameResults when Metamask address is clicked
    }
  };

  return (
<div className="App">
  <div className="gradient-background" style={{ paddingTop: '20px', marginTop: '-20px' }}>
    <div className="container pt-3 mt-5">
      <header className="text-center">
        <h1 className="display-5 fw-bold text-white lh-1 my-5 texttitle">Dice Roll Game</h1>
        <button onClick={connectWallet} className="btn btn-primary">
          {walletAddress ? `Connected: ${walletAddress}` : "Connect Wallet"}
        </button>
      </header>

      <div>
      <div className="pt-5 mt-5 mb-3">
    <p style={{ textAlign: 'center', color: gameStarted ? 'green' : 'white', fontSize: gameStarted ? '1.2em' : '1em', fontWeight: 'bold' }}>
        {gameStarted ? "Game has started! Place your bet." : "Game has not started. Enter to join!"}
    </p>
</div>




<table className="table  text-center transparent-table mb-3" style={{ width: '40%', margin: 'auto' }}>
  <tbody>
    <tr>
      <td style={{ color: 'white' }}>Players</td>
      <td style={{ color: 'white' }}>{playerCount}</td>
    </tr>
    <tr>
      <td style={{ color: 'white' }}>Total Balance</td>
      <td style={{ color: 'white' }}>{gameBalance} ETH</td>
    </tr>
  </tbody>
</table>

<div className="mb-5"></div>


<div className="row">
  <div className="col-md-6 mx-auto">
    <div className="input-group">
    {showEnterExitButtons && !gameStarted && (
      <>
      <input
        type="text"
        placeholder="Enter with value in ETH"
        value={entryValue}
        onChange={(e) => setEntryValue(e.target.value)}
        className="form-control rounded-start"
      />
          <button onClick={enterGame} className="btn btn-success rounded">Enter Game</button>
          {!gameStarted && showExitButton && (
            <button onClick={exitGame} className="btn btn-danger ml-2 rounded">Exit Game</button>
          )}
        </>
      )}
    </div>
  </div>
</div>



</div>
<div className="mt-5">
  {gameStarted && !isPlacingBet && (
    <div className="row">
      <h3 className="text-center">Place a Bet</h3>
      <div className="col-md-6 mx-auto">
        <div className="input-group">
          <input
            type="number"
            min={1}
            max={6}
            placeholder="Bet on a number (1-6)"
            value={betOutcome}
            onChange={(e) => setBetOutcome(parseInt(e.target.value, 10))}
            className="form-control rounded-start" 
          />
          <button onClick={placeBet} className="btn btn-primary rounded" style={{ height: "38px" }}>Place Bet</button>
        </div>
      </div>
    </div>
  )}
  {isPlacingBet &&     <p className="text-center" style={{ color: '#007bff' }}>Placing your bet...</p>
}
  {gameStarted && (
    <div className="row mt-3">
      <div className="col-md-6 mx-auto d-flex justify-content-center">
        <button onClick={cancelBet} className="btn btn-warning rounded" style={{ height: "38px" }}>Cancel Bet</button>
      </div>
    </div>
  )}
</div>

<div className="my-5 pt-5"></div>

<div className="mt-0 pt-5 pb-5" style={{ backgroundColor: '#efd285', border: '4px solid #0066b2', borderRadius: '8px', padding: '20px', color: '#000000' }}>
  <h3 className="mb-2"style={{ fontWeight: 'bold', fontSize: '20px' }}>Game Result</h3>
  {gameResult ? (
    <div className="mb-4">
      <p>
        <strong>Player:</strong> {gameResult.participant} - {gameResult.didWin ? "Won" : "Lost"}
        {gameResult.didWin && (
          <span>, <strong>Bet Outcome:</strong> {gameResult.betOutcome}, <strong>Dice Value:</strong> {gameResult.randomRoll}, <strong>Amount Won:</strong> {gameResult.reward} wei, <strong>Player Balance:</strong> {gameResult.playerBalance} wei</span>
        )}
        {!gameResult.didWin && (
          <span>, <strong>Bet Outcome:</strong> {gameResult.betOutcome}, <strong>Dice Value:</strong> {gameResult.randomRoll}, <strong>Player Balance:</strong> {gameResult.playerBalance} wei</span>
        )}
      </p>
    </div>
  ) : (
    <p>No game result available.</p>
  )}

  {!isFetchingResult && !gameStarted && (
    <div className="text-center">
      <button onClick={fetchGameResults} className="btn btn-info" >Fetch Game Result</button>
    </div>
  )}
  {isFetchingResult && (
    <div className="text-center" >
      <p>Fetching game result...</p>
    </div>
  )}
</div>


      <div className="mt-5 pt-5 pb-5">
        {error && (
          <div className="notification is-danger">
            <button className="delete" onClick={() => setError("")}></button>
            {error}
          </div>
        )}
        {successMsg && (
          <div className="notification is-success">
            <button className="delete" onClick={() => setSuccessMsg("")}></button>
            {successMsg}
          </div>
        )}
      </div>
    </div>
  </div>
</div>

  );
}


export default App;