#!/bin/bash
# Script to get contract statistics

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ""
log_info "Fetching contract statistics..."
echo ""

# Get stats
STATS=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_stats 2>&1)

if echo "$STATS" | grep -q "error"; then
    log_error "Failed to fetch stats"
    echo "$STATS"
    exit 1
fi

# Parse stats
TOTAL_LOCKED=$(echo "$STATS" | grep -o '"total_locked":"[0-9]*"' | grep -o '[0-9]*')
TOTAL_WITHDRAWN=$(echo "$STATS" | grep -o '"total_withdrawn":"[0-9]*"' | grep -o '[0-9]*')
TOTAL_YIELD=$(echo "$STATS" | grep -o '"total_yield_paid":"[0-9]*"' | grep -o '[0-9]*')
ACTIVE_VAULTS=$(echo "$STATS" | grep -o '"active_vaults":[0-9]*' | grep -o '[0-9]*')
TOTAL_VAULTS=$(echo "$STATS" | grep -o '"total_vaults":[0-9]*' | grep -o '[0-9]*')

# Convert to BTC
TOTAL_LOCKED_BTC=$(echo "scale=8; $TOTAL_LOCKED / 100000000" | bc)
TOTAL_WITHDRAWN_BTC=$(echo "scale=8; $TOTAL_WITHDRAWN / 100000000" | bc)
TOTAL_YIELD_BTC=$(echo "scale=8; $TOTAL_YIELD / 100000000" | bc)

# Calculate closed vaults
CLOSED_VAULTS=$((TOTAL_VAULTS - ACTIVE_VAULTS))

# Get config for additional info
CONFIG=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_config 2>&1)

YIELD_RATE=$(echo "$CONFIG" | grep -o '"yield_rate":[0-9]*' | grep -o '[0-9]*')
DEPOSIT_FEE=$(echo "$CONFIG" | grep -o '"deposit_fee":[0-9]*' | grep -o '[0-9]*')
WITHDRAWAL_FEE=$(echo "$CONFIG" | grep -o '"withdrawal_fee":[0-9]*' | grep -o '[0-9]*')
IS_PAUSED=$(echo "$CONFIG" | grep -o '"paused":[a-z]*' | grep -o '[a-z]*')

YIELD_APY=$(echo "scale=2; $YIELD_RATE / 100" | bc)
DEPOSIT_FEE_PCT=$(echo "scale=2; $DEPOSIT_FEE / 100" | bc)
WITHDRAWAL_FEE_PCT=$(echo "scale=2; $WITHDRAWAL_FEE / 100" | bc)

# Display stats
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "           🪙  BITCOIN VAULT CONTRACT STATS  🪙"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 VAULT STATISTICS"
echo "───────────────────────────────────────────────────────"
echo "Total Vaults:        $TOTAL_VAULTS"
echo "Active Vaults:       $ACTIVE_VAULTS 🔓"
echo "Closed Vaults:       $CLOSED_VAULTS 🔒"
echo ""
echo "💰 FINANCIAL STATISTICS"
echo "───────────────────────────────────────────────────────"
echo "Total Locked:        $TOTAL_LOCKED satoshis"
echo "                     $TOTAL_LOCKED_BTC BTC"
echo ""
echo "Total Withdrawn:     $TOTAL_WITHDRAWN satoshis"
echo "                     $TOTAL_WITHDRAWN_BTC BTC"
echo ""
echo "Total Yield Paid:    $TOTAL_YIELD satoshis"
echo "                     $TOTAL_YIELD_BTC BTC"
echo ""
echo "⚙️  CONTRACT CONFIGURATION"
echo "───────────────────────────────────────────────────────"
echo "Yield Rate:          $YIELD_APY% APY"
echo "Deposit Fee:         $DEPOSIT_FEE_PCT%"
echo "Withdrawal Fee:      $WITHDRAWAL_FEE_PCT%"
echo "Contract Status:     $([ "$IS_PAUSED" == "true" ] && echo "⏸️  PAUSED" || echo "✅ ACTIVE")"
echo ""
echo "🌐 CONTRACT INFO"
echo "───────────────────────────────────────────────────────"
echo "Contract ID:         $CONTRACT_ID"
echo "Network:             $NETWORK"
echo "Explorer:            https://stellar.expert/explorer/$NETWORK/contract/$CONTRACT_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Additional insights
if [ "$ACTIVE_VAULTS" -gt 0 ]; then
    AVG_LOCKED=$(echo "scale=8; $TOTAL_LOCKED / $ACTIVE_VAULTS" | bc)
    AVG_LOCKED_BTC=$(echo "scale=8; $AVG_LOCKED / 100000000" | bc)
    echo "📈 INSIGHTS"
    echo "───────────────────────────────────────────────────────"
    echo "Average per Active Vault: $AVG_LOCKED_BTC BTC"
    
    if [ "$TOTAL_YIELD" -gt 0 ] && [ "$TOTAL_LOCKED" -gt 0 ]; then
        EFFECTIVE_YIELD=$(echo "scale=2; ($TOTAL_YIELD * 100) / $TOTAL_LOCKED" | bc)
        echo "Effective Yield Paid:     $EFFECTIVE_YIELD%"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

log_info "Quick actions:"
echo "  View a vault:     ./scripts/get-vault.sh --vault-id <ID>"
echo "  Create vault:     ./scripts/create-vault.sh --help"
echo "  List user vaults: ./scripts/list-user-vaults.sh --user <NAME>"
echo ""
