#!/bin/bash
# Script to pause the contract (admin only)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ""
log_warning "⚠️  PAUSING CONTRACT ⚠️"
echo ""
echo "This will prevent all vault operations:"
echo "  - Creating new vaults"
echo "  - Claiming yield"
echo "  - Requesting withdrawals"
echo "  - Approving withdrawals"
echo "  - Executing withdrawals"
echo ""
echo "Only admin can pause/resume the contract."
echo ""

read -p "Are you sure you want to pause the contract? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

log_info "Pausing contract..."

RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  pause 2>&1)

if echo "$RESULT" | grep -q "Success\|()"; then
    log_success "✅ Contract paused successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⏸️  CONTRACT IS NOW PAUSED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "All vault operations are suspended"
    echo ""
    echo "To resume operations:"
    echo "  ./scripts/resume.sh"
    echo ""
else
    log_error "Failed to pause contract"
    echo "$RESULT"
    exit 1
fi
