import { useState, useEffect } from 'react';
import Header from './components/Header';
import ConnectWallet from './components/ConnectWallet';
import Stats from './components/Stats';
import CreateVault from './components/CreateVault';
import VaultList from './components/VaultList';
import { getPublicKey } from './utils/wallet';

function App() {
  const [publicKey, setPublicKey] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkWalletConnection();
  }, []);

  const checkWalletConnection = async () => {
    try {
      const key = await getPublicKey();
      setPublicKey(key);
    } catch (error) {
      console.error('Error checking wallet connection:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleWalletConnect = async () => {
    const key = await getPublicKey();
    setPublicKey(key);
  };

  const handleWalletDisconnect = () => {
    setPublicKey(null);
  };

  if (isLoading) {
    return (
      <div className="container" style={{ textAlign: 'center', paddingTop: '100px' }}>
        <div className="loading" style={{ width: '60px', height: '60px', margin: '0 auto' }}></div>
        <p style={{ marginTop: '20px', color: 'var(--text-secondary)' }}>Loading...</p>
      </div>
    );
  }

  return (
    <div className="app">
      <Header />
      
      <div className="container">
        <div className="card" style={{ textAlign: 'center', marginBottom: '40px' }}>
          <h1 style={{ fontSize: '48px', marginBottom: '16px' }}>
            <span style={{ color: 'var(--primary-color)' }}>₿</span> Bitcoin Vault
          </h1>
          <p style={{ fontSize: '18px', color: 'var(--text-secondary)' }}>
            Time-locked BTC vaults with multi-sig withdrawals on Stellar
          </p>
        </div>

        <ConnectWallet
          publicKey={publicKey}
          onConnect={handleWalletConnect}
          onDisconnect={handleWalletDisconnect}
        />

        {publicKey ? (
          <>
            <Stats publicKey={publicKey} />
            <CreateVault publicKey={publicKey} />
            <VaultList publicKey={publicKey} />
          </>
        ) : (
          <div className="card" style={{ textAlign: 'center' }}>
            <h2>Welcome to Bitcoin Vault</h2>
            <p style={{ color: 'var(--text-secondary)', marginBottom: '24px' }}>
              Connect your Freighter wallet to get started
            </p>
            <div style={{ padding: '40px', backgroundColor: 'var(--dark-bg)', borderRadius: '8px' }}>
              <h3 style={{ marginBottom: '16px' }}>Features</h3>
              <div className="grid grid-2" style={{ textAlign: 'left' }}>
                <div>
                  <h4 style={{ color: 'var(--primary-color)', marginBottom: '8px' }}>🔒 Time-Locked Vaults</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                    Lock your BTC for a custom duration (1 day to 1 year)
                  </p>
                </div>
                <div>
                  <h4 style={{ color: 'var(--primary-color)', marginBottom: '8px' }}>📈 Earn Yield</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                    Earn 10% APY on your locked BTC, claimable anytime
                  </p>
                </div>
                <div>
                  <h4 style={{ color: 'var(--primary-color)', marginBottom: '8px' }}>🔐 Multi-Sig Security</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                    Withdrawals require 2 out of 3 signer approvals
                  </p>
                </div>
                <div>
                  <h4 style={{ color: 'var(--primary-color)', marginBottom: '8px' }}>⚡ On Stellar</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                    Fast, low-cost transactions on Stellar testnet
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        <footer style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
          <p>
            Bitcoin Vault on Stellar Testnet •{' '}
            <a
              href="https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: 'var(--primary-color)' }}
            >
              View Contract
            </a>
          </p>
        </footer>
      </div>
    </div>
  );
}

export default App;
