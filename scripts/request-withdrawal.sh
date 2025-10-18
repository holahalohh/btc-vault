#!/bin/bash
# Script to request a withdrawal from a vault

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
VAULT_ID=""
OWNER_KEY=""
BTC_ADDRESS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --vault-id)
            VAULT_ID="$2"
            shift 2
            ;;
        --owner)
            OWNER_KEY="$2"
            shift 2
            ;;
        --btc-address)
            BTC_ADDRESS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --vault-id VAULT_ID [OPTIONS]"
            echo ""
            echo "Request a withdrawal from a vault (requires vault to be unlocked)"
            echo ""
            echo "Options:"
            echo "  --vault-id ID        Vault ID to withdraw from"
            echo "  --owner KEY          Owner's key name (auto-detected if not provided)"
            echo "  --btc-address ADDR   Bitcoin address (uses vault's address if not provided)"
            echo "  --help               Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --vault-id 0"
            echo "  $0 --vault-id 0 --btc-address bc1qxyz..."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$VAULT_ID" ]; then
    log_error "Vault ID is required"
    echo "Usage: $0 --vault-id VAULT_ID [OPTIONS]"
    exit 1
fi

# Get vault details
log_info "Fetching vault #$VAULT_ID details..."
VAULT_DATA=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_vault \
  --vault_id "$VAULT_ID" 2>&1)

if echo "$VAULT_DATA" | grep -q "VaultNotFound"; then
    log_error "Vault #$VAULT_ID not found"
    exit 1
fi

AMOUNT=$(echo "$VAULT_DATA" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
OWNER_ADDRESS=$(echo "$VAULT_DATA" | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)
CREATED_AT=$(echo "$VAULT_DATA" | grep -o '"created_at":[0-9]*' | grep -o '[0-9]*')
LOCK_DURATION=$(echo "$VAULT_DATA" | grep -o '"lock_duration":[0-9]*' | grep -o '[0-9]*')
VAULT_BTC_ADDRESS=$(echo "$VAULT_DATA" | grep -o '"btc_address":"[^"]*"' | cut -d'"' -f4)
YIELD_AMOUNT=$(echo "$VAULT_DATA" | grep -o '"yield_amount":"[0-9]*"' | grep -o '[0-9]*')

# Use vault's BTC address if not provided
if [ -z "$BTC_ADDRESS" ]; then
    BTC_ADDRESS="$VAULT_BTC_ADDRESS"
fi

# Determine owner key if not provided
if [ -z "$OWNER_KEY" ]; then
    if [ "$OWNER_ADDRESS" == "$ADMIN_ADDRESS" ]; then
        OWNER_KEY="$ADMIN_KEY"
    elif [ "$OWNER_ADDRESS" == "$SIGNER1_ADDRESS" ]; then
        OWNER_KEY="$SIGNER1_KEY"
    elif [ "$OWNER_ADDRESS" == "$SIGNER2_ADDRESS" ]; then
        OWNER_KEY="$SIGNER2_KEY"
    elif [ "$OWNER_ADDRESS" == "$SIGNER3_ADDRESS" ]; then
        OWNER_KEY="$SIGNER3_KEY"
    else
        log_error "Could not determine owner key. Please specify with --owner"
        exit 1
    fi
fi

# Check if vault is unlocked
UNLOCK_TIME=$((CREATED_AT + LOCK_DURATION))
CURRENT_TIME=$(date +%s)

if [ "$CURRENT_TIME" -lt "$UNLOCK_TIME" ]; then
    TIME_LEFT=$((UNLOCK_TIME - CURRENT_TIME))
    DAYS_LEFT=$(echo "scale=1; $TIME_LEFT / 86400" | bc)
    log_error "Vault is still locked!"
    echo "Unlock time: $(date -d "@$UNLOCK_TIME" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r $UNLOCK_TIME "+%Y-%m-%d %H:%M:%S")"
    echo "Time left: $DAYS_LEFT days"
    exit 1
fi

# Calculate withdrawal amount
TOTAL_AMOUNT=$(echo "$AMOUNT + $YIELD_AMOUNT" | bc)
FEE=$(echo "scale=0; $TOTAL_AMOUNT * $WITHDRAWAL_FEE / 10000" | bc)
NET_AMOUNT=$(echo "$TOTAL_AMOUNT - $FEE" | bc)

TOTAL_BTC=$(echo "scale=8; $TOTAL_AMOUNT / 100000000" | bc)
FEE_BTC=$(echo "scale=8; $FEE / 100000000" | bc)
NET_BTC=$(echo "scale=8; $NET_AMOUNT / 100000000" | bc)

echo ""
log_info "Requesting withdrawal from vault #$VAULT_ID..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Vault ID:         $VAULT_ID"
echo "Owner:            $OWNER_KEY ($OWNER_ADDRESS)"
echo "Principal:        $AMOUNT satoshis"
echo "Yield:            $YIELD_AMOUNT satoshis"
echo "Total:            $TOTAL_AMOUNT satoshis ($TOTAL_BTC BTC)"
echo "Withdrawal Fee:   $FEE satoshis ($FEE_BTC BTC)"
echo "Net Amount:       $NET_AMOUNT satoshis ($NET_BTC BTC)"
echo "BTC Address:      $BTC_ADDRESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_warning "After this request, you'll need $REQUIRED_APPROVALS approvals from signers"
echo ""

read -p "Proceed with withdrawal request? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

# Request withdrawal
log_info "Invoking request_withdrawal..."
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$OWNER_KEY" \
  --network "$NETWORK" \
  -- \
  request_withdrawal \
  --vault_id "$VAULT_ID" \
  --btc_address "$BTC_ADDRESS" 2>&1)

if echo "$RESULT" | grep -q "Success"; then
    WITHDRAWAL_ID=$(echo "$RESULT" | grep -o '"u64":"[0-9]*"' | grep -o '[0-9]*' | head -1)
    log_success "Withdrawal requested successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Withdrawal ID: $WITHDRAWAL_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Next steps:"
    echo "  1. Get $REQUIRED_APPROVALS signers to approve:"
    echo "     ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer bob"
    echo "     ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer charlie"
    echo ""
    echo "  2. After approvals, execute withdrawal:"
    echo "     ./scripts/execute-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --vault-id $VAULT_ID"
    echo ""
else
    log_error "Failed to request withdrawal"
    echo "$RESULT"
    exit 1
fi
