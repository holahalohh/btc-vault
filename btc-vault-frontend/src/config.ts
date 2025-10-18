export const CONTRACT_ID = 'CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA';
export const NETWORK_PASSPHRASE = 'Test SDF Network ; September 2015';
export const RPC_URL = 'https://soroban-testnet.stellar.org';
export const NETWORK = 'testnet';

// Time constants (in seconds)
export const ONE_DAY = 86400;
export const ONE_WEEK = 604800;
export const ONE_MONTH = 2592000;
export const THREE_MONTHS = 7776000;
export const SIX_MONTHS = 15552000;
export const ONE_YEAR = 31536000;

// BTC amount constants (in satoshis)
export const SATOSHI = 1;
export const ONE_BTC = 100000000;
export const HALF_BTC = 50000000;
export const QUARTER_BTC = 25000000;
export const TENTH_BTC = 10000000;

// Fee rates (in basis points)
export const DEPOSIT_FEE = 50; // 0.5%
export const WITHDRAWAL_FEE = 50; // 0.5%
export const YIELD_RATE = 1000; // 10% APY

// Multi-sig configuration
export const REQUIRED_APPROVALS = 2;
export const TOTAL_SIGNERS = 3;

// Duration presets for UI
export const DURATION_PRESETS = [
  { label: '1 Day', value: ONE_DAY },
  { label: '1 Week', value: ONE_WEEK },
  { label: '1 Month', value: ONE_MONTH },
  { label: '3 Months', value: THREE_MONTHS },
  { label: '6 Months', value: SIX_MONTHS },
  { label: '1 Year', value: ONE_YEAR },
];

// Amount presets for UI
export const AMOUNT_PRESETS = [
  { label: '0.1 BTC', value: TENTH_BTC },
  { label: '0.25 BTC', value: QUARTER_BTC },
  { label: '0.5 BTC', value: HALF_BTC },
  { label: '1 BTC', value: ONE_BTC },
];
