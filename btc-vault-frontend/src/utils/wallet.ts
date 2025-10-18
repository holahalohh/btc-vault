import {
  StellarWalletsKit,
  WalletNetwork,
  allowAllModules,
  FREIGHTER_ID,
} from '@creit.tech/stellar-wallets-kit';
import { NETWORK_PASSPHRASE } from '../config';

const SELECTED_WALLET_ID = 'selectedWalletId';

/**
 * Get selected wallet ID from localStorage
 */
function getSelectedWalletId(): string | null {
  return localStorage.getItem(SELECTED_WALLET_ID);
}

/**
 * Initialize Stellar Wallets Kit
 */
const kit = new StellarWalletsKit({
  network: NETWORK_PASSPHRASE as WalletNetwork,
  selectedWalletId: getSelectedWalletId() ?? FREIGHTER_ID,
  modules: allowAllModules(),
});

/**
 * Get public key from connected wallet
 */
export async function getPublicKey(): Promise<string | null> {
  try {
    if (!getSelectedWalletId()) return null;
    const { address } = await kit.getAddress();
    return address;
  } catch (error) {
    console.error('Error getting public key:', error);
    return null;
  }
}

/**
 * Set wallet and save to localStorage
 */
export async function setWallet(walletId: string): Promise<void> {
  localStorage.setItem(SELECTED_WALLET_ID, walletId);
  kit.setWallet(walletId);
}

/**
 * Connect wallet with callback
 */
export async function connectWallet(
  callback?: () => Promise<void> | void
): Promise<void> {
  await kit.openModal({
    onWalletSelected: async (option) => {
      try {
        await setWallet(option.id);
        if (callback) await callback();
      } catch (e) {
        console.error('Error selecting wallet:', e);
      }
    },
  });
}

/**
 * Disconnect wallet
 */
export async function disconnectWallet(
  callback?: () => Promise<void> | void
): Promise<void> {
  localStorage.removeItem(SELECTED_WALLET_ID);
  kit.disconnect();
  if (callback) await callback();
}

/**
 * Sign transaction with connected wallet
 */
export async function signTransaction(
  xdr: string,
  opts?: {
    networkPassphrase?: string;
    address?: string;
  }
): Promise<{ signedTxXdr: string; signerAddress?: string }> {
  const result = await kit.signTransaction(xdr, opts);
  return {
    signedTxXdr: result.signedTxXdr,
    signerAddress: result.signerAddress,
  };
}

/**
 * Check if wallet is connected
 */
export async function isWalletConnected(): Promise<boolean> {
  const publicKey = await getPublicKey();
  return publicKey !== null;
}

export { kit };
