#!/bin/bash
# Script to approve a withdrawal request (multi-sig)

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse arguments
WITHDRAWAL_ID=""
SIGNER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --withdrawal-id)
            WITHDRAWAL_ID="$2"
            shift 2
            ;;
        --signer)
            SIGNER="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --withdrawal-id ID --signer SIGNER"
            echo ""
            echo "Approve a withdrawal request (requires multi-sig signer)"
            echo ""
            echo "Options:"
            echo "  --withdrawal-id ID   Withdrawal request ID to approve"
            echo "  --signer NAME        Signer name (bob, charlie, or david)"
            echo "  --help               Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --withdrawal-id 0 --signer bob"
            echo "  $0 --withdrawal-id 0 --signer charlie"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$WITHDRAWAL_ID" ] || [ -z "$SIGNER" ]; then
    log_error "Both withdrawal ID and signer are required"
    echo "Usage: $0 --withdrawal-id ID --signer SIGNER"
    exit 1
fi

# Determine signer key
case $SIGNER in
    bob)
        SIGNER_KEY="$SIGNER1_KEY"
        SIGNER_ADDRESS="$SIGNER1_ADDRESS"
        ;;
    charlie)
        SIGNER_KEY="$SIGNER2_KEY"
        SIGNER_ADDRESS="$SIGNER2_ADDRESS"
        ;;
    david)
        SIGNER_KEY="$SIGNER3_KEY"
        SIGNER_ADDRESS="$SIGNER3_ADDRESS"
        ;;
    *)
        log_error "Invalid signer. Must be bob, charlie, or david"
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

VAULT_ID=$(echo "$WITHDRAWAL_DATA" | grep -o '"vault_id":"[0-9]*"' | grep -o '[0-9]*')
AMOUNT=$(echo "$WITHDRAWAL_DATA" | grep -o '"amount":"[0-9]*"' | grep -o '[0-9]*')
BTC_ADDRESS=$(echo "$WITHDRAWAL_DATA" | grep -o '"btc_address":"[^"]*"' | cut -d'"' -f4)
REQUESTED_AT=$(echo "$WITHDRAWAL_DATA" | grep -o '"requested_at":[0-9]*' | grep -o '[0-9]*')
APPROVAL_COUNT=$(echo "$WITHDRAWAL_DATA" | grep -o '"approval_count":[0-9]*' | grep -o '[0-9]*')

AMOUNT_BTC=$(echo "scale=8; $AMOUNT / 100000000" | bc)

# Check if already approved by this signer
if echo "$WITHDRAWAL_DATA" | grep -q "\"$SIGNER_ADDRESS\""; then
    log_warning "Signer $SIGNER has already approved this withdrawal"
    echo ""
    echo "Current approvals: $APPROVAL_COUNT / $REQUIRED_APPROVALS"
    
    if [ "$APPROVAL_COUNT" -ge "$REQUIRED_APPROVALS" ]; then
        log_success "Withdrawal is ready to execute!"
        echo ""
        echo "Execute with:"
        echo "  ./scripts/execute-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --vault-id $VAULT_ID"
    fi
    exit 0
fi

echo ""
log_info "Approving withdrawal request #$WITHDRAWAL_ID..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Withdrawal ID:    $WITHDRAWAL_ID"
echo "Vault ID:         $VAULT_ID"
echo "Amount:           $AMOUNT satoshis ($AMOUNT_BTC BTC)"
echo "BTC Address:      $BTC_ADDRESS"
echo "Requested:        $(date -d "@$REQUESTED_AT" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r $REQUESTED_AT "+%Y-%m-%d %H:%M:%S")"
echo "Current Approvals: $APPROVAL_COUNT / $REQUIRED_APPROVALS"
echo "Approving as:     $SIGNER ($SIGNER_ADDRESS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Approve this withdrawal? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Cancelled"
    exit 0
fi

# Approve withdrawal
log_info "Invoking approve_withdrawal..."
RESULT=$(stellar contract invoke \
  --id "$CONTRACT_ID" \
  --source "$SIGNER_KEY" \
  --network "$NETWORK" \
  -- \
  approve_withdrawal \
  --withdrawal_id "$WITHDRAWAL_ID" \
  --signer "$SIGNER_ADDRESS" 2>&1)

if echo "$RESULT" | grep -q "Success\|()"; then
    log_success "Withdrawal approved by $SIGNER!"
    
    NEW_APPROVAL_COUNT=$((APPROVAL_COUNT + 1))
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Approvals: $NEW_APPROVAL_COUNT / $REQUIRED_APPROVALS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$NEW_APPROVAL_COUNT" -ge "$REQUIRED_APPROVALS" ]; then
        log_success "✅ Withdrawal has enough approvals and can be executed!"
        echo ""
        echo "Execute with:"
        echo "  ./scripts/execute-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --vault-id $VAULT_ID"
    else
        REMAINING=$((REQUIRED_APPROVALS - NEW_APPROVAL_COUNT))
        log_info "Need $REMAINING more approval(s)"
        echo ""
        echo "Next approver can run:"
        if [ "$SIGNER" != "bob" ]; then
            echo "  ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer bob"
        fi
        if [ "$SIGNER" != "charlie" ]; then
            echo "  ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer charlie"
        fi
        if [ "$SIGNER" != "david" ]; then
            echo "  ./scripts/approve-withdrawal.sh --withdrawal-id $WITHDRAWAL_ID --signer david"
        fi
    fi
    echo ""
else
    log_error "Failed to approve withdrawal"
    echo "$RESULT"
    exit 1
fi
