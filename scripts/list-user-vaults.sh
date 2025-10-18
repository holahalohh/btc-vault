#!/bin/bash
# Script to list all vaults for a user

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
USER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            USER="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --user USER"
            echo ""
            echo "List all vaults for a specific user"
            echo ""
            echo "Options:"
            echo "  --user NAME    User name (alice, bob, charlie, or david)"
            echo "  --help         Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --user bob"
            echo "  $0 --user alice"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$USER" ]; then
    log_error "User is required"
    echo "Usage: $0 --user USER"
    exit 1
fi

# Determine user address
case $USER in
    admin|alice)
        USER_ADDRESS="$ADMIN_ADDRESS"
        ;;
    bob)
        USER_ADDRESS="$SIGNER1_ADDRESS"
        ;;
    charlie)
        USER_ADDRESS="$SIGNER2_ADDRESS"
        ;;
    david)
        USER_ADDRESS="$SIGNER3_ADDRESS"
        ;;
    *)
        log_error "Invalid user. Must be alice, bob, charlie, or david"
        exit 1
        ;;
esac

echo ""
log_info "Fetching vaults for $USER ($USER_ADDRESS)..."
echo ""

# Get user vaults
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_user_vaults \
  --user "$USER_ADDRESS" 2>&1)

if echo "$RESULT" | grep -q "error"; then
    log_error "Failed to fetch user vaults"
    echo "$RESULT"
    exit 1
fi

# Check if empty
if echo "$RESULT" | grep -q "\[\]"; then
    log_warning "No vaults found for $USER"
    echo ""
    echo "Create a vault with:"
    echo "  ./scripts/create-vault.sh --owner $USER --amount <SATOSHIS> --duration <SECONDS>"
    exit 0
fi

# Parse vault IDs
VAULT_IDS=$(echo "$RESULT" | grep -o '"u64":"[0-9]*"' | grep -o '[0-9]*')

if [ -z "$VAULT_IDS" ]; then
    log_warning "No vaults found for $USER"
    exit 0
fi

VAULT_COUNT=$(echo "$VAULT_IDS" | wc -l)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 VAULTS FOR $USER ($USER_ADDRESS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Found $VAULT_COUNT vault(s)"
echo ""

CURRENT_TIME=$(date +%s)
TOTAL_LOCKED=0
TOTAL_YIELD=0

# Iterate through vault IDs
for VAULT_ID in $VAULT_IDS; do
    # Get vault details
    VAULT_DATA=$(stellar contract invoke \
      --id "$CONTRACT_ID" \
      --source "$ADMIN_KEY" \
      --network "$NETWORK" \
      -- \
      get_vault \
      --vault_id "$VAULT_ID" 2>&1)
    
    if echo "$VAULT_DATA" | grep -q "error"; then
        continue
    fi
    
    AMOUNT=$(echo "$VAULT_DATA" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
    CREATED_AT=$(echo "$VAULT_DATA" | grep -o '"created_at":[0-9]*' | grep -o '[0-9]*')
    LOCK_DURATION=$(echo "$VAULT_DATA" | grep -o '"lock_duration":[0-9]*' | grep -o '[0-9]*')
    BTC_ADDRESS=$(echo "$VAULT_DATA" | grep -o '"btc_address":"[^"]*"' | cut -d'"' -f4)
    YIELD_AMOUNT=$(echo "$VAULT_DATA" | grep -o '"yield_amount":"[0-9]*"' | grep -o '[0-9]*')
    LAST_YIELD_CLAIM=$(echo "$VAULT_DATA" | grep -o '"last_yield_claim":[0-9]*' | grep -o '[0-9]*')
    
    AMOUNT_BTC=$(echo "scale=8; $AMOUNT / 100000000" | bc)
    YIELD_BTC=$(echo "scale=8; $YIELD_AMOUNT / 100000000" | bc)
    
    UNLOCK_TIME=$((CREATED_AT + LOCK_DURATION))
    DURATION_DAYS=$(echo "scale=1; $LOCK_DURATION / 86400" | bc)
    
    # Calculate status
    if [ "$CURRENT_TIME" -lt "$UNLOCK_TIME" ]; then
        TIME_LEFT=$((UNLOCK_TIME - CURRENT_TIME))
        DAYS_LEFT=$(echo "scale=1; $TIME_LEFT / 86400" | bc)
        STATUS="🔒 Locked ($DAYS_LEFT days left)"
    else
        STATUS="🔓 Unlocked"
    fi
    
    # Calculate current yield
    TIME_HELD=$((CURRENT_TIME - LAST_YIELD_CLAIM))
    CURRENT_YIELD=$(echo "scale=0; ($AMOUNT * $YIELD_RATE * $TIME_HELD) / (10000 * 31536000)" | bc)
    CURRENT_YIELD_BTC=$(echo "scale=8; $CURRENT_YIELD / 100000000" | bc)
    
    TOTAL_LOCKED=$((TOTAL_LOCKED + AMOUNT))
    TOTAL_YIELD=$((TOTAL_YIELD + YIELD_AMOUNT + CURRENT_YIELD))
    
    echo "┌─────────────────────────────────────────────────────┐"
    echo "│ Vault #$VAULT_ID"
    echo "├─────────────────────────────────────────────────────┤"
    echo "│ Amount:           $AMOUNT_BTC BTC"
    echo "│ Locked For:       $DURATION_DAYS days"
    echo "│ Status:           $STATUS"
    echo "│ Created:          $(date -d "@$CREATED_AT" "+%Y-%m-%d" 2>/dev/null || date -r $CREATED_AT "+%Y-%m-%d")"
    echo "│ Unlock Date:      $(date -d "@$UNLOCK_TIME" "+%Y-%m-%d" 2>/dev/null || date -r $UNLOCK_TIME "+%Y-%m-%d")"
    echo "│ BTC Address:      ${BTC_ADDRESS:0:20}..."
    echo "│ Claimed Yield:    $YIELD_BTC BTC"
    echo "│ Claimable Yield:  $CURRENT_YIELD_BTC BTC"
    echo "└─────────────────────────────────────────────────────┘"
    echo ""
    
    # Suggest actions
    if [ "$CURRENT_TIME" -ge "$UNLOCK_TIME" ]; then
        echo "   💡 Actions: ./scripts/request-withdrawal.sh --vault-id $VAULT_ID"
    elif [ "$CURRENT_YIELD" -gt 0 ]; then
        echo "   💡 Actions: ./scripts/claim-yield.sh --vault-id $VAULT_ID"
    fi
    echo ""
done

TOTAL_LOCKED_BTC=$(echo "scale=8; $TOTAL_LOCKED / 100000000" | bc)
TOTAL_YIELD_BTC=$(echo "scale=8; $TOTAL_YIELD / 100000000" | bc)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY FOR $USER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Vaults:        $VAULT_COUNT"
echo "Total Locked:        $TOTAL_LOCKED_BTC BTC"
echo "Total Yield:         $TOTAL_YIELD_BTC BTC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log_info "View vault details:"
echo "  ./scripts/get-vault.sh --vault-id <ID>"
echo ""
