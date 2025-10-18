#!/bin/bash
# Configuration file for Bitcoin Vault scripts

# Contract ID on Stellar Testnet
export CONTRACT_ID="CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA"

# Network
export NETWORK="testnet"

# Admin account
export ADMIN_KEY="alice"
export ADMIN_ADDRESS="GAF2PGFZ6YYX2NNFHL7VO7KMXZXSKMQXTXTQHQWZ3LXKU65AOPNTCRYI"

# Multi-sig signers
export SIGNER1_KEY="bob"
export SIGNER1_ADDRESS="GCQQOFCV7USOB2PAWSPPGWV4DBIMH3EKGRDGAPKGESHX4HVPSO7OC4LQ"

export SIGNER2_KEY="charlie"
export SIGNER2_ADDRESS="GBPTUJHVSQGOL3HAFXO2TXDPCSGPGQXJOUT2PWCSQHYCUBQXKAOQS6SB"

export SIGNER3_KEY="david"
export SIGNER3_ADDRESS="GBAYS3MNITYQG7PHKZVSUKGZSOFTU2TKGHZPJK7A4SMRB5TSIXARGCUU"

# Contract parameters
export MIN_LOCK_DURATION=86400        # 1 day
export MAX_LOCK_DURATION=31536000     # 1 year
export DEPOSIT_FEE=50                 # 0.5%
export WITHDRAWAL_FEE=50              # 0.5%
export YIELD_RATE=1000                # 10% APY
export REQUIRED_APPROVALS=2           # 2-of-3 multi-sig

# Common lock durations (in seconds)
export ONE_DAY=86400
export ONE_WEEK=604800
export ONE_MONTH=2592000
export THREE_MONTHS=7776000
export SIX_MONTHS=15552000
export ONE_YEAR=31536000

# Common BTC amounts (in satoshis)
export POINT_ONE_BTC=10000000
export HALF_BTC=50000000
export ONE_BTC=100000000
export TWO_BTC=200000000
export FIVE_BTC=500000000

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Print configuration
print_config() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Bitcoin Vault Contract Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Contract ID: $CONTRACT_ID"
    echo "Network:     $NETWORK"
    echo "Admin:       $ADMIN_KEY ($ADMIN_ADDRESS)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Export functions for use in other scripts
export -f log_info
export -f log_success
export -f log_error
export -f log_warning
export -f print_config
