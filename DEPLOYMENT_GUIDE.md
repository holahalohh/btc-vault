# Bitcoin Vault Contract - Deployment Guide

## ✅ Deployment Status: LIVE ON TESTNET

### 🌐 Contract Information

**Contract ID**: `CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA`

**Network**: Stellar Testnet  
**Deployed by**: alice  
**Deployment Date**: October 16, 2025  
**Wasm Hash**: `b553d88916d0c0a3dec62807aa5d6a361995516ce36b1aa2f28893bd78a4d405`

**Explorer Links**:
- [Contract on Stellar Expert](https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA)
- [Install Transaction](https://stellar.expert/explorer/testnet/tx/32dc85600f2621d9ea882808e400d5fdd00fbe4bec73c8b9d52ae3112b01f64b)
- [Deploy Transaction](https://stellar.expert/explorer/testnet/tx/bfca97be2e8d5c351c5c0c0e696a34af608b3f0b9370e5ffe53a9a1748729621)

### ⚙️ Current Configuration

```json
{
  "admin": "GAF2PGFZ6YYX2NNFHL7VO7KMXZXSKMQXTXTQHQWZ3LXKU65AOPNTCRYI",
  "min_lock_duration": 86400,        // 1 day in seconds
  "max_lock_duration": 31536000,     // 1 year in seconds
  "deposit_fee": 50,                 // 0.5% (50 basis points)
  "withdrawal_fee": 50,              // 0.5% (50 basis points)
  "yield_rate": 1000,                // 10% APY (1000 basis points)
  "required_approvals": 2,           // 2-of-3 multi-sig
  "signers": [
    "GCQQOFCV7USOB2PAWSPPGWV4DBIMH3EKGRDGAPKGESHX4HVPSO7OC4LQ",  // Bob
    "GBPTUJHVSQGOL3HAFXO2TXDPCSGPGQXJOUT2PWCSQHYCUBQXKAOQS6SB",  // Charlie
    "GBAYS3MNITYQG7PHKZVSUKGZSOFTU2TKGHZPJK7A4SMRB5TSIXARGCUU"   // David
  ],
  "paused": false
}
```

### 📊 Current Status

**Active Vaults**: 1  
**Total Locked**: 99,500,000 satoshis (0.995 BTC)  
**Total Yield Distributed**: 0 satoshis  
**Withdrawal Requests**: 0

### 🧪 Test Vault #0

```json
{
  "vault_id": 0,
  "owner": "GCQQOFCV7USOB2PAWSPPGWV4DBIMH3EKGRDGAPKGESHX4HVPSO7OC4LQ",  // Bob
  "amount": "99500000",              // 0.995 BTC (after 0.5% fee)
  "created_at": 1760626706,          // October 16, 2025
  "lock_duration": 2592000,          // 30 days
  "unlock_date": 1763218706,         // November 15, 2025
  "btc_address": "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
  "yield_amount": "0",
  "yield_claimed": false
}
```

## 🚀 Quick Start Guide

### Prerequisites
```bash
stellar --version  # Should be 23.1.3 or higher
```

### Environment Variables
```bash
export CONTRACT_ID="CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA"
export NETWORK="testnet"
```

## 📝 Usage Examples

### 1. Create a Vault

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source <YOUR_KEY> \
  --network $NETWORK \
  -- \
  create_vault \
  --owner <YOUR_ADDRESS> \
  --amount 100000000 \
  --lock_duration 2592000 \
  --btc_address "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
```

**Parameters**:
- `amount`: BTC amount in satoshis (100000000 = 1 BTC)
- `lock_duration`: Lock time in seconds (2592000 = 30 days)
- `btc_address`: Your Bitcoin withdrawal address

### 2. Check Your Vaults

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source <YOUR_KEY> \
  --network $NETWORK \
  -- \
  get_user_vaults \
  --user <YOUR_ADDRESS>
```

### 3. Get Vault Details

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  get_vault \
  --vault_id 0
```

### 4. Claim Yield

After some time has passed, claim accumulated yield:

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source <VAULT_OWNER_KEY> \
  --network $NETWORK \
  -- \
  claim_yield \
  --vault_id <VAULT_ID>
```

### 5. Request Withdrawal

After the lock period expires:

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source <VAULT_OWNER_KEY> \
  --network $NETWORK \
  -- \
  request_withdrawal \
  --vault_id <VAULT_ID> \
  --btc_address "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
```

### 6. Approve Withdrawal (Multi-sig)

**Signer 1 (Bob)**:
```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source bob \
  --network $NETWORK \
  -- \
  approve_withdrawal \
  --signer GCQQOFCV7USOB2PAWSPPGWV4DBIMH3EKGRDGAPKGESHX4HVPSO7OC4LQ \
  --withdrawal_id 0
```

**Signer 2 (Charlie)**:
```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source charlie \
  --network $NETWORK \
  -- \
  approve_withdrawal \
  --signer GBPTUJHVSQGOL3HAFXO2TXDPCSGPGQXJOUT2PWCSQHYCUBQXKAOQS6SB \
  --withdrawal_id 0
```

### 7. Execute Withdrawal

After sufficient approvals:

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source <VAULT_OWNER_KEY> \
  --network $NETWORK \
  -- \
  execute_withdrawal \
  --withdrawal_id 0 \
  --vault_id 0
```

### 8. Get Contract Statistics

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  get_stats
```

Returns: `[total_locked, total_yield, vault_count, withdrawal_count]`

### 9. Get Configuration

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  get_config
```

## 🔧 Admin Functions

### Pause Contract (Emergency)

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  pause
```

### Resume Contract

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  resume
```

### Update Yield Rate

```bash
stellar contract invoke \
  --id $CONTRACT_ID \
  --source alice \
  --network $NETWORK \
  -- \
  update_yield_rate \
  --new_rate 1500  # 15% APY
```

## 📊 Monitoring

### Check Contract Events

View all contract events on Stellar Expert:
```
https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA/events
```

### Event Types

The contract emits the following events:

1. **`init`** - Contract initialized
2. **`vault` + `create`** - New vault created
3. **`yield` + `claim`** - Yield claimed
4. **`withdraw` + `request`** - Withdrawal requested
5. **`withdraw` + `approve`** - Withdrawal approved
6. **`withdraw` + `execute`** - Withdrawal executed
7. **`pause`** - Contract paused
8. **`resume`** - Contract resumed
9. **`update` + `yield`** - Yield rate updated

## 🧮 Calculations

### Deposit Fee
```
net_amount = amount - (amount * deposit_fee / 10000)
Example: 100000000 - (100000000 * 50 / 10000) = 99,500,000 satoshis
```

### Withdrawal Fee
```
net_withdrawal = amount - (amount * withdrawal_fee / 10000)
```

### Yield Calculation
```
yield = (amount * yield_rate * time_locked) / (10000 * 31536000)

Example after 30 days:
yield = (99500000 * 1000 * 2592000) / (10000 * 31536000)
     = 8,184,931 satoshis (~0.082 BTC)
     ≈ 8.2% of locked amount
```

## 🔐 Security Notes

1. **Multi-sig**: All withdrawals require 2 out of 3 signer approvals
2. **Time-locks**: Vaults cannot be withdrawn before lock expires
3. **Admin Controls**: Only admin (alice) can pause/resume or update rates
4. **Fee Limits**: Fees capped at 10% (1000 basis points)
5. **Address Validation**: Bitcoin addresses validated for length (14-90 chars)

## 🎯 Use Cases on Testnet

### Testing Scenarios

1. **Basic Vault Flow**
   - Create vault → Wait → Claim yield → Request withdrawal → Approve → Execute

2. **Multi-sig Testing**
   - Test different approval combinations
   - Test rejection of insufficient approvals

3. **Emergency Scenarios**
   - Pause contract → Attempt operations → Resume

4. **Edge Cases**
   - Try early withdrawal (should fail)
   - Try invalid amounts (should fail)
   - Try invalid BTC addresses (should fail)

## 📚 Additional Resources

- **Contract Source**: `btc-vault/contracts/btc-vault/src/lib.rs`
- **Tests**: `btc-vault/contracts/btc-vault/src/test.rs`
- **Documentation**: `btc-vault/README.md`

## 🐛 Troubleshooting

### Common Issues

**"VaultLocked" error**:
- Your vault hasn't reached its unlock time yet
- Check `created_at + lock_duration` vs current timestamp

**"WithdrawalNotApproved" error**:
- Need more approvals (requires 2 out of 3)
- Get bob or charlie or david to approve

**"Unauthorized" error**:
- Using wrong key for the operation
- Check that vault owner matches your key

**"InvalidAmount" error**:
- Amount must be positive and non-zero

**"ContractPaused" error**:
- Contract is paused by admin
- Wait for admin to resume

## 📞 Support

For issues or questions:
1. Check the contract source code
2. Review test cases for examples
3. Check Stellar Expert for transaction details
4. Review event logs for detailed error information

---

## 🎉 Success!

Your Bitcoin Vault contract is now live on Stellar testnet and ready for testing!

**Next Steps**:
1. Create more test vaults with different parameters
2. Test the complete withdrawal flow
3. Test multi-sig approval process
4. Monitor yield accumulation
5. Test admin functions (pause/resume/update rate)

**Happy Testing! 🚀**
