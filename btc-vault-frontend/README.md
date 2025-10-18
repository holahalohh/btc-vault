# Bitcoin Vault Frontend

Professional React-based DApp frontend for the Bitcoin Vault smart contract on Stellar testnet.

## Features

- 🔐 Freighter wallet integration
- 💰 Create time-locked BTC vaults
- 📈 Claim yield rewards
- 🔓 Multi-sig withdrawal flow
- 📊 Real-time contract statistics
- 🎨 Modern, responsive UI
- ⚡ Built with React + TypeScript + Vite

## Getting Started

### Prerequisites

- Node.js v18.14.1 or greater
- Freighter wallet extension installed
- Testnet account with XLM

### Installation

```bash
npm install
```

### Generate Contract Bindings

```bash
npm run bindings
```

### Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

## Contract Information

- **Contract ID**: `CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA`
- **Network**: Stellar Testnet
- **Functions**: 15 exported functions
- **Features**: Time-locks, multi-sig, yield generation

## Project Structure

```
btc-vault-frontend/
├── src/
│   ├── components/          # React components
│   │   ├── ConnectWallet.tsx
│   │   ├── CreateVault.tsx
│   │   ├── VaultList.tsx
│   │   ├── VaultDetails.tsx
│   │   ├── ClaimYield.tsx
│   │   ├── WithdrawalFlow.tsx
│   │   └── Stats.tsx
│   ├── contracts/           # Generated contract bindings
│   ├── hooks/               # Custom React hooks
│   ├── utils/               # Utility functions
│   ├── styles/              # CSS styles
│   ├── App.tsx              # Main app component
│   └── main.tsx             # Entry point
├── public/                  # Static assets
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## Usage

### Connect Wallet

1. Click "Connect Wallet" button
2. Select Freighter from the modal
3. Approve the connection

### Create a Vault

1. Enter BTC amount (in satoshis)
2. Set lock duration (in days)
3. Provide Bitcoin withdrawal address
4. Confirm transaction in Freighter

### Claim Yield

1. Navigate to your vault
2. Click "Claim Yield"
3. Confirm transaction

### Withdraw Funds

1. Wait for lock period to expire
2. Request withdrawal
3. Get 2 of 3 multi-sig approvals
4. Execute withdrawal

## Technologies

- **React** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Stellar SDK** - Blockchain interaction
- **StellarWalletsKit** - Wallet integration
- **BigNumber.js** - Precise number handling

## License

MIT
