import BigNumber from 'bignumber.js';
import { ONE_BTC, YIELD_RATE } from '../config';

/**
 * Convert satoshis to BTC
 */
export function satoshisToBTC(satoshis: number | string): string {
  return new BigNumber(satoshis).dividedBy(ONE_BTC).toFixed(8);
}

/**
 * Convert BTC to satoshis
 */
export function btcToSatoshis(btc: number | string): number {
  return new BigNumber(btc).multipliedBy(ONE_BTC).toNumber();
}

/**
 * Format BTC amount with proper decimals
 */
export function formatBTC(satoshis: number | string): string {
  const btc = satoshisToBTC(satoshis);
  return `${btc} BTC`;
}

/**
 * Format satoshis with commas
 */
export function formatSatoshis(satoshis: number | string): string {
  return new BigNumber(satoshis).toFormat(0);
}

/**
 * Calculate fee amount
 */
export function calculateFee(amount: number, feeRate: number): number {
  return new BigNumber(amount).multipliedBy(feeRate).dividedBy(10000).toNumber();
}

/**
 * Calculate yield for a given amount and time
 */
export function calculateYield(
  amount: number,
  timeHeld: number,
  yieldRate: number = YIELD_RATE
): number {
  // yield = (amount * yieldRate * timeHeld) / (10000 * 31536000)
  const SECONDS_IN_YEAR = 31536000;
  return new BigNumber(amount)
    .multipliedBy(yieldRate)
    .multipliedBy(timeHeld)
    .dividedBy(10000)
    .dividedBy(SECONDS_IN_YEAR)
    .toNumber();
}

/**
 * Convert seconds to human-readable format
 */
export function formatDuration(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`;
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`;
  } else {
    return `${minutes} minute${minutes > 1 ? 's' : ''}`;
  }
}

/**
 * Format timestamp to date string
 */
export function formatDate(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Format timestamp to relative time
 */
export function formatRelativeTime(timestamp: number): string {
  const now = Math.floor(Date.now() / 1000);
  const diff = timestamp - now;

  if (diff < 0) {
    return 'Expired';
  }

  return formatDuration(diff);
}

/**
 * Truncate address for display
 */
export function truncateAddress(address: string, start: number = 6, end: number = 4): string {
  if (address.length <= start + end) return address;
  return `${address.slice(0, start)}...${address.slice(-end)}`;
}

/**
 * Calculate progress percentage
 */
export function calculateProgress(current: number, total: number): number {
  if (total === 0) return 0;
  return Math.min(Math.round((current / total) * 100), 100);
}

/**
 * Check if vault is locked
 */
export function isVaultLocked(createdAt: number, lockDuration: number): boolean {
  const now = Math.floor(Date.now() / 1000);
  const unlockTime = createdAt + lockDuration;
  return now < unlockTime;
}

/**
 * Get unlock timestamp
 */
export function getUnlockTimestamp(createdAt: number, lockDuration: number): number {
  return createdAt + lockDuration;
}

/**
 * Get time remaining until unlock
 */
export function getTimeRemaining(createdAt: number, lockDuration: number): number {
  const now = Math.floor(Date.now() / 1000);
  const unlockTime = createdAt + lockDuration;
  return Math.max(0, unlockTime - now);
}

/**
 * Validate Bitcoin address
 */
export function isValidBTCAddress(address: string): boolean {
  // Basic validation for BTC addresses
  // Legacy addresses (1...) are 26-35 characters
  // SegWit addresses (3...) are 34 characters  
  // Bech32 addresses (bc1...) are 42-62 characters
  const legacyRegex = /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/;
  const segwitRegex = /^3[a-km-zA-HJ-NP-Z1-9]{33}$/;
  const bech32Regex = /^bc1[a-z0-9]{39,59}$/;

  return legacyRegex.test(address) || segwitRegex.test(address) || bech32Regex.test(address);
}

/**
 * Copy to clipboard
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (err) {
    console.error('Failed to copy:', err);
    return false;
  }
}

/**
 * Format percentage
 */
export function formatPercentage(basisPoints: number): string {
  return `${(basisPoints / 100).toFixed(2)}%`;
}

/**
 * Parse error message
 */
export function parseError(error: any): string {
  if (typeof error === 'string') return error;
  if (error?.message) return error.message;
  if (error?.toString) return error.toString();
  return 'An unknown error occurred';
}
