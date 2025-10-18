#!/bin/bash
# Script to claim yield from a vault

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
VAULT_ID=""
OWNER_KEY=""

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
        --help)
            echo "Usage: $0 --vault-id VAULT_ID [--owner KEY]"
            echo ""
            echo "Claim accumulated yield from a vault"
            echo ""
            echo "Options:"
            echo "  --vault-id ID    Vault ID to claim from"
            echo "  --owner KEY      Owner's key name (auto-detected if not provided)"
            echo "  --help           Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --vault-id 0"
            echo "  $0 --vault-id 0 --owner bob"
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
    echo "Usage: $0 --vault-id VAULT_ID [--owner KEY]"
    exit 1
fi

# Get vault details to find owner if not provided
if [ -z "$OWNER_KEY" ]; then
    log_info "Fetching vault details to determine owner..."
    VAULT_DATA=$(stellar contract invoke \
      --id "$CONTRACT_ID" \
      --source "$ADMIN_KEY" \
      --network "$NETWORK" \
      -- \
      get_vault \
      --vault_id "$VAULT_ID" 2>&1)
    
    OWNER_ADDRESS=$(echo "$VAULT_DATA" | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)
    
    # Try to match with known addresses
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

# Get current yield estimate
log_info "Calculating current yield for vault #$VAULT_ID..."

VAULT_DATA=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_vault \
  --vault_id "$VAULT_ID" 2>&1)

AMOUNT=$(echo "$VAULT_DATA" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
CREATED_AT=$(echo "$VAULT_DATA" | grep -o '"created_at":[0-9]*' | grep -o '[0-9]*')
CLAIMED_YIELD=$(echo "$VAULT_DATA" | grep -o '"yield_amount":"[0-9]*"' | grep -o '[0-9]*')

CURRENT_TIME=$(date +%s)
TIME_ELAPSED=$((CURRENT_TIME - CREATED_AT))
TOTAL_YIELD=$(echo "scale=0; $AMOUNT * $YIELD_RATE * $TIME_ELAPSED / 10000 / 31536000" | bc)
CLAIMABLE_YIELD=$(echo "$TOTAL_YIELD - $CLAIMED_YIELD" | bc)

if [ "$CLAIMABLE_YIELD" -le "0" ]; then
    log_warning "No yield available to claim yet"
    CLAIMABLE_BTC=$(echo "scale=8; $CLAIMABLE_YIELD / 100000000" | bc)
    echo "Current claimable yield: $CLAIMABLE_YIELD satoshis ($CLAIMABLE_BTC BTC)"
    exit 0
fi

CLAIMABLE_BTC=$(echo "scale=8; $CLAIMABLE_YIELD / 100000000" | bc)

echo ""
log_info "Claiming yield from vault #$VAULT_ID..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Vault ID:         $VAULT_ID"
echo "Owner:            $OWNER_KEY"
echo "Estimated Yield:  ~$CLAIMABLE_YIELD satoshis (~$CLAIMABLE_BTC BTC)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Claim yield
log_info "Invoking claim_yield..."
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$OWNER_KEY" \
  --network "$NETWORK" \
  -- \
  claim_yield \
  --vault_id "$VAULT_ID" 2>&1)

if echo "$RESULT" | grep -q "Success"; then
    # Extract actual claimed amount from result
    CLAIMED=$(echo "$RESULT" | grep -o '"i128":"[0-9]*"' | grep -o '[0-9]*')
    CLAIMED_BTC=$(echo "scale=8; $CLAIMED / 100000000" | bc)
    
    log_success "Yield claimed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Claimed Amount:   $CLAIMED satoshis"
    echo "                  $CLAIMED_BTC BTC"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    log_error "Failed to claim yield"
    echo "$RESULT"
    exit 1
fi
