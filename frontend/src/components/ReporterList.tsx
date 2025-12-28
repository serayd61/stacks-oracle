import React from 'react';

interface Reporter {
  address: string;
  name: string;
  stake: number;
  submissions: number;
  accuracy: number;
  status: 'active' | 'inactive' | 'slashed';
}

const MOCK_REPORTERS: Reporter[] = [
  { address: 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7', name: 'Alpha Node', stake: 50000, submissions: 12847, accuracy: 99.8, status: 'active' },
  { address: 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE', name: 'Beta Oracle', stake: 35000, submissions: 11234, accuracy: 99.5, status: 'active' },
  { address: 'SP1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', name: 'Gamma Feed', stake: 25000, submissions: 8765, accuracy: 99.2, status: 'active' },
  { address: 'SP9876543210ZYXWVUTSRQPONMLKJIHGFEDCBA', name: 'Delta Price', stake: 20000, submissions: 7654, accuracy: 98.9, status: 'active' },
  { address: 'SPABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890', name: 'Epsilon Data', stake: 15000, submissions: 5432, accuracy: 98.5, status: 'inactive' },
];

function shortenAddress(addr: string): string {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

function ReporterList() {
  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '1px solid var(--border)',
      borderRadius: '16px',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '2fr 1fr 1fr 1fr 100px',
        padding: '16px 24px',
        background: 'var(--bg-secondary)',
        borderBottom: '1px solid var(--border)',
        fontSize: '12px',
        color: 'var(--text-secondary)',
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
        fontWeight: 600,
      }}>
        <div>Reporter</div>
        <div>Staked</div>
        <div>Submissions</div>
        <div>Accuracy</div>
        <div>Status</div>
      </div>

      {/* Rows */}
      {MOCK_REPORTERS.map((reporter, i) => (
        <div
          key={reporter.address}
          style={{
            display: 'grid',
            gridTemplateColumns: '2fr 1fr 1fr 1fr 100px',
            padding: '16px 24px',
            borderBottom: i < MOCK_REPORTERS.length - 1 ? '1px solid var(--border)' : 'none',
            transition: 'background 0.2s',
          }}
          onMouseOver={e => e.currentTarget.style.background = 'var(--bg-hover)'}
          onMouseOut={e => e.currentTarget.style.background = 'transparent'}
        >
          {/* Reporter Info */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{
              width: '40px',
              height: '40px',
              borderRadius: '10px',
              background: `linear-gradient(135deg, hsl(${i * 60}, 70%, 50%) 0%, hsl(${i * 60 + 30}, 70%, 40%) 100%)`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: '14px',
            }}>
              {reporter.name[0]}
            </div>
            <div>
              <div style={{ fontWeight: 600 }}>{reporter.name}</div>
              <div style={{ 
                fontSize: '12px', 
                color: 'var(--text-muted)',
                fontFamily: "'JetBrains Mono', monospace",
              }}>
                {shortenAddress(reporter.address)}
              </div>
            </div>
          </div>

          {/* Stake */}
          <div style={{ 
            display: 'flex', 
            alignItems: 'center',
            fontFamily: "'JetBrains Mono', monospace",
            fontWeight: 500,
          }}>
            {reporter.stake.toLocaleString()} STX
          </div>

          {/* Submissions */}
          <div style={{ 
            display: 'flex', 
            alignItems: 'center',
            fontFamily: "'JetBrains Mono', monospace",
          }}>
            {reporter.submissions.toLocaleString()}
          </div>

          {/* Accuracy */}
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <div style={{
              background: reporter.accuracy >= 99 
                ? 'rgba(34, 197, 94, 0.15)' 
                : reporter.accuracy >= 98 
                  ? 'rgba(245, 158, 11, 0.15)'
                  : 'rgba(239, 68, 68, 0.15)',
              color: reporter.accuracy >= 99 
                ? 'var(--success)' 
                : reporter.accuracy >= 98 
                  ? 'var(--warning)'
                  : 'var(--error)',
              padding: '4px 10px',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 600,
              fontFamily: "'JetBrains Mono', monospace",
            }}>
              {reporter.accuracy}%
            </div>
          </div>

          {/* Status */}
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}>
              <div style={{
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                background: reporter.status === 'active' 
                  ? 'var(--success)' 
                  : reporter.status === 'inactive' 
                    ? 'var(--warning)'
                    : 'var(--error)',
                animation: reporter.status === 'active' ? 'pulse 2s infinite' : 'none',
              }} />
              <span style={{
                fontSize: '12px',
                fontWeight: 500,
                textTransform: 'capitalize',
                color: reporter.status === 'active' 
                  ? 'var(--success)' 
                  : reporter.status === 'inactive' 
                    ? 'var(--warning)'
                    : 'var(--error)',
              }}>
                {reporter.status}
              </span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export default ReporterList;

