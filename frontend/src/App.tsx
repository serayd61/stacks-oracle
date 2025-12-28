import React, { useState, useEffect } from 'react';
import PriceCard from './components/PriceCard';
import PriceChart from './components/PriceChart';
import ReporterList from './components/ReporterList';
import StatsPanel from './components/StatsPanel';

interface PriceData {
  pair: string;
  price: number;
  change24h: number;
  lastUpdate: Date;
  reporters: number;
}

const MOCK_PRICES: PriceData[] = [
  { pair: 'STX-USD', price: 1.25, change24h: 5.2, lastUpdate: new Date(), reporters: 5 },
  { pair: 'BTC-USD', price: 43250.00, change24h: 2.1, lastUpdate: new Date(), reporters: 5 },
  { pair: 'ETH-USD', price: 2280.50, change24h: -1.3, lastUpdate: new Date(), reporters: 5 },
  { pair: 'sBTC-USD', price: 43200.00, change24h: 2.0, lastUpdate: new Date(), reporters: 4 },
];

function App() {
  const [prices, setPrices] = useState<PriceData[]>(MOCK_PRICES);
  const [selectedPair, setSelectedPair] = useState('STX-USD');
  const [isLive, setIsLive] = useState(true);

  useEffect(() => {
    const interval = setInterval(() => {
      setPrices(prev => prev.map(p => ({
        ...p,
        price: p.price * (1 + (Math.random() - 0.5) * 0.002),
        lastUpdate: new Date(),
      })));
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-primary)' }}>
      {/* Header */}
      <header style={{
        padding: '20px 40px',
        borderBottom: '1px solid var(--border)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        background: 'var(--bg-secondary)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <span style={{ fontSize: '32px' }}>🔮</span>
          <div>
            <h1 style={{ fontSize: '24px', fontWeight: 700, margin: 0 }}>
              Stacks Oracle
            </h1>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)', margin: 0 }}>
              Decentralized Price Feeds
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <div style={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: '8px',
            padding: '8px 16px',
            background: isLive ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)',
            borderRadius: '20px',
            border: `1px solid ${isLive ? 'var(--success)' : 'var(--error)'}`,
          }}>
            <div style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              background: isLive ? 'var(--success)' : 'var(--error)',
              animation: isLive ? 'pulse 2s infinite' : 'none',
            }} />
            <span style={{ 
              fontSize: '12px', 
              fontWeight: 600,
              color: isLive ? 'var(--success)' : 'var(--error)',
            }}>
              {isLive ? 'LIVE' : 'OFFLINE'}
            </span>
          </div>

          <button style={{
            padding: '10px 24px',
            background: 'var(--accent-gradient)',
            border: 'none',
            borderRadius: '8px',
            color: 'white',
            fontWeight: 600,
            cursor: 'pointer',
            transition: 'transform 0.2s',
          }}
          onMouseOver={e => e.currentTarget.style.transform = 'scale(1.05)'}
          onMouseOut={e => e.currentTarget.style.transform = 'scale(1)'}
          >
            Become Reporter
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main style={{ padding: '40px' }}>
        {/* Stats */}
        <StatsPanel 
          totalFeeds={prices.length}
          totalReporters={5}
          totalUpdates={12847}
          avgResponseTime="1.2s"
        />

        {/* Price Cards */}
        <section style={{ marginTop: '40px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 600, marginBottom: '20px' }}>
            📊 Live Price Feeds
          </h2>
          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '20px',
          }}>
            {prices.map(price => (
              <PriceCard
                key={price.pair}
                pair={price.pair}
                price={price.price}
                change24h={price.change24h}
                lastUpdate={price.lastUpdate}
                reporters={price.reporters}
                isSelected={selectedPair === price.pair}
                onClick={() => setSelectedPair(price.pair)}
              />
            ))}
          </div>
        </section>

        {/* Chart */}
        <section style={{ marginTop: '40px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 600, marginBottom: '20px' }}>
            📈 {selectedPair} Price History
          </h2>
          <PriceChart pair={selectedPair} />
        </section>

        {/* Reporters */}
        <section style={{ marginTop: '40px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 600, marginBottom: '20px' }}>
            👥 Active Reporters
          </h2>
          <ReporterList />
        </section>
      </main>

      {/* Footer */}
      <footer style={{
        padding: '20px 40px',
        borderTop: '1px solid var(--border)',
        textAlign: 'center',
        color: 'var(--text-secondary)',
        fontSize: '14px',
      }}>
        Built on <span style={{ color: 'var(--stx-orange)' }}>Stacks</span> | 
        Made with 💜 by serayd61
      </footer>
    </div>
  );
}

export default App;

