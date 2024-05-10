import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import UserPage from './ethereum/UserPage'; // Import User component
import OwnerPage from './ethereum/OwnerPage'; // Import Owner component

function App() {
  return (
    <Router>
      <div className="App">
        {/* Main routing setup */}
        <Routes>
          {/* Define the landing page */}
          <Route
            path="/"
            element={
              <div>
                <h1>Welcome to Dice Roll Game</h1>
                <button>
                  <Link to="/user">User</Link>
                </button>
                <button>
                  <Link to="/owner">Owner</Link>
                </button>
              </div>
            }
          />
          {/* Route for user interface */}
          <Route path="/user" element={<UserPage />} />
          {/* Route for owner interface */}
          <Route path="/owner" element={<OwnerPage />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;