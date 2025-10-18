#!/bin/bash
# Script to execute an approved withdrawal

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
WITHDRAWAL_ID=""
VAULT_ID=""
EXECUTOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --withdrawal-id)
            WITHDRAWAL_ID="$2"
            shift 2
            ;;
        --vault-id)
            VAULT_ID="$2"
            shift 2
            ;;
        --executor)
            EXECUTOR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --withdrawal-id ID --vault-id VAULT_ID [OPTIONS]"
            echo ""
            echo "Execute an approved withdrawal (requires sufficient approvals)"
            echo ""
            echo "Options:"
            echo "  --withdrawal-id ID   Withdrawal request ID to execute"
            echo "  --vault-id ID        Vault ID"
            echo "  --executor NAME      Executor name (default: admin)"
            echo "  --help               Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --withdrawal-id 0 --vault-id 0"
            echo "  $0 --withdrawal-id 0 --vault-id 0 --executor bob"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$WITHDRAWAL_ID" ] || [ -z "$VAULT_ID" ]; then
    log_error "Both withdrawal ID and vault ID are required"
    echo "Usage: $0 --withdrawal-id ID --vault-id VAULT_ID"
    exit 1
fi

# Determine executor key (default to admin)
if [ -z "$EXECUTOR" ]; then
    EXECUTOR="admin"
fi

case $EXECUTOR in
    admin|alice)
        EXECUTOR_KEY="$ADMIN_KEY"
        EXECUTOR_ADDRESS="$ADMIN_ADDRESS"
        ;;
    bob)
        EXECUTOR_KEY="$SIGNER1_KEY"
        EXECUTOR_ADDRESS="$SIGNER1_ADDRESS"
        ;;
    charlie)
        EXECUTOR_KEY="$SIGNER2_KEY"
        EXECUTOR_ADDRESS="$SIGNER2_ADDRESS"
        ;;
    david)
        EXECUTOR_KEY="$SIGNER3_KEY"
        EXECUTOR_ADDRESS="$SIGNER3_ADDRESS"
        ;;
    *)
        log_error "Invalid executor. Must be admin, alice, bob, charlie, or david"
        exit 1
        ;;
esac

# Get withdrawal request details
log_info "Fetching withdrawal request #$WITHDRAWAL_ID details..."
WITHDRAWAL_DATA=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$ADMIN_KEY" \
  --network "$NETWORK" \
  -- \
  get_withdrawal_request \
  --withdrawal_id "$WITHDRAWAL_ID" 2>&1)

if echo "$WITHDRAWAL_DATA" | grep -q "error"; then
    log_error "Withdrawal request #$WITHDRAWAL_ID not found"
    exit 1
fi

AMOUNT=$(echo "$WITHDRAWAL_DATA" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
BTC_ADDRESS=$(echo "$WITHDRAWAL_DATA" | grep -o '"btc_address":"[^"]*"' | cut -d'"' -f4)
REQUESTED_AT=$(echo "$WITHDRAWAL_DATA" | grep -o '"requested_at":[0-9]*' | grep -o '[0-9]*')
APPROVAL_COUNT=$(echo "$WITHDRAWAL_DATA" | grep -o '"approval_count":[0-9]*' | grep -o '[0-9]*')

AMOUNT_BTC=$(echo "scale=8; $AMOUNT / 100000000" | bc)

# Check if withdrawal has enough approvals
if [ "$APPROVAL_COUNT" -lt "$REQUIRED_APPROVALS" ]; then
    log_error "Withdrawal does not have enough approvals!"
    echo "Current approvals: $APPROVAL_COUNT / $REQUIRED_APPROVALS"
    echo ""
    REMAINING=$((REQUIRED_APPROVALS - APPROVAL_COUNT))
    log_info "Need $REMAINING more approval(s). Run:"
    echo "  ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer <bob|charlie|david>"
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

VAULT_OWNER=$(echo "$VAULT_DATA" | grep -o '"owner":"[^"]*"' | cut -d'"' -f4)

echo ""
log_info "Executing withdrawal #$WITHDRAWAL_ID..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Withdrawal ID:    $WITHDRAWAL_ID"
echo "Vault ID:         $VAULT_ID"
echo "Vault Owner:      $VAULT_OWNER"
echo "Amount:           $AMOUNT satoshis ($AMOUNT_BTC BTC)"
echo "BTC Address:      $BTC_ADDRESS"
echo "Requested:        $(date -d "@$REQUESTED_AT" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r $REQUESTED_AT "+%Y-%m-%d %H:%M:%S")"
echo "Approvals:        $APPROVAL_COUNT / $REQUIRED_APPROVALS ✅"
echo "Executing as:     $EXECUTOR ($EXECUTOR_ADDRESS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_warning "This will release funds from the contract"
echo ""

read -p "Execute this withdrawal? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

# Execute withdrawal
log_info "Invoking execute_withdrawal..."
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$EXECUTOR_KEY" \
  --network "$NETWORK" \
  -- \
  execute_withdrawal \
  --withdrawal_id "$WITHDRAWAL_ID" \
  --vault_id "$VAULT_ID" 2>&1)

if echo "$RESULT" | grep -q "Success\|()"; then
    log_success "✅ Withdrawal executed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Amount Withdrawn: $AMOUNT_BTC BTC"
    echo "BTC Address:      $BTC_ADDRESS"
    echo "Vault ID:         $VAULT_ID (now closed)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "The vault has been closed and funds have been released"
    echo ""
    log_info "View contract stats:"
    echo "  ./scripts/get-stats.sh"
    echo ""
else
    log_error "Failed to execute withdrawal"
    echo "$RESULT"
    exit 1
fi
