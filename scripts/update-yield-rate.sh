#!/bin/bash
# Script to update the yield rate (admin only)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
NEW_RATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --rate)
            NEW_RATE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --rate RATE"
            echo ""
            echo "Update the yield rate (admin only)"
            echo ""
            echo "Options:"
            echo "  --rate RATE    New yield rate in basis points (1% = 100)"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --rate 1000   # Set to 10% APY"
            echo "  $0 --rate 500    # Set to 5% APY"
            echo "  $0 --rate 1500   # Set to 15% APY"
            echo ""
            echo "Current rate: $YIELD_RATE basis points ($((YIELD_RATE / 100))% APY)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$NEW_RATE" ]; then
    log_error "New rate is required"
    echo "Usage: $0 --rate RATE"
    echo "Run '$0 --help' for examples"
    exit 1
fi

# Validate rate
if ! [[ "$NEW_RATE" =~ ^[0-9]+$ ]]; then
    log_error "Rate must be a positive integer (basis points)"
    exit 1
fi

if [ "$NEW_RATE" -gt 10000 ]; then
    log_error "Rate cannot exceed 10000 basis points (100%)"
    exit 1
fi

NEW_APY=$(echo "scale=2; $NEW_RATE / 100" | bc)
CURRENT_APY=$(echo "scale=2; $YIELD_RATE / 100" | bc)

echo ""
log_info "Updating yield rate..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Current Rate:  $YIELD_RATE basis points ($CURRENT_APY% APY)"
echo "New Rate:      $NEW_RATE basis points ($NEW_APY% APY)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$NEW_RATE" -gt "$YIELD_RATE" ]; then
    log_success "📈 Increasing yield rate"
elif [ "$NEW_RATE" -lt "$YIELD_RATE" ]; then
    log_warning "📉 Decreasing yield rate"
else
    log_warning "Rate is unchanged"
    exit 0
fi

echo ""
read -p "Update yield rate? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

log_info "Invoking update_yield_rate..."

RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  update_yield_rate \
  --new_rate "$NEW_RATE" 2>&1)

if echo "$RESULT" | grep -q "Success\|()"; then
    log_success "✅ Yield rate updated successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  New Yield Rate: $NEW_APY% APY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "This rate applies to:"
    echo "  - All new vaults created from now"
    echo "  - Ongoing yield calculations for existing vaults"
    echo ""
    log_info "View updated config:"
    echo "  ./scripts/get-stats.sh"
    echo ""
else
    log_error "Failed to update yield rate"
    echo "$RESULT"
    exit 1
fi
