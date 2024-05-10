import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import 'bulma/css/bulma.css';
import "bootstrap/dist/css/bootstrap.min.css"; // Import Bootstrap
import diceRollGameAbi from './DiceRollGame.json';
import randomWordLibraryAbi from './RandomWordLibrary.json';
import "../App.css";

const RANDOM_WORD_LIBRARY_ADDRESS = '0x8110b8204F50303d8001AE0eE07CcdFCa75BfeA9';
const DICE_ROLL_GAME_ADDRESS = '0x68cb81F58db50F9A79355900c5C2114f49B39Be0';

function OwnerPage() {
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  const [randomWordLibraryContract, setRandomWordLibraryContract] = useState(null); // Add this line
  const [ownerAddress, setOwnerAddress] = useState('');
  const [playerCount, setPlayerCount] = useState(0); // Number of players
  const [gameStarted, setGameStarted] = useState(false);
  const [gameCounter, setGameCounter] = useState(0);
  const [gameBalance, setGameBalance] = useState('');
  const [totalBetAmount, setTotalBetAmount] = useState('');
  const [ownerRewardPercentage, setOwnerRewardPercentage] = useState('');
  const [predefinedBettingAmount, setPredefinedBettingAmount] = useState('');
  const [maxPlayers, setMaxPlayers] = useState('');
  const [newOwnerReward, setNewOwnerReward] = useState('');
  const [newPredefinedBet, setNewPredefinedBet] = useState('');
  const [newMaxPlayers, setNewMaxPlayers] = useState('');
  const [players, setPlayers] = useState([]);
  const [gameHistory, setGameHistory] = useState([]); // Initialize as an empty array
  const [gameHistoryId, setGameHistoryId] = useState(0);
  const [requestId, setRequestId] = useState(null); // Store the last request ID
  const [intervalId, setIntervalId] = useState(null); // Store the interval ID
  const [showSettings, setShowSettings] = useState(false);
  const [showAdditionalFunctions, setShowAdditionalFunctions] = useState(false);
  
  useEffect(() => {
    connectWallet(); // Connect to MetaMask when the component is mounted
  }, []);

  // Connect to MetaMask and setup the contract
  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts',
        });
        const newProvider = new ethers.providers.Web3Provider(window.ethereum);
        const newSigner = newProvider.getSigner();
        const newContract = new ethers.Contract(
          DICE_ROLL_GAME_ADDRESS,
          diceRollGameAbi.abi,
          newSigner
        );
        const randomWordLibraryContract = new ethers.Contract(
          RANDOM_WORD_LIBRARY_ADDRESS,
          randomWordLibraryAbi.abi,
          newSigner
        );
  
        setProvider(newProvider);
        setContract(newContract);
        setRandomWordLibraryContract(randomWordLibraryContract);
        setOwnerAddress(accounts[0]);
  
        // Fetch contract data
        const hasGameStarted = await newContract.gameStarted();
        setGameStarted(hasGameStarted);

        const players = await contract.getPlayers(); // Get the players
        setPlayerCount(players.length);
  
        const currentGameCounter = await newContract.gameCounter();
        setGameCounter(currentGameCounter.toNumber());
  
        const currentBalance = await newContract.getBalance();
        setGameBalance(ethers.utils.formatEther(currentBalance));
  
        const totalBet = await newContract.totalBetAmount();
        setTotalBetAmount(totalBet.toString());
  
        setOwnerRewardPercentage((await newContract.ownerRewardPercentage()).toNumber());
        setPredefinedBettingAmount(
          ethers.utils.formatUnits(await newContract.getPredefinedBettingAmount(), 'ether')
        );
        setMaxPlayers((await newContract.maxPlayers()).toNumber());
      } catch (err) {
        console.error('Error connecting to wallet:', err);
      }
    } else {
      console.error('MetaMask is not installed.');
    }
  };
  

  // Function to start the game
  const startGame = async () => {
    if (contract && !gameStarted) {
      try {
        const tx = await contract.startGame();
        await tx.wait();
        setGameStarted(true);
      } catch (err) {
        console.error('Error starting the game:', err);
      }
    }
  };

// to update game information
const updateGameInformation = async () => {
    if (contract) {
      try {
        const hasGameStarted = await contract.gameStarted();
        setGameStarted(hasGameStarted);

        const players = await contract.getPlayers(); // Get the players
        setPlayerCount(players.length);
  
        const currentGameCounter = await contract.gameCounter();
        setGameCounter(currentGameCounter.toNumber());
  
        const currentBalance = await contract.getBalance();
        setGameBalance(ethers.utils.formatEther(currentBalance));
  
        const totalBet = await contract.totalBetAmount();
        setTotalBetAmount(totalBet.toString());
  
        setOwnerRewardPercentage((await contract.ownerRewardPercentage()).toNumber());
        setPredefinedBettingAmount(
          ethers.utils.formatUnits(await contract.getPredefinedBettingAmount(), 'ether')
        );
        setMaxPlayers((await contract.maxPlayers()).toNumber());
      } catch (err) {
        console.error('Error updating game information:', err);
      }
    }
  };



  function delay(milliseconds) {
    return new Promise(resolve => {
      setTimeout(resolve, milliseconds);
    });
  }


  // Function to roll dice and distribute rewards           console.log('Random word requested. Request ID:', requestId.toString(10));

  const rollDiceAndDistributeRewards = async () => {
    const requestId = await randomWordLibraryContract.getLastRequestId();
    await randomWordLibraryContract.requestRandomWords();
    await delay(1000); // Wait for 1 seconds

    if (contract && gameStarted && randomWordLibraryContract) {
      console.log('Rolling dice...');
      try {
        //await delay(1000); // Wait for 1 seconds
        const newRequestId = await randomWordLibraryContract.getLastRequestId();
        console.log('Random word requested. Request ID:', newRequestId);
        console.log('Random word requested. OLD Request ID:', requestId.toString(10));
        console.log('Random word requested. NEW Request ID:', newRequestId.toString(10));
        // Check if the new request ID is different from the stored one
        if (newRequestId.toString(10) !== requestId.toString(10)) {
          clearInterval(intervalId); // Clear the previous interval
          setRequestId(newRequestId); // Update the request ID
  
          const newIntervalId = setInterval(async () => {
            try {
              const randomWord = await randomWordLibraryContract.fetchRandomWord(newRequestId);
              console.log('Fetched random word:', randomWord);
              if (randomWord !== 0) {
                clearInterval(newIntervalId);
                console.log('Dice rolled successfully. Distributing rewards...');
                const tx = await contract.rollDiceAndDistributeRewards({ gasLimit: 2000000 });
                await tx.wait();
                console.log('Rewards distributed successfully.');
                setGameStarted(false);
                
                // Update game information after rolling dice
                updateGameInformation();

              } else {
                console.log('Random word not fetched yet. Waiting...');
              }
            } catch (fetchError) {
              console.error('Error fetching random word:', fetchError);
            }
          }, 10000);
          setIntervalId(newIntervalId); // Store the new interval ID
        } else {
          // If the request ID hasn't been updated, fetch the latest request ID again
          console.log('Request ID has not been updated. Fetching latest ID...');
          rollDiceAndDistributeRewards();
        }
      } catch (requestError) {
        console.error('Error requesting random words:', requestError);
      }
    }
  };
  
  
  
  

  // Function to set the owner reward percentage
  const setOwnerReward = async () => {
    if (contract && !gameStarted && newOwnerReward >= 0 && newOwnerReward <= 10) {
      try {
        const tx = await contract.setOwnerRewardPercentage(newOwnerReward);
        await tx.wait();
        setOwnerRewardPercentage(newOwnerReward); // Update after transaction confirmation
        updateGameInformation();
      } catch (err) {
        console.error('Error setting owner reward percentage:', err);
      }
    }
  };

  // Function to set the predefined betting amount
  const setPredefinedBetting = async () => {
    if (contract && !gameStarted) {
      try {
        const newPredefinedAmount = ethers.utils.parseUnits(newPredefinedBet, 'ether');
        const tx = await contract.setPredefinedBettingAmount(newPredefinedAmount);
        await tx.wait();
        setPredefinedBettingAmount(newPredefinedBet); // Update after transaction
        updateGameInformation();
      } catch (err) {
        console.error('Error setting predefined betting amount:', err);
      }
    }
  };

  // Function to set the maximum number of players
  const setMaxPlayersInGame = async () => {
    if (contract && !gameStarted && newMaxPlayers > 0) {
      try {
        const tx = await contract.setMaxPlayers(newMaxPlayers);
        await tx.wait();
        setMaxPlayers(newMaxPlayers); // Update after transaction
        updateGameInformation();
      } catch (err) {
        console.error('Error setting max players:', err);
      }
    }
  };



  const getPlayers = async () => {
    if (contract) {
      try {
        const playersList = await contract.getPlayers();
        if (playersList.length > 0) {
          setPlayers(playersList.map((p) => p.toString())); // Store the players list as strings
        } else {
          console.warn('No players found.');
        }
      } catch (err) {
        console.error('Error getting players:', err);
      }
    }
  };

  const getGameResults = async () => {
    if (contract && !isNaN(gameHistoryId) && gameHistoryId >= 0) {
      try {
        const results = await contract.getGameResults(gameHistoryId);
        if (results.length > 0) {
          setGameHistory(
            results.map((r) => ({
              participant: r.participant.toString(),
              playerDiceValue: r.playerDiceValue.toString(),
              rolledDiceValue: r.rolledDiceValue.toString(),
              didWin: r.didWin,
              amountWon: r.amountWon.toString(),
              balanceAtEnd: r.balanceAtEnd.toString(),
            }))
          );
        } else {
          console.warn('No game history found for this game ID.');
          setGameHistory([]); // Ensure empty array to prevent errors
        }
      } catch (err) {
        console.error('Error getting game history:', err);
      }
    }
  };

  return (
    <div className="App">
    <div className="gradient-background" style={{ paddingTop: '20px', marginTop: '-20px' }}>
    <div>
    <div className="container pt-3 mt-5">
    <header className="text-center">
      <h1 className="display-5 fw-bold text-white lh-1 my-5 texttitle">Owner Page</h1>
    
      <button onClick={connectWallet} className="btn btn-primary">
        {ownerAddress ? `Connected: ${ownerAddress}` : 'Connect Wallet'}
      </button>
      </header></div>





      <div className="mt-5" style={{ display: 'flex', justifyContent: 'space-between' }}>
      <section className="my-4 mt-5" style={{ width: '60%', borderRight: '1px solid #ccc', paddingRight: '10px' }}>
      <h2 className="mb-4"style={{ fontWeight: 'bold', fontSize: '20px', textAlign:"center",color:"white"  }}>Game Information</h2>
    <table className="table text-center transparent-table mb-3" style={{ width: '70%',margin: 'auto' }}>
      <tbody>
        <tr>
          <td style={{ color: 'white' }}>Game Started</td>
          <td style={{ color: 'white' }}>{gameStarted ? 'Yes' : 'No'}</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Players</td>
          <td style={{ color: 'white' }}>{playerCount}</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Game Counter</td>
          <td style={{ color: 'white' }}>{gameCounter}</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Game Balance</td>
          <td style={{ color: 'white' }}>{gameBalance} ETH</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Total Betted Amount</td>
          <td style={{ color: 'white' }}>{totalBetAmount} wei</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Owner Reward Percentage</td>
          <td style={{ color: 'white' }}>{ownerRewardPercentage}%</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Predefined Betting Amount</td>
          <td style={{ color: 'white' }}>{predefinedBettingAmount} ETH</td>
        </tr>
        <tr>
          <td style={{ color: 'white' }}>Max Players</td>
          <td style={{ color: 'white' }}>{maxPlayers}</td>
        </tr>
      </tbody>
    </table>
  </section>



  <section style={{ width: '45%', paddingLeft: '20px', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
  <div className='mt-5'></div>
  <div className='mt-5'></div>
  <h2 className="mb-4"style={{ fontWeight: 'bold', fontSize: '20px', textAlign:"center",color:"white"  }}>Actions</h2>
  <div className='mt-5'></div>
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
    <button onClick={startGame} className="button is-success mb-5" style={{ marginBottom: '10px', width: '325px' }} disabled={gameStarted}>
      Start Game
    </button>
    <button onClick={rollDiceAndDistributeRewards} className="button is-danger " style={{ width: '325px' }} disabled={!gameStarted}>
      Roll Dice and Distribute Rewards
    </button>
  </div>
</section>

</div>



<div className='mt-5'></div>

<div >
<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center'}}>

  <div className="" style={{ backgroundColor: 'rgba(211, 211, 211, 0.17)', borderRadius: '8px', padding: '10px', width: '60%'}}>
    <h3 className="d-flex justify-content-center text-white" onClick={() => setShowSettings(!showSettings)} style={{ cursor: 'pointer', fontSize: '1.2rem' }}>
      Owner Settings  {showSettings ? '▲' : '▼'}
    </h3>
  </div></div>
  <div className='mt-2' style={{ display: 'flex', justifyContent: 'center', alignItems: 'center'}}>
    {showSettings && (
      <div className="px-4 py-3" style={{ backgroundColor: 'rgba(211, 211, 211, 0.17)', borderRadius: '8px', padding: '10px', width: '60%'}}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <input
            type="number"
            placeholder="Set Owner Reward % (0-10)"
            value={newOwnerReward}
            onChange={(e) => setNewOwnerReward(parseInt(e.target.value, 10))}
            style={{ width: '70%', marginRight: '0px', borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px', border: 'none', height: '35px' }}
          />
          <button onClick={setOwnerReward} className="button is-link" style={{ width: '30%' }}>
            Set Owner Reward Percentage
          </button>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: '10px' }}>
          <input
            type="text"
            placeholder="Set Predefined Bet (in ETH)"
            value={newPredefinedBet}
            onChange={(e) => setNewPredefinedBet(e.target.value)}
            style={{ width: '70%', marginRight: '0px', borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px', border: 'none', height: '35px' }}
          />
          <button onClick={setPredefinedBetting} className="button is-link" style={{ width: '30%' }}>
            Set Predefined Bet Amount
          </button>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: '10px' }}>
          <input
            type="number"
            placeholder="Set Max Players"
            value={newMaxPlayers}
            onChange={(e) => setNewMaxPlayers(parseInt(e.target.value, 10))}
            style={{ width: '70%', marginRight: '0px', borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px', border: 'none', height: '35px' }}
          />
          <button onClick={setMaxPlayersInGame} className="button is-link" style={{ width: '30%' }}>
            Set Max Players
          </button>
        </div>
      </div>
    )}
  </div>
</div>

<div className='mt-3'></div>

<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
      <div className="" style={{ backgroundColor: 'rgba(211, 211, 211, 0.17)', borderRadius: '8px', padding: '10px', width: '60%' }}>
        <h3 className="d-flex justify-content-center text-white" onClick={() => setShowAdditionalFunctions(!showAdditionalFunctions)} style={{ cursor: 'pointer', fontSize: '1.2rem' }}>
          Additional Functions  {showAdditionalFunctions ? '▲' : '▼'}
        </h3>
        {showAdditionalFunctions && (
          <section>
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '10px' , marginTop: '20px'}}>
              <button onClick={getPlayers} className="button is-info">
                Get Players
              </button>
            </div>
            <div style={{ color: 'white' }}>
            <h4 style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>Players:</h4>
              {players.length > 0 ? (
                <ul>
                  {players.map((player, index) => (
                    <li key={index}>{player}</li>
                  ))}
                </ul>
              ) : (
                <p>No players found.</p>
              )}
            </div>


            <div style={{ color: 'white', marginTop: '30px' }}>

              <div style={{ display: 'flex', justifyContent: 'center', marginTop: '10px' }}>
              <input
                type="number"
                placeholder="Game ID"
                value={gameHistoryId}
                onChange={(e) => setGameHistoryId(parseInt(e.target.value, 10))}
                style={{ width: '30%', marginRight: '0px', marginTop: '1px', borderTopLeftRadius: '8px', borderBottomLeftRadius: '8px', border: 'none', height: '36px' }}
              />
              
                <button onClick={getGameResults} className="button is-link ">
                  Get Game History
                </button>
              </div>
              <h4 className="mt-3" style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>Game History:</h4>

              {gameHistory.length > 0 ? (
                <ul>
                  {gameHistory.map((result, index) => (
                    <li key={index}>
                      <strong style={{ color: 'white' }}>Participant:</strong> {result.participant}, <strong style={{ color: 'white' }}>Dice Value Chosen:</strong> {result.playerDiceValue}, <strong style={{ color: 'white' }}>Rolled Dice Value:</strong> {result.rolledDiceValue}, <strong style={{ color: 'white' }}>Did Win:</strong> {result.didWin ? 'Yes' : 'No'}, <strong style={{ color: 'white' }}>Amount Won:</strong> {result.amountWon} wei, <strong style={{ color: 'white' }}>Balance At End:</strong> {result.balanceAtEnd} wei
                    </li>
                  ))}
                </ul>
              ) : (
                <p>No game history found for this Game ID.</p>
              )}

            </div>
          </section>
        )}
      </div>
    </div>

    <div className='py-5'></div>


    </div>
    </div></div>
  );
}

export default OwnerPage;
