import { useState, useEffect } from 'react';
import { Client, Vault } from '../contracts/btc-vault/src/index';
import { CONTRACT_ID, RPC_URL, NETWORK_PASSPHRASE } from '../config';
import { 
  formatBTC, 
  formatDate, 
  isVaultLocked, 
  getTimeRemaining, 
  formatDuration,
  truncateAddress,
  calculateYield
} from '../utils/helpers';

interface VaultListProps {
  publicKey: string;
}

export default function VaultList({ publicKey }: VaultListProps) {
  const [vaults, setVaults] = useState<Array<{ id: number; vault: Vault }>>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchVaults();
  }, [publicKey]);

  const fetchVaults = async () => {
    try {
      const client = new Client({
        contractId: CONTRACT_ID,
        networkPassphrase: NETWORK_PASSPHRASE,
        rpcUrl: RPC_URL,
      });

      // Get user's vault IDs
      const vaultIdsTx = await client.get_user_vaults({ user: publicKey });
      const vaultIdsResult = await vaultIdsTx.simulate();
      const vaultIds = vaultIdsResult.result as any[];

      if (!vaultIds || vaultIds.length === 0) {
        setVaults([]);
        setLoading(false);
        return;
      }

      // Fetch each vault's details
      const vaultPromises = vaultIds.map(async (id: any) => {
        const vaultTx = await client.get_vault({ vault_id: BigInt(id.toString()) });
        const vaultResult = await vaultTx.simulate();
        return {
          id: Number(id),
          vault: vaultResult.result.unwrap() as Vault,
        };
      });

      const fetchedVaults = await Promise.all(vaultPromises);
      setVaults(fetchedVaults);
    } catch (err: any) {
      console.error('Error fetching vaults:', err);
      setError('Failed to load vaults');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="card">
        <h2>My Vaults</h2>
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <div className="loading"></div>
          <p style={{ color: 'var(--text-secondary)', marginTop: '16px' }}>
            Loading vaults...
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card">
        <h2>My Vaults</h2>
        <div className="alert alert-danger">{error}</div>
      </div>
    );
  }

  if (vaults.length === 0) {
    return (
      <div className="card">
        <h2>My Vaults</h2>
        <p style={{ color: 'var(--text-secondary)', textAlign: 'center', padding: '40px' }}>
          You don't have any vaults yet. Create your first vault above!
        </p>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>My Vaults ({vaults.length})</h2>
      <div className="grid grid-2" style={{ marginTop: '20px' }}>
        {vaults.map(({ id, vault }) => {
          const locked = isVaultLocked(Number(vault.created_at), Number(vault.lock_duration));
          const timeLeft = getTimeRemaining(Number(vault.created_at), Number(vault.lock_duration));
          const currentYield = calculateYield(
            Number(vault.amount),
            Math.floor(Date.now() / 1000) - Number(vault.created_at)
          );

          return (
            <div key={id} className="vault-card">
              <div className="vault-header">
                <span className="vault-id">Vault #{id}</span>
                <span className={`badge ${locked ? 'badge-warning' : 'badge-success'}`}>
                  {locked ? '🔒 Locked' : '🔓 Unlocked'}
                </span>
              </div>

              <div className="info-row">
                <span className="info-label">Amount:</span>
                <span className="info-value">{formatBTC(vault.amount.toString())}</span>
              </div>

              <div className="info-row">
                <span className="info-label">Created:</span>
                <span className="info-value">{formatDate(Number(vault.created_at))}</span>
              </div>

              <div className="info-row">
                <span className="info-label">Lock Duration:</span>
                <span className="info-value">{formatDuration(Number(vault.lock_duration))}</span>
              </div>

              {locked && (
                <div className="info-row">
                  <span className="info-label">Time Remaining:</span>
                  <span className="info-value" style={{ color: 'var(--warning-color)' }}>
                    {formatDuration(timeLeft)}
                  </span>
                </div>
              )}

              <div className="info-row">
                <span className="info-label">Current Yield:</span>
                <span className="info-value" style={{ color: 'var(--success-color)' }}>
                  {formatBTC(currentYield.toString())}
                </span>
              </div>

              <div className="info-row">
                <span className="info-label">BTC Address:</span>
                <span className="info-value">
                  <code style={{ fontSize: '12px' }}>
                    {truncateAddress(vault.btc_address, 10, 8)}
                  </code>
                </span>
              </div>

              {!locked && (
                <div style={{ marginTop: '16px' }}>
                  <button 
                    className="btn btn-success" 
                    style={{ width: '100%', fontSize: '14px' }}
                  >
                    Request Withdrawal
                  </button>
                </div>
              )}

              {currentYield > 0 && (
                <div style={{ marginTop: '8px' }}>
                  <button 
                    className="btn btn-secondary" 
                    style={{ width: '100%', fontSize: '14px' }}
                  >
                    Claim Yield
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
