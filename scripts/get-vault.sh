#!/bin/bash
# Script to get vault details

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
VAULT_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --vault-id)
            VAULT_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --vault-id VAULT_ID"
            echo ""
            echo "Get details of a specific vault"
            echo ""
            echo "Options:"
            echo "  --vault-id ID    Vault ID to query"
            echo "  --help           Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --vault-id 0"
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
    echo "Usage: $0 --vault-id VAULT_ID"
    exit 1
fi

log_info "Fetching vault #$VAULT_ID details..."

# Get vault
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_vault \
  --vault_id "$VAULT_ID" 2>&1)

if echo "$RESULT" | grep -q "VaultNotFound"; then
    log_error "Vault #$VAULT_ID not found"
    exit 1
fi

# Parse JSON (basic parsing)
AMOUNT=$(echo "$RESULT" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
OWNER=$(echo "$RESULT" | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)
CREATED_AT=$(echo "$RESULT" | grep -o '"created_at":[0-9]*' | grep -o '[0-9]*')
LOCK_DURATION=$(echo "$RESULT" | grep -o '"lock_duration":[0-9]*' | grep -o '[0-9]*')
BTC_ADDRESS=$(echo "$RESULT" | grep -o '"btc_address":"[^"]*"' | cut -d'"' -f4)
YIELD_AMOUNT=$(echo "$RESULT" | grep -o '"yield_amount":"[0-9]*"' | grep -o '[0-9]*')
YIELD_CLAIMED=$(echo "$RESULT" | grep -o '"yield_claimed":[a-z]*' | cut -d':' -f2)

# Calculate values
if [ -n "$AMOUNT" ] && [ "$AMOUNT" != "0" ]; then
    BTC_AMOUNT=$(echo "scale=8; $AMOUNT / 100000000" | bc)
    UNLOCK_TIME=$((CREATED_AT + LOCK_DURATION))
    CURRENT_TIME=$(date +%s)
    
    # Calculate unlock date
    UNLOCK_DATE=$(date -d "@$UNLOCK_TIME" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r $UNLOCK_TIME "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "N/A")
    CREATED_DATE=$(date -d "@$CREATED_AT" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r $CREATED_AT "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "N/A")
    
    DAYS=$(echo "scale=2; $LOCK_DURATION / 86400" | bc)
    
    # Check if locked
    if [ "$CURRENT_TIME" -lt "$UNLOCK_TIME" ]; then
        STATUS="🔒 LOCKED"
        TIME_LEFT=$((UNLOCK_TIME - CURRENT_TIME))
        DAYS_LEFT=$(echo "scale=1; $TIME_LEFT / 86400" | bc)
    else
        STATUS="🔓 UNLOCKED"
        DAYS_LEFT="0"
    fi
    
    # Calculate current yield
    TIME_ELAPSED=$((CURRENT_TIME - CREATED_AT))
    if [ $TIME_ELAPSED -lt 0 ]; then
        TIME_ELAPSED=0
    fi
    CURRENT_YIELD=$(echo "scale=0; $AMOUNT * $YIELD_RATE * $TIME_ELAPSED / 10000 / 31536000" | bc)
    CURRENT_YIELD_BTC=$(echo "scale=8; $CURRENT_YIELD / 100000000" | bc)
    
    YIELD_BTC=$(echo "scale=8; $YIELD_AMOUNT / 100000000" | bc)
    
    # Display
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    VAULT #$VAULT_ID DETAILS                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Basic Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Vault ID:        $VAULT_ID"
    echo "Status:          $STATUS"
    echo "Owner:           $OWNER"
    echo ""
    echo "💰 Balance"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Amount:          $AMOUNT satoshis"
    echo "                 $BTC_AMOUNT BTC"
    echo ""
    echo "📅 Time Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Created:         $CREATED_DATE"
    echo "                 (Timestamp: $CREATED_AT)"
    echo "Lock Duration:   $LOCK_DURATION seconds ($DAYS days)"
    echo "Unlock Date:     $UNLOCK_DATE"
    echo "                 (Timestamp: $UNLOCK_TIME)"
    if [ "$CURRENT_TIME" -lt "$UNLOCK_TIME" ]; then
        echo "Time Left:       $TIME_LEFT seconds ($DAYS_LEFT days)"
    fi
    echo ""
    echo "📈 Yield Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Current Yield:   $CURRENT_YIELD satoshis"
    echo "                 $CURRENT_YIELD_BTC BTC"
    echo "Claimed Yield:   $YIELD_AMOUNT satoshis"
    echo "                 $YIELD_BTC BTC"
    echo "Yield Claimed:   $YIELD_CLAIMED"
    echo "Yield Rate:      ${YIELD_RATE} basis points (10% APY)"
    echo ""
    echo "🔗 Bitcoin Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "BTC Address:     $BTC_ADDRESS"
    echo ""
    
    # Action suggestions
    if [ "$CURRENT_TIME" -ge "$UNLOCK_TIME" ]; then
        log_success "This vault can be withdrawn!"
        echo ""
        echo "Next steps:"
        echo "  1. ./scripts/request-withdrawal.sh --vault-id $VAULT_ID"
    else
        log_info "This vault is still locked for $DAYS_LEFT days"
        if [ "$CURRENT_YIELD" -gt "0" ]; then
            echo ""
            echo "You can claim yield:"
            echo "  ./scripts/claim-yield.sh --vault-id $VAULT_ID"
        fi
    fi
    echo ""
else
    log_error "Failed to parse vault data"
    echo "$RESULT"
fi
