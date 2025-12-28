import React from 'react';

interface PriceCardProps {
  pair: string;
  price: number;
  change24h: number;
  lastUpdate: Date;
  reporters: number;
  isSelected: boolean;
  onClick: () => void;
}

const ICONS: Record<string, string> = {
  'STX-USD': '⚡',
  'BTC-USD': '₿',
  'ETH-USD': 'Ξ',
  'sBTC-USD': '🔸',
};

function PriceCard({ pair, price, change24h, lastUpdate, reporters, isSelected, onClick }: PriceCardProps) {
  const isPositive = change24h >= 0;
  const formattedPrice = pair.includes('BTC') || pair.includes('ETH') 
    ? price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    : price.toFixed(4);

  return (
    <div
      onClick={onClick}
      style={{
        background: isSelected 
          ? 'linear-gradient(135deg, rgba(124, 58, 237, 0.2) 0%, rgba(168, 85, 247, 0.1) 100%)'
          : 'var(--bg-card)',
        border: `1px solid ${isSelected ? 'var(--accent-primary)' : 'var(--border)'}`,
        borderRadius: '16px',
        padding: '24px',
        cursor: 'pointer',
        transition: 'all 0.3s ease',
        animation: 'slideUp 0.5s ease-out',
      }}
      onMouseOver={e => {
        if (!isSelected) {
          e.currentTarget.style.borderColor = 'var(--text-muted)';
          e.currentTarget.style.background = 'var(--bg-hover)';
        }
      }}
      onMouseOut={e => {
        if (!isSelected) {
          e.currentTarget.style.borderColor = 'var(--border)';
          e.currentTarget.style.background = 'var(--bg-card)';
        }
      }}
    >
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '28px' }}>{ICONS[pair] || '💰'}</span>
          <div>
            <div style={{ fontWeight: 600, fontSize: '16px' }}>{pair}</div>
            <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              {reporters} reporters
            </div>
          </div>
        </div>
        <div style={{
          padding: '4px 10px',
          borderRadius: '12px',
          fontSize: '12px',
          fontWeight: 600,
          background: isPositive ? 'rgba(34, 197, 94, 0.15)' : 'rgba(239, 68, 68, 0.15)',
          color: isPositive ? 'var(--success)' : 'var(--error)',
        }}>
          {isPositive ? '+' : ''}{change24h.toFixed(2)}%
        </div>
      </div>

      {/* Price */}
      <div style={{
        fontSize: '32px',
        fontWeight: 700,
        fontFamily: "'JetBrains Mono', monospace",
        marginBottom: '16px',
      }}>
        ${formattedPrice}
      </div>

      {/* Footer */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingTop: '12px',
        borderTop: '1px solid var(--border)',
        fontSize: '12px',
        color: 'var(--text-secondary)',
      }}>
        <span>Last update</span>
        <span style={{ fontFamily: "'JetBrains Mono', monospace" }}>
          {lastUpdate.toLocaleTimeString()}
        </span>
      </div>
    </div>
  );
}

export default PriceCard;

