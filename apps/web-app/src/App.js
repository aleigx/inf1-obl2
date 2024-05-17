import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Welcome to Our eCommerce Site</h1>
      </header>
      <main>
        <section className="hero">
          <h2>About Us</h2>
          <p>We offer the best products at the best prices.</p>
        </section>
        <section className="features">
          <div className="feature">
            <h3>Wide Selection</h3>
            <p>Choose from a wide variety of products across different categories.</p>
          </div>
          <div className="feature">
            <h3>Best Prices</h3>
            <p>Our prices are unbeatable, offering you great value for your money.</p>
          </div>
          <div className="feature">
            <h3>Fast Shipping</h3>
            <p>Enjoy fast and reliable shipping on all orders.</p>
          </div>
        </section>
      </main>
      <footer>
        <p>© 2024 eCommerce Site. All rights reserved.</p>
      </footer>
    </div>
  );
}

export default App;
