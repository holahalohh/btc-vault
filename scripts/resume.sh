#!/bin/bash
# Script to resume the contract (admin only)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ""
log_info "Resuming contract operations..."
echo ""

RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  resume 2>&1)

if echo "$RESULT" | grep -q "Success\|()"; then
    log_success "✅ Contract resumed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ▶️  CONTRACT IS NOW ACTIVE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_success "All vault operations are restored"
    echo ""
    log_info "View contract stats:"
    echo "  ./scripts/get-stats.sh"
    echo ""
else
    log_error "Failed to resume contract"
    echo "$RESULT"
    exit 1
fi
