#!/bin/bash
# Master menu script for Bitcoin Vault contract interaction

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

show_header() {
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "        🪙  BITCOIN VAULT CONTRACT MANAGER  🪙"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Contract: $CONTRACT_ID"
    echo "Network:  $NETWORK"
    echo ""
}

show_menu() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  MAIN MENU"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  📊 QUERY OPERATIONS"
    echo "  ───────────────────"
    echo "  1) View Contract Statistics"
    echo "  2) View Vault Details"
    echo "  3) List User Vaults"
    echo "  4) View Configuration"
    echo ""
    echo "  💰 VAULT OPERATIONS"
    echo "  ───────────────────"
    echo "  5) Create New Vault"
    echo "  6) Claim Yield"
    echo ""
    echo "  🔓 WITHDRAWAL OPERATIONS"
    echo "  ────────────────────────"
    echo "  7) Request Withdrawal"
    echo "  8) Approve Withdrawal"
    echo "  9) Execute Withdrawal"
    echo ""
    echo "  ⚙️  ADMIN OPERATIONS (Admin Only)"
    echo "  ─────────────────────────────────"
    echo "  A) Pause Contract"
    echo "  B) Resume Contract"
    echo "  C) Update Yield Rate"
    echo ""
    echo "  ❌ EXIT"
    echo "  ───────"
    echo "  0) Exit"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

pause_for_input() {
    echo ""
    read -p "Press Enter to continue..." -r
}

while true; do
    show_header
    show_menu
    read -p "Select an option: " choice
    echo ""

    case $choice in
        1)
            log_info "Fetching contract statistics..."
            "$SCRIPT_DIR/get-stats.sh"
            pause_for_input
            ;;
        2)
            read -p "Enter vault ID: " vault_id
            if [ -n "$vault_id" ]; then
                "$SCRIPT_DIR/get-vault.sh" --vault-id "$vault_id"
            else
                log_error "Vault ID is required"
            fi
            pause_for_input
            ;;
        3)
            echo "Available users: alice, bob, charlie, david"
            read -p "Enter user name: " user
            if [ -n "$user" ]; then
                "$SCRIPT_DIR/list-user-vaults.sh" --user "$user"
            else
                log_error "User name is required"
            fi
            pause_for_input
            ;;
        4)
            log_info "Viewing configuration..."
            print_config
            pause_for_input
            ;;
        5)
            echo "Create New Vault"
            echo "───────────────"
            read -p "Owner (alice/bob/charlie/david): " owner
            read -p "Amount (satoshis, e.g., 100000000 = 1 BTC): " amount
            read -p "Lock duration (seconds, e.g., 2592000 = 30 days): " duration
            read -p "BTC address: " btc_addr
            
            if [ -n "$owner" ] && [ -n "$amount" ] && [ -n "$duration" ] && [ -n "$btc_addr" ]; then
                "$SCRIPT_DIR/create-vault.sh" --owner "$owner" --amount "$amount" --duration "$duration" --btc-address "$btc_addr"
            else
                log_error "All fields are required"
            fi
            pause_for_input
            ;;
        6)
            read -p "Enter vault ID: " vault_id
            if [ -n "$vault_id" ]; then
                "$SCRIPT_DIR/claim-yield.sh" --vault-id "$vault_id"
            else
                log_error "Vault ID is required"
            fi
            pause_for_input
            ;;
        7)
            read -p "Enter vault ID: " vault_id
            if [ -n "$vault_id" ]; then
                "$SCRIPT_DIR/request-withdrawal.sh" --vault-id "$vault_id"
            else
                log_error "Vault ID is required"
            fi
            pause_for_input
            ;;
        8)
            read -p "Enter withdrawal ID: " withdrawal_id
            echo "Available signers: bob, charlie, david"
            read -p "Enter signer name: " signer
            if [ -n "$withdrawal_id" ] && [ -n "$signer" ]; then
                "$SCRIPT_DIR/approve-withdrawal.sh" --withdrawal-id "$withdrawal_id" --signer "$signer"
            else
                log_error "Both withdrawal ID and signer are required"
            fi
            pause_for_input
            ;;
        9)
            read -p "Enter withdrawal ID: " withdrawal_id
            read -p "Enter vault ID: " vault_id
            if [ -n "$withdrawal_id" ] && [ -n "$vault_id" ]; then
                "$SCRIPT_DIR/execute-withdrawal.sh" --withdrawal-id "$withdrawal_id" --vault-id "$vault_id"
            else
                log_error "Both withdrawal ID and vault ID are required"
            fi
            pause_for_input
            ;;
        [Aa])
            "$SCRIPT_DIR/pause.sh"
            pause_for_input
            ;;
        [Bb])
            "$SCRIPT_DIR/resume.sh"
            pause_for_input
            ;;
        [Cc])
            read -p "Enter new yield rate (basis points, e.g., 1000 = 10%): " rate
            if [ -n "$rate" ]; then
                "$SCRIPT_DIR/update-yield-rate.sh" --rate "$rate"
            else
                log_error "Yield rate is required"
            fi
            pause_for_input
            ;;
        0)
            log_info "Goodbye!"
            exit 0
            ;;
        *)
            log_error "Invalid option. Please try again."
            pause_for_input
            ;;
    esac
done
