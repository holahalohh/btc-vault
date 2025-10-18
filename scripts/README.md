# Bitcoin Vault Scripts

A complete set of bash scripts to interact with the Bitcoin Vault smart contract on Stellar testnet.

## Quick Start

### Option 1: Interactive Menu (Recommended)
```bash
./menu.sh
```

### Option 2: Individual Scripts
All scripts support `--help` flag for detailed usage information.

## Available Scripts

### 📊 Query Operations

#### `get-stats.sh`
View contract statistics including total locked, withdrawn, yield paid, and active vaults.
```bash
./get-stats.sh
```

#### `get-vault.sh`
Get detailed information about a specific vault.
```bash
./get-vault.sh --vault-id 0
```

#### `list-user-vaults.sh`
List all vaults for a specific user with summaries.
```bash
./list-user-vaults.sh --user bob
./list-user-vaults.sh --user alice
```

### 💰 Vault Operations

#### `create-vault.sh`
Create a new vault with time-locked BTC.
```bash
./create-vault.sh --owner bob --amount 100000000 --duration 2592000 --btc-address bc1qxyz...
```

**Parameters:**
- `--owner`: Vault owner (alice, bob, charlie, or david)
- `--amount`: Amount in satoshis (100000000 = 1 BTC)
- `--duration`: Lock duration in seconds (2592000 = 30 days)
- `--btc-address`: Bitcoin address for withdrawals

**Common Amounts:**
- 0.1 BTC = 10000000 satoshis
- 0.5 BTC = 50000000 satoshis
- 1 BTC = 100000000 satoshis
- 5 BTC = 500000000 satoshis

**Common Durations:**
- 1 day = 86400 seconds
- 1 week = 604800 seconds
- 30 days = 2592000 seconds
- 90 days = 7776000 seconds
- 1 year = 31536000 seconds

#### `claim-yield.sh`
Claim accumulated yield from a vault.
```bash
./claim-yield.sh --vault-id 0
./claim-yield.sh --vault-id 0 --owner bob
```

### 🔓 Withdrawal Operations

The withdrawal process requires 3 steps:

#### Step 1: `request-withdrawal.sh`
Request a withdrawal from an unlocked vault.
```bash
./request-withdrawal.sh --vault-id 0
./request-withdrawal.sh --vault-id 0 --btc-address bc1qxyz...
```

#### Step 2: `approve-withdrawal.sh`
Multi-sig signers approve the withdrawal (need 2 out of 3).
```bash
./approve-withdrawal.sh --withdrawal-id 0 --signer bob
./approve-withdrawal.sh --withdrawal-id 0 --signer charlie
```

#### Step 3: `execute-withdrawal.sh`
Execute the approved withdrawal and close the vault.
```bash
./execute-withdrawal.sh --withdrawal-id 0 --vault-id 0
```

### ⚙️ Admin Operations

**Note:** These operations require admin privileges (alice account).

#### `pause.sh`
Pause the contract (emergency stop).
```bash
./pause.sh
```

#### `resume.sh`
Resume contract operations.
```bash
./resume.sh
```

#### `update-yield-rate.sh`
Update the yield rate for all vaults.
```bash
./update-yield-rate.sh --rate 1000   # 10% APY
./update-yield-rate.sh --rate 500    # 5% APY
./update-yield-rate.sh --rate 1500   # 15% APY
```

**Note:** Rate is in basis points (1% = 100 basis points)

## Configuration

All scripts use centralized configuration from `config.sh`:

- **Contract ID**: Set automatically from deployment
- **Network**: Stellar Testnet
- **Accounts**:
  - Admin: alice
  - Signers: bob, charlie, david

To modify configuration, edit `config.sh`.

## Common Workflows

### Create and Monitor a Vault

```bash
# 1. Create vault (1 BTC for 30 days)
./create-vault.sh --owner bob --amount 100000000 --duration 2592000 --btc-address bc1qxyz...

# 2. View vault details
./get-vault.sh --vault-id 0

# 3. Claim yield periodically
./claim-yield.sh --vault-id 0

# 4. After lock expires, request withdrawal
./request-withdrawal.sh --vault-id 0

# 5. Get approvals (need 2 out of 3)
./approve-withdrawal.sh --withdrawal-id 0 --signer bob
./approve-withdrawal.sh --withdrawal-id 0 --signer charlie

# 6. Execute withdrawal
./execute-withdrawal.sh --withdrawal-id 0 --vault-id 0
```

### Monitor Contract Health

```bash
# View overall statistics
./get-stats.sh

# List all vaults for a user
./list-user-vaults.sh --user bob

# Check specific vault
./get-vault.sh --vault-id 0
```

### Admin Operations

```bash
# Emergency pause
./pause.sh

# Resume operations
./resume.sh

# Adjust yield rate
./update-yield-rate.sh --rate 1200  # Change to 12% APY

# View updated config
./get-stats.sh
```

## Script Features

All scripts include:

- ✅ **Help text**: Run any script with `--help`
- ✅ **Input validation**: Checks for valid parameters
- ✅ **Confirmation prompts**: Prevents accidental operations
- ✅ **Formatted output**: Color-coded and easy to read
- ✅ **Error handling**: Clear error messages
- ✅ **Status calculations**: Shows lock status, time remaining, yield
- ✅ **Next action suggestions**: Guides you through workflows

## Troubleshooting

### Script Not Found
Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
```

### Account Not Found
Ensure you have the correct account names (alice, bob, charlie, david) and they are configured in `config.sh`.

### Vault Locked
Vaults must be unlocked before withdrawal. Check unlock time with:
```bash
./get-vault.sh --vault-id <ID>
```

### Insufficient Approvals
Withdrawals need 2 out of 3 multi-sig approvals. Check approval count:
```bash
# Approve with different signers until you have 2
./approve-withdrawal.sh --withdrawal-id <ID> --signer bob
./approve-withdrawal.sh --withdrawal-id <ID> --signer charlie
```

### Contract Paused
If the contract is paused, only admin can resume:
```bash
./resume.sh
```

## Support

For more information:
- View contract on [Stellar Expert](https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA)
- Check `DEPLOYMENT_GUIDE.md` for detailed usage
- Check `QUICK_REFERENCE.md` for command reference
- Check `PROJECT_COMPLETE.md` for full project documentation

## License

MIT
