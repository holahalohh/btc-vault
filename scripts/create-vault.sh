#!/bin/bash
# Script to create a new vault

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Default values
OWNER_KEY="$ADMIN_KEY"
OWNER_ADDRESS="$ADMIN_ADDRESS"
AMOUNT="$ONE_BTC"
LOCK_DURATION="$ONE_MONTH"
BTC_ADDRESS="bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --owner)
            OWNER_KEY="$2"
            OWNER_ADDRESS=$(stellar keys address "$2" 2>/dev/null)
            if [ -z "$OWNER_ADDRESS" ]; then
                log_error "Invalid owner key: $2"
                exit 1
            fi
            shift 2
            ;;
        --amount)
            AMOUNT="$2"
            shift 2
            ;;
        --duration)
            LOCK_DURATION="$2"
            shift 2
            ;;
        --btc-address)
            BTC_ADDRESS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Create a new Bitcoin vault"
            echo ""
            echo "Options:"
            echo "  --owner KEY          Owner's key name (default: alice)"
            echo "  --amount SATOSHIS    Amount in satoshis (default: 100000000 = 1 BTC)"
            echo "  --duration SECONDS   Lock duration in seconds (default: 2592000 = 30 days)"
            echo "  --btc-address ADDR   Bitcoin address for withdrawal"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --owner bob --amount 50000000 --duration 604800"
            echo "  $0 --amount \$ONE_BTC --duration \$ONE_MONTH"
            echo ""
            echo "Common amounts (satoshis):"
            echo "  \$POINT_ONE_BTC = 10,000,000 (0.1 BTC)"
            echo "  \$HALF_BTC      = 50,000,000 (0.5 BTC)"
            echo "  \$ONE_BTC       = 100,000,000 (1 BTC)"
            echo "  \$TWO_BTC       = 200,000,000 (2 BTC)"
            echo ""
            echo "Common durations (seconds):"
            echo "  \$ONE_DAY       = 86,400 (1 day)"
            echo "  \$ONE_WEEK      = 604,800 (1 week)"
            echo "  \$ONE_MONTH     = 2,592,000 (30 days)"
            echo "  \$THREE_MONTHS  = 7,776,000 (90 days)"
            echo "  \$ONE_YEAR      = 31,536,000 (365 days)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Calculate expected values
BTC_AMOUNT=$(echo "scale=8; $AMOUNT / 100000000" | bc)
DAYS=$(echo "scale=2; $LOCK_DURATION / 86400" | bc)
FEE=$(echo "scale=0; $AMOUNT * $DEPOSIT_FEE / 10000" | bc)
NET_AMOUNT=$(echo "$AMOUNT - $FEE" | bc)
NET_BTC=$(echo "scale=8; $NET_AMOUNT / 100000000" | bc)

# Display information
echo ""
log_info "Creating new vault..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Owner:          $OWNER_KEY ($OWNER_ADDRESS)"
echo "Amount:         $AMOUNT satoshis ($BTC_AMOUNT BTC)"
echo "Deposit Fee:    $FEE satoshis (${DEPOSIT_FEE} basis points = 0.5%)"
echo "Net Amount:     $NET_AMOUNT satoshis ($NET_BTC BTC)"
echo "Lock Duration:  $LOCK_DURATION seconds ($DAYS days)"
echo "BTC Address:    $BTC_ADDRESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm
read -p "Proceed with vault creation? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

# Create vault
log_info "Invoking create_vault..."
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$OWNER_KEY" \
  --network "$NETWORK" \
  -- \
  create_vault \
  --owner "$OWNER_ADDRESS" \
  --amount "$AMOUNT" \
  --lock_duration "$LOCK_DURATION" \
  --btc_address "$BTC_ADDRESS" 2>&1)

# Check result
if echo "$RESULT" | grep -q "Success"; then
    VAULT_ID=$(echo "$RESULT" | grep -o '"u64":"[0-9]*"' | grep -o '[0-9]*' | head -1)
    log_success "Vault created successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Vault ID: $VAULT_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "To view vault details, run:"
    echo "  ./scripts/get-vault.sh --vault-id $VAULT_ID"
    echo ""
else
    log_error "Failed to create vault"
    echo "$RESULT"
    exit 1
fi
