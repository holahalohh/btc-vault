import { useState, useEffect } from 'react';
import { Client } from '../contracts/btc-vault/src/index';
import { CONTRACT_ID, RPC_URL, NETWORK_PASSPHRASE } from '../config';
import { formatBTC } from '../utils/helpers';

interface StatsProps {
  publicKey: string;
}

export default function Stats({ publicKey }: StatsProps) {
  const [stats, setStats] = useState<{
    totalLocked: string;
    totalWithdrawn: string;
    totalVaults: number;
    activeVaults: number;
  } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const client = new Client({
        contractId: CONTRACT_ID,
        networkPassphrase: NETWORK_PASSPHRASE,
        rpcUrl: RPC_URL,
      });

      const tx = await client.get_stats();
      const result = await tx.simulate();

      // Result is a tuple: [total_locked, total_withdrawn, total_vaults, active_vaults]
      const [totalLocked, totalWithdrawn, totalVaults, activeVaults] = result.result as any;

      setStats({
        totalLocked: totalLocked.toString(),
        totalWithdrawn: totalWithdrawn.toString(),
        totalVaults: Number(totalVaults),
        activeVaults: Number(activeVaults),
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="card">
        <h2>Contract Statistics</h2>
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <div className="loading"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>Contract Statistics</h2>
      <div className="grid grid-3">
        <div className="stat-card">
          <div className="stat-label">Total Locked</div>
          <div className="stat-value">
            {stats ? formatBTC(stats.totalLocked) : '0 BTC'}
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Active Vaults</div>
          <div className="stat-value">{stats?.activeVaults || 0}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Total Withdrawn</div>
          <div className="stat-value">
            {stats ? formatBTC(stats.totalWithdrawn) : '0 BTC'}
          </div>
        </div>
      </div>
    </div>
  );
}
