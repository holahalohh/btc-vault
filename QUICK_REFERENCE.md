# Bitcoin Vault Contract - Quick Reference Card

## 🎯 Contract ID
```
CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA
```

## 🔗 Links
- [Contract Explorer](https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA)
- [Events](https://stellar.expert/explorer/testnet/contract/CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA/events)

## ⚙️ Configuration
```
Min Lock:     1 day (86400 seconds)
Max Lock:     1 year (31536000 seconds)
Deposit Fee:  0.5% (50 basis points)
Withdrawal:   0.5% (50 basis points)
Yield Rate:   10% APY (1000 basis points)
Multi-sig:    2 of 3 approvals required
Admin:        alice (GAF2PGFZ6YYX2NNFHL7VO7KMXZXSKMQXTXTQHQWZ3LXKU65AOPNTCRYI)
```

## 👥 Authorized Signers
```
Bob:     GCQQOFCV7USOB2PAWSPPGWV4DBIMH3EKGRDGAPKGESHX4HVPSO7OC4LQ
Charlie: GBPTUJHVSQGOL3HAFXO2TXDPCSGPGQXJOUT2PWCSQHYCUBQXKAOQS6SB
David:   GBAYS3MNITYQG7PHKZVSUKGZSOFTU2TKGHZPJK7A4SMRB5TSIXARGCUU
```

## 🚀 Common Commands

### Create Vault (1 BTC, 30 days)
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source alice --network testnet -- create_vault --owner <ADDR> --amount 100000000 --lock_duration 2592000 --btc_address "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
```

### Check Vault
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source alice --network testnet -- get_vault --vault_id 0
```

### Claim Yield
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source <owner> --network testnet -- claim_yield --vault_id 0
```

### Request Withdrawal
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source <owner> --network testnet -- request_withdrawal --vault_id 0 --btc_address "bc1q..."
```

### Approve Withdrawal
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source bob --network testnet -- approve_withdrawal --signer <BOB_ADDR> --withdrawal_id 0
```

### Execute Withdrawal
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source <owner> --network testnet -- execute_withdrawal --withdrawal_id 0 --vault_id 0
```

### Get Stats
```bash
stellar contract invoke --id CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA --source alice --network testnet -- get_stats
```

## 📊 Current Status
```
Vaults:      1 active
Total BTC:   0.995 BTC locked
Yield Paid:  0 BTC
Status:      ✅ Active (not paused)
```

## 🧪 Test Vault #0
```
Owner:       Bob (GCQQOFCV...)
Amount:      99,500,000 sats (0.995 BTC)
Created:     Oct 16, 2025
Unlocks:     Nov 15, 2025 (30 days)
BTC Address: bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
```

## 🔢 Quick Conversions
```
1 BTC       = 100,000,000 satoshis
1 day       = 86,400 seconds
30 days     = 2,592,000 seconds
1 year      = 31,536,000 seconds

10% APY     = 1000 basis points
0.5% fee    = 50 basis points
```

## ⚠️ Remember
- Vaults are time-locked (can't withdraw early)
- Withdrawals need 2/3 approvals (Bob, Charlie, or David)
- Fees: 0.5% on deposit, 0.5% on withdrawal
- Yield: 10% APY calculated continuously

---
**Deployed**: Oct 16, 2025 | **Network**: Testnet | **Status**: ✅ Live
