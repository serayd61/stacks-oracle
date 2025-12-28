import React from 'react';

interface StatsPanelProps {
  totalFeeds: number;
  totalReporters: number;
  totalUpdates: number;
  avgResponseTime: string;
}

function StatsPanel({ totalFeeds, totalReporters, totalUpdates, avgResponseTime }: StatsPanelProps) {
  const stats = [
    { label: 'Price Feeds', value: totalFeeds.toString(), icon: '📊', color: '#7c3aed' },
    { label: 'Active Reporters', value: totalReporters.toString(), icon: '👥', color: '#22c55e' },
    { label: 'Total Updates', value: totalUpdates.toLocaleString(), icon: '🔄', color: '#f59e0b' },
    { label: 'Avg Response', value: avgResponseTime, icon: '⚡', color: '#ec4899' },
  ];

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
      gap: '20px',
    }}>
      {stats.map((stat, i) => (
        <div
          key={stat.label}
          style={{
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: '16px',
            padding: '24px',
            animation: 'slideUp 0.5s ease-out',
            animationDelay: `${i * 0.1}s`,
            animationFillMode: 'backwards',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            <span style={{ fontSize: '24px' }}>{stat.icon}</span>
            <span style={{ 
              fontSize: '12px', 
              color: 'var(--text-secondary)',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
            }}>
              {stat.label}
            </span>
          </div>
          <div style={{
            fontSize: '32px',
            fontWeight: 700,
            fontFamily: "'JetBrains Mono', monospace",
            background: `linear-gradient(135deg, ${stat.color} 0%, ${stat.color}aa 100%)`,
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
          }}>
            {stat.value}
          </div>
        </div>
      ))}
    </div>
  );
}

export default StatsPanel;

