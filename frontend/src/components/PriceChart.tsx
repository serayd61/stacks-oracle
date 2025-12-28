import React, { useState, useEffect } from 'react';

interface PriceChartProps {
  pair: string;
}

function PriceChart({ pair }: PriceChartProps) {
  const [data, setData] = useState<number[]>([]);
  const [timeframe, setTimeframe] = useState<'1H' | '24H' | '7D'>('24H');

  useEffect(() => {
    // Generate mock data
    const points = timeframe === '1H' ? 12 : timeframe === '24H' ? 24 : 7;
    const basePrice = pair === 'STX-USD' ? 1.25 : pair === 'BTC-USD' ? 43000 : 2200;
    const newData = Array.from({ length: points }, (_, i) => 
      basePrice * (1 + (Math.sin(i * 0.5) + Math.random() - 0.5) * 0.05)
    );
    setData(newData);
  }, [pair, timeframe]);

  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;

  const pathD = data.map((price, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - ((price - min) / range) * 100;
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  const isPositive = data.length > 1 && data[data.length - 1] > data[0];

  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '1px solid var(--border)',
      borderRadius: '16px',
      padding: '24px',
    }}>
      {/* Timeframe Selector */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
        {(['1H', '24H', '7D'] as const).map(tf => (
          <button
            key={tf}
            onClick={() => setTimeframe(tf)}
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              border: 'none',
              background: timeframe === tf ? 'var(--accent-primary)' : 'var(--bg-secondary)',
              color: timeframe === tf ? 'white' : 'var(--text-secondary)',
              cursor: 'pointer',
              fontWeight: 600,
              transition: 'all 0.2s',
            }}
          >
            {tf}
          </button>
        ))}
      </div>

      {/* Chart */}
      <div style={{ position: 'relative', height: '300px' }}>
        <svg
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
          style={{
            width: '100%',
            height: '100%',
          }}
        >
          {/* Gradient */}
          <defs>
            <linearGradient id="chartGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={isPositive ? '#22c55e' : '#ef4444'} stopOpacity="0.3" />
              <stop offset="100%" stopColor={isPositive ? '#22c55e' : '#ef4444'} stopOpacity="0" />
            </linearGradient>
          </defs>

          {/* Fill */}
          <path
            d={`${pathD} L 100 100 L 0 100 Z`}
            fill="url(#chartGradient)"
          />

          {/* Line */}
          <path
            d={pathD}
            fill="none"
            stroke={isPositive ? 'var(--success)' : 'var(--error)'}
            strokeWidth="0.5"
            vectorEffect="non-scaling-stroke"
          />
        </svg>

        {/* Price Labels */}
        <div style={{
          position: 'absolute',
          top: '10px',
          right: '10px',
          background: 'rgba(0,0,0,0.7)',
          padding: '8px 12px',
          borderRadius: '8px',
          fontFamily: "'JetBrains Mono', monospace",
          fontSize: '14px',
        }}>
          <div style={{ color: 'var(--text-secondary)', fontSize: '11px' }}>Current</div>
          <div style={{ fontWeight: 700 }}>
            ${data[data.length - 1]?.toFixed(pair === 'STX-USD' ? 4 : 2)}
          </div>
        </div>

        {/* Min/Max */}
        <div style={{
          position: 'absolute',
          top: '0',
          left: '0',
          fontSize: '10px',
          color: 'var(--text-muted)',
          fontFamily: "'JetBrains Mono', monospace",
        }}>
          ${max.toFixed(2)}
        </div>
        <div style={{
          position: 'absolute',
          bottom: '0',
          left: '0',
          fontSize: '10px',
          color: 'var(--text-muted)',
          fontFamily: "'JetBrains Mono', monospace",
        }}>
          ${min.toFixed(2)}
        </div>
      </div>
    </div>
  );
}

export default PriceChart;

