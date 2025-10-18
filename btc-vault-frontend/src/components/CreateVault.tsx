import { useState } from 'react';
import { Client } from '../contracts/btc-vault/src/index';
import { signTransaction } from '../utils/wallet';
import { CONTRACT_ID, RPC_URL, NETWORK_PASSPHRASE, DURATION_PRESETS, AMOUNT_PRESETS } from '../config';
import { isValidBTCAddress, calculateFee, formatBTC, parseError } from '../utils/helpers';

interface CreateVaultProps {
  publicKey: string;
}

export default function CreateVault({ publicKey }: CreateVaultProps) {
  const [amount, setAmount] = useState('');
  const [duration, setDuration] = useState('');
  const [btcAddress, setBtcAddress] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleCreateVault = async () => {
    setError('');
    setSuccess('');

    // Validation
    if (!amount || !duration || !btcAddress) {
      setError('All fields are required');
      return;
    }

    const amountNum = parseInt(amount);
    const durationNum = parseInt(duration);

    if (isNaN(amountNum) || amountNum <= 0) {
      setError('Invalid amount');
      return;
    }

    if (isNaN(durationNum) || durationNum < 86400) {
      setError('Duration must be at least 1 day (86400 seconds)');
      return;
    }

    if (!isValidBTCAddress(btcAddress)) {
      setError('Invalid Bitcoin address');
      return;
    }

    setLoading(true);

    try {
      // Initialize contract client
      const client = new Client({
        contractId: CONTRACT_ID,
        networkPassphrase: NETWORK_PASSPHRASE,
        rpcUrl: RPC_URL,
      });

      // Set the public key and sign transaction function
      client.options.publicKey = publicKey;
      client.options.signTransaction = signTransaction;

      // Calculate fee
      const fee = calculateFee(amountNum, 50); // 50 basis points = 0.5%
      const netAmount = amountNum - fee;

      console.log('Creating vault:', {
        owner: publicKey,
        amount: BigInt(amountNum),
        lock_duration: BigInt(durationNum),
        btc_address: btcAddress,
        fee,
        netAmount,
      });

      // Create vault transaction
      const tx = await client.create_vault({
        owner: publicKey,
        amount: BigInt(amountNum),
        lock_duration: BigInt(durationNum),
        btc_address: btcAddress,
      });

      // Sign and send
      const result = await tx.signAndSend();

      console.log('Vault created!', result);

      setSuccess(`Vault created successfully! Net amount: ${formatBTC(netAmount)}`);
      
      // Reset form
      setAmount('');
      setDuration('');
      setBtcAddress('');

      // Reload page after 2 seconds to refresh vault list
      setTimeout(() => {
        window.location.reload();
      }, 2000);

    } catch (err: any) {
      console.error('Error creating vault:', err);
      setError(parseError(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <h2>Create New Vault</h2>

      {error && (
        <div className="alert alert-danger">
          ❌ {error}
        </div>
      )}

      {success && (
        <div className="alert alert-success">
          ✅ {success}
        </div>
      )}

      <div className="input-group">
        <label>Amount (satoshis)</label>
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="100000000 (1 BTC)"
          disabled={loading}
        />
        <div style={{ display: 'flex', gap: '8px', marginTop: '8px', flexWrap: 'wrap' }}>
          {AMOUNT_PRESETS.map((preset) => (
            <button
              key={preset.value}
              onClick={() => setAmount(preset.value.toString())}
              className="btn btn-outline"
              style={{ fontSize: '12px', padding: '6px 12px' }}
              disabled={loading}
            >
              {preset.label}
            </button>
          ))}
        </div>
      </div>

      <div className="input-group">
        <label>Lock Duration (seconds)</label>
        <input
          type="number"
          value={duration}
          onChange={(e) => setDuration(e.target.value)}
          placeholder="2592000 (30 days)"
          disabled={loading}
        />
        <div style={{ display: 'flex', gap: '8px', marginTop: '8px', flexWrap: 'wrap' }}>
          {DURATION_PRESETS.map((preset) => (
            <button
              key={preset.value}
              onClick={() => setDuration(preset.value.toString())}
              className="btn btn-outline"
              style={{ fontSize: '12px', padding: '6px 12px' }}
              disabled={loading}
            >
              {preset.label}
            </button>
          ))}
        </div>
      </div>

      <div className="input-group">
        <label>Bitcoin Address</label>
        <input
          type="text"
          value={btcAddress}
          onChange={(e) => setBtcAddress(e.target.value)}
          placeholder="bc1q..."
          disabled={loading}
        />
      </div>

      {amount && (
        <div className="alert alert-info" style={{ marginBottom: '20px' }}>
          <div className="info-row">
            <span className="info-label">Deposit Amount:</span>
            <span className="info-value">{formatBTC(amount)}</span>
          </div>
          <div className="info-row">
            <span className="info-label">Deposit Fee (0.5%):</span>
            <span className="info-value">{formatBTC(calculateFee(parseInt(amount), 50))}</span>
          </div>
          <div className="info-row">
            <span className="info-label">Net Locked:</span>
            <span className="info-value" style={{ color: 'var(--primary-color)' }}>
              {formatBTC(parseInt(amount) - calculateFee(parseInt(amount), 50))}
            </span>
          </div>
        </div>
      )}

      <button 
        className="btn btn-primary" 
        onClick={handleCreateVault}
        disabled={loading}
        style={{ width: '100%' }}
      >
        {loading ? (
          <>
            <span className="loading"></span>
            Creating Vault...
          </>
        ) : (
          'Create Vault'
        )}
      </button>
    </div>
  );
}
