import { connectWallet, disconnectWallet } from '../utils/wallet';
import { truncateAddress } from '../utils/helpers';

interface ConnectWalletProps {
  publicKey: string | null;
  onConnect: () => Promise<void> | void;
  onDisconnect: () => void;
}

export default function ConnectWallet({ publicKey, onConnect, onDisconnect }: ConnectWalletProps) {
  const handleConnect = async () => {
    await connectWallet(onConnect);
  };

  const handleDisconnect = async () => {
    await disconnectWallet(onDisconnect);
  };

  return (
    <div className="card" style={{ textAlign: 'center' }}>
      {publicKey ? (
        <div>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '12px' }}>
            Connected as
          </p>
          <code style={{ fontSize: '16px', padding: '8px 16px' }}>
            {truncateAddress(publicKey, 8, 8)}
          </code>
          <br />
          <button
            onClick={handleDisconnect}
            className="btn btn-outline"
            style={{ marginTop: '16px' }}
          >
            Disconnect
          </button>
        </div>
      ) : (
        <div>
          <h2>Connect Your Wallet</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '20px' }}>
            Connect Freighter wallet to interact with the contract
          </p>
          <button onClick={handleConnect} className="btn btn-primary">
            Connect Wallet
          </button>
        </div>
      )}
    </div>
  );
}
