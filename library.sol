// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the SubscriptionConsumer contract
import "contracts/vrf.sol";

contract RandomWordLibrary {
    SubscriptionConsumer public subscriptionConsumer; // Instance of SubscriptionConsumer

    constructor(address _subscriptionConsumerAddress) {
        // Initialize with the provided SubscriptionConsumer contract address
        subscriptionConsumer = SubscriptionConsumer(_subscriptionConsumerAddress);
    }

    // Function to request random words
    function requestRandomWords() public returns (uint256) {
        // Get the request ID from SubscriptionConsumer
        return subscriptionConsumer.requestRandomWords();
    }

    // Function to fetch the latest random word using the last request ID
    function fetchRandomWord(uint256 requestId) public view returns (uint256) {
        // Get the status of the request and ensure it's fulfilled
        (bool fulfilled, uint256[] memory randomWords) = subscriptionConsumer.getRequestStatus(requestId);
        require(fulfilled, "Random words request not yet fulfilled");
        require(randomWords.length > 0, "No random words available");

        // Return the random word associated with the request ID
        return randomWords[0];
    }

    // Function to get the last request ID
    function getLastRequestId() public view returns (uint256) {
        return subscriptionConsumer.lastRequestId();
    }


    struct GameOutcome {
        uint256 outcome;
        uint256 probability;
    }

    struct Fraction {
        uint256 nominator;
        uint256 denominator;
    }

        // Define a struct to represent the state of a game
    struct GameState {
        address player;
        uint256 betAmount;
        GameOutcome[] possibleOutcomes;
    }

    // Generate a random number within the specified range [min, max]
    function generateRandomNumber(uint256 min, uint256 max) public view returns (uint256) {
        require(max > min, "Invalid range");
        uint256 requestId = getLastRequestId();
        uint256 randomNumber = fetchRandomWord(requestId) % (max - min + 1) + min;
        return randomNumber;
    }

    // Calculate the probability of an event given the numerator and denominator
    function calculateProbability(uint256 numerator, uint256 denominator) public pure returns (uint256) {
        require(denominator != 0, "Denominator cannot be zero");
        return (numerator * 100) / denominator; // Return probability as a percentage (0-100)
    }

    // Calculate the probability of exactly k successes in n trials with probability p for each trial
    function calculateBinomialProbability(uint256 n, uint256 k, uint256 p) public pure returns (uint256) {
        require(n >= k, "Number of trials must be greater than or equal to number of successes");
        require(p >= 0 && p <= 100, "Probability must be between 0 and 100");

        uint256 combinationNK = factorial(n) / (factorial(k) * factorial(n - k));
        uint256 probability = combinationNK * ((p ** k) * ((100 - p) ** (n - k))) / (100 ** n);
        return probability;
    }

    // Internal function to calculate factorial
    function factorial(uint256 n) internal pure returns (uint256) {
        if (n == 0) {
            return 1;
        } else {
            return n * factorial(n - 1);
        }
    }

    // Simulate flipping a fair coin
    function simulateCoinFlip() public view returns (uint256) {
        // Generate a random number between 0 and 1
        uint256 randomNumber = generateRandomNumber(0, 1);
        
        // Return Heads if randomNumber is 0, otherwise return Tails
        if (randomNumber == 0) {
            return 0; // Heads
        } else {
            return 1; // Tails
        }
    }

    // Simulate the outcome of rolling a dice with `sides` number of sides
    function simulateDiceRoll(uint256 sides) public view returns (uint256) {
        require(sides > 0, "Invalid number of sides");
        return generateRandomNumber(1, sides);
    }

    // Simulate spinning a fair roulette wheel
    function simulateRouletteSpin() public view returns (uint256) {
        // Generate a random number between 0 and 36 (representing the numbers on the roulette wheel)
        return generateRandomNumber(0, 36);
    }

    // Simulate drawing `cardsToDraw` cards from a deck of `totalCards` cards
    function simulateCardDraw(uint256 totalCards, uint256 cardsToDraw) public view returns (uint256[] memory) {
        require(totalCards > 0 && cardsToDraw > 0 && cardsToDraw <= totalCards, "Invalid parameters");

        uint256[] memory drawnCards = new uint256[](cardsToDraw);
        uint256 remainingCards = totalCards;
        for (uint256 i = 0; i < cardsToDraw; i++) {
            drawnCards[i] = generateRandomNumber(1, remainingCards);
            remainingCards--;
        }

        return drawnCards;
    }

    // Determine the winner based on a list of possible outcomes and their corresponding probabilities
    function determineWinner(uint256[] memory outcomes, uint256[] memory probabilities) public view returns (uint256) {
        require(outcomes.length == probabilities.length, "Length mismatch");

        uint256 totalProbability = 0;
        for (uint256 i = 0; i < probabilities.length; i++) {
            totalProbability += probabilities[i];
        }

        uint256 randomNumber = generateRandomNumber(1, totalProbability);
        uint256 cumulativeProbability = 0;
        for (uint256 i = 0; i < probabilities.length; i++) {
            cumulativeProbability += probabilities[i];
            if (randomNumber <= cumulativeProbability) {
                return outcomes[i];
            }
        }

        // Fallback in case of unexpected situation
        revert("Unable to determine winner");
    }

    // Handle errors gracefully and provide informative error messages to users
    function handleError(string memory errorMessage) internal pure {
        revert(errorMessage);
    }

    // Implement a mechanism to recover funds in case of errors or disputes
    function recoverFunds(address recipient, uint256 amount) internal {
        payable(recipient).transfer(amount);
    }



}

