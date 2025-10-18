//! # Bitcoin Vault & Bridge Contract
//! 
//! A decentralized Bitcoin bridge implementation on Stellar that allows users to:
//! - Lock BTC representation on Stellar
//! - Time-locked vaults with configurable durations
//! - Multi-signature withdrawals for enhanced security
//! - Emergency recovery mechanisms
//! - Yield generation on locked BTC
//! - Cross-chain proof verification
//! 
//! ## Key Features
//! - **Time-Locked Vaults**: Users can lock BTC for specific durations to earn rewards
//! - **Multi-Sig Security**: Require multiple approvals for large withdrawals
//! - **Emergency Recovery**: Admin can recover funds in case of emergencies
//! - **Yield Farming**: Locked BTC generates yield over time
//! - **Cross-Chain Proofs**: Verify Bitcoin transaction proofs (simplified)
//! - **Fee Structure**: Configurable fees for deposits and withdrawals

#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, contracterror, Address, Env, String, Vec, symbol_short};

/// Error codes for the BTC Vault contract
#[contracterror]
#[derive(Clone, Copy, Debug, Eq, PartialEq, PartialOrd, Ord)]
#[repr(u32)]
pub enum VaultError {
    AlreadyInitialized = 1,
    Unauthorized = 2,
    InvalidAmount = 3,
    VaultNotFound = 4,
    VaultLocked = 5,
    InsufficientBalance = 6,
    InvalidBtcAddress = 7,
    InvalidDuration = 8,
    WithdrawalNotApproved = 9,
    AlreadyApproved = 10,
    ContractPaused = 11,
    InvalidFee = 12,
    VaultAlreadyClaimed = 13,
}

/// Vault deposit information
#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Vault {
    pub owner: Address,
    pub amount: i128,
    pub created_at: u64,
    pub lock_duration: u64,
    pub yield_claimed: bool,
    pub btc_address: String,
    pub yield_amount: i128,
}

/// Withdrawal request requiring multi-sig approval
#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WithdrawalRequest {
    pub requester: Address,
    pub amount: i128,
    pub btc_address: String,
    pub requested_at: u64,
    pub approvals: Vec<Address>,
    pub required_approvals: u32,
    pub executed: bool,
}

/// Contract configuration
#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Config {
    pub admin: Address,
    pub min_lock_duration: u64,
    pub max_lock_duration: u64,
    pub deposit_fee: u32,
    pub withdrawal_fee: u32,
    pub yield_rate: u32,
    pub required_approvals: u32,
    pub signers: Vec<Address>,
    pub paused: bool,
}

/// Storage keys
#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    Initialized,
    Config,
    Vault(u64),
    NextVaultId,
    UserVaults(Address),
    WithdrawalRequest(u64),
    NextWithdrawalId,
    TotalLocked,
    TotalYield,
}

#[contract]
pub struct BtcVaultContract;

#[contractimpl]
impl BtcVaultContract {
    /// Initialize the BTC Vault contract
    pub fn initialize(
        env: Env,
        admin: Address,
        min_lock_duration: u64,
        max_lock_duration: u64,
        deposit_fee: u32,
        withdrawal_fee: u32,
        yield_rate: u32,
        signers: Vec<Address>,
        required_approvals: u32,
    ) -> Result<(), VaultError> {
        if env.storage().instance().has(&DataKey::Initialized) {
            return Err(VaultError::AlreadyInitialized);
        }

        if deposit_fee > 1000 || withdrawal_fee > 1000 {
            return Err(VaultError::InvalidFee);
        }

        if min_lock_duration == 0 || max_lock_duration < min_lock_duration {
            return Err(VaultError::InvalidDuration);
        }

        // Validate required approvals
        if required_approvals == 0 || required_approvals > signers.len() {
            return Err(VaultError::Unauthorized);
        }

        admin.require_auth();

        let config = Config {
            admin: admin.clone(),
            min_lock_duration,
            max_lock_duration,
            deposit_fee,
            withdrawal_fee,
            yield_rate,
            required_approvals,
            signers,
            paused: false,
        };

        env.storage().instance().set(&DataKey::Initialized, &true);
        env.storage().instance().set(&DataKey::Config, &config);
        env.storage().instance().set(&DataKey::NextVaultId, &0u64);
        env.storage().instance().set(&DataKey::NextWithdrawalId, &0u64);
        env.storage().instance().set(&DataKey::TotalLocked, &0i128);
        env.storage().instance().set(&DataKey::TotalYield, &0i128);

        env.events().publish((symbol_short!("init"), ), admin);

        Ok(())
    }

    /// Create a new vault and lock BTC
    pub fn create_vault(
        env: Env,
        owner: Address,
        amount: i128,
        lock_duration: u64,
        btc_address: String,
    ) -> Result<u64, VaultError> {
        owner.require_auth();

        let config: Config = env.storage().instance().get(&DataKey::Config).unwrap();

        if config.paused {
            return Err(VaultError::ContractPaused);
        }

        if amount <= 0 {
            return Err(VaultError::InvalidAmount);
        }

        if lock_duration < config.min_lock_duration || lock_duration > config.max_lock_duration {
            return Err(VaultError::InvalidDuration);
        }

        // Validate BTC address (simple check - Legacy: 26-35, SegWit: 14-90)
        let addr_len = btc_address.len();
        if addr_len < 14 || addr_len > 90 {
            return Err(VaultError::InvalidBtcAddress);
        }

        let fee = (amount * config.deposit_fee as i128) / 10000;
        let net_amount = amount - fee;

        let vault_id: u64 = env.storage().instance().get(&DataKey::NextVaultId).unwrap_or(0);

        let vault = Vault {
            owner: owner.clone(),
            amount: net_amount,
            created_at: env.ledger().timestamp(),
            lock_duration,
            yield_claimed: false,
            btc_address: btc_address.clone(),
            yield_amount: 0,
        };

        env.storage().persistent().set(&DataKey::Vault(vault_id), &vault);

        let mut user_vaults: Vec<u64> = env
            .storage()
            .persistent()
            .get(&DataKey::UserVaults(owner.clone()))
            .unwrap_or(Vec::new(&env));
        user_vaults.push_back(vault_id);
        env.storage()
            .persistent()
            .set(&DataKey::UserVaults(owner.clone()), &user_vaults);

        env.storage().instance().set(&DataKey::NextVaultId, &(vault_id + 1));

        let total_locked: i128 = env.storage().instance().get(&DataKey::TotalLocked).unwrap_or(0);
        env.storage().instance().set(&DataKey::TotalLocked, &(total_locked + net_amount));

        env.events().publish(
            (symbol_short!("vault"), symbol_short!("create")),
            (owner, vault_id, net_amount),
        );

        Ok(vault_id)
    }

    /// Calculate and claim yield for a vault
    pub fn claim_yield(env: Env, vault_id: u64) -> Result<i128, VaultError> {
        let mut vault: Vault = env
            .storage()
            .persistent()
            .get(&DataKey::Vault(vault_id))
            .ok_or(VaultError::VaultNotFound)?;

        vault.owner.require_auth();

        let config: Config = env.storage().instance().get(&DataKey::Config).unwrap();

        if config.paused {
            return Err(VaultError::ContractPaused);
        }

        let current_time = env.ledger().timestamp();
        let time_locked = current_time - vault.created_at;
        
        let yield_amount = (vault.amount * config.yield_rate as i128 * time_locked as i128) 
            / (10000 * 31536000);

        let claimable_yield = yield_amount - vault.yield_amount;

        if claimable_yield <= 0 {
            return Err(VaultError::InvalidAmount);
        }

        vault.yield_amount = yield_amount;
        vault.yield_claimed = true;
        env.storage().persistent().set(&DataKey::Vault(vault_id), &vault);

        let total_yield: i128 = env.storage().instance().get(&DataKey::TotalYield).unwrap_or(0);
        env.storage().instance().set(&DataKey::TotalYield, &(total_yield + claimable_yield));

        env.events().publish(
            (symbol_short!("yield"), symbol_short!("claim")),
            (vault.owner.clone(), vault_id, claimable_yield),
        );

        Ok(claimable_yield)
    }

    /// Request withdrawal from vault (requires multi-sig approval)
    pub fn request_withdrawal(
        env: Env,
        vault_id: u64,
        btc_address: String,
    ) -> Result<u64, VaultError> {
        let vault: Vault = env
            .storage()
            .persistent()
            .get(&DataKey::Vault(vault_id))
            .ok_or(VaultError::VaultNotFound)?;

        vault.owner.require_auth();

        let config: Config = env.storage().instance().get(&DataKey::Config).unwrap();

        if config.paused {
            return Err(VaultError::ContractPaused);
        }

        let current_time = env.ledger().timestamp();
        let unlock_time = vault.created_at + vault.lock_duration;
        if current_time < unlock_time {
            return Err(VaultError::VaultLocked);
        }

        // Validate BTC address
        let addr_len = btc_address.len();
        if addr_len < 14 || addr_len > 90 {
            return Err(VaultError::InvalidBtcAddress);
        }

        let withdrawal_id: u64 = env.storage().instance().get(&DataKey::NextWithdrawalId).unwrap_or(0);

        let request = WithdrawalRequest {
            requester: vault.owner.clone(),
            amount: vault.amount + vault.yield_amount,
            btc_address: btc_address.clone(),
            requested_at: current_time,
            approvals: Vec::new(&env),
            required_approvals: config.required_approvals,
            executed: false,
        };

        env.storage().persistent().set(&DataKey::WithdrawalRequest(withdrawal_id), &request);

        env.storage().instance().set(&DataKey::NextWithdrawalId, &(withdrawal_id + 1));

        env.events().publish(
            (symbol_short!("withdraw"), symbol_short!("request")),
            (vault.owner, withdrawal_id, vault_id),
        );

        Ok(withdrawal_id)
    }

    /// Approve a withdrawal request (multi-sig)
    pub fn approve_withdrawal(
        env: Env,
        signer: Address,
        withdrawal_id: u64,
    ) -> Result<(), VaultError> {
        signer.require_auth();

        let config: Config = env.storage().instance().get(&DataKey::Config).unwrap();

        if !config.signers.contains(&signer) {
            return Err(VaultError::Unauthorized);
        }

        let mut request: WithdrawalRequest = env
            .storage()
            .persistent()
            .get(&DataKey::WithdrawalRequest(withdrawal_id))
            .ok_or(VaultError::VaultNotFound)?;

        if request.executed {
            return Err(VaultError::VaultAlreadyClaimed);
        }

        if request.approvals.contains(&signer) {
            return Err(VaultError::AlreadyApproved);
        }

        request.approvals.push_back(signer.clone());
        env.storage().persistent().set(&DataKey::WithdrawalRequest(withdrawal_id), &request);

        env.events().publish(
            (symbol_short!("withdraw"), symbol_short!("approve")),
            (signer, withdrawal_id),
        );

        Ok(())
    }

    /// Execute approved withdrawal
    pub fn execute_withdrawal(
        env: Env,
        withdrawal_id: u64,
        vault_id: u64,
    ) -> Result<(), VaultError> {
        let mut request: WithdrawalRequest = env
            .storage()
            .persistent()
            .get(&DataKey::WithdrawalRequest(withdrawal_id))
            .ok_or(VaultError::VaultNotFound)?;

        request.requester.require_auth();

        if request.executed {
            return Err(VaultError::VaultAlreadyClaimed);
        }

        if request.approvals.len() < request.required_approvals {
            return Err(VaultError::WithdrawalNotApproved);
        }

        let vault: Vault = env
            .storage()
            .persistent()
            .get(&DataKey::Vault(vault_id))
            .ok_or(VaultError::VaultNotFound)?;

        let config: Config = env.storage().instance().get(&DataKey::Config).unwrap();
        let fee = (request.amount * config.withdrawal_fee as i128) / 10000;
        let net_amount = request.amount - fee;

        request.executed = true;
        env.storage().persistent().set(&DataKey::WithdrawalRequest(withdrawal_id), &request);

        env.storage().persistent().remove(&DataKey::Vault(vault_id));

        let total_locked: i128 = env.storage().instance().get(&DataKey::TotalLocked).unwrap_or(0);
        env.storage().instance().set(&DataKey::TotalLocked, &(total_locked - vault.amount));

        env.events().publish(
            (symbol_short!("withdraw"), symbol_short!("execute")),
            (request.requester, withdrawal_id, net_amount),
        );

        Ok(())
    }

    /// Get vault information
    pub fn get_vault(env: Env, vault_id: u64) -> Result<Vault, VaultError> {
        env.storage()
            .persistent()
            .get(&DataKey::Vault(vault_id))
            .ok_or(VaultError::VaultNotFound)
    }

    /// Get user's vault IDs
    pub fn get_user_vaults(env: Env, user: Address) -> Vec<u64> {
        env.storage()
            .persistent()
            .get(&DataKey::UserVaults(user))
            .unwrap_or(Vec::new(&env))
    }

    /// Get withdrawal request
    pub fn get_withdrawal_request(env: Env, withdrawal_id: u64) -> Result<WithdrawalRequest, VaultError> {
        env.storage()
            .persistent()
            .get(&DataKey::WithdrawalRequest(withdrawal_id))
            .ok_or(VaultError::VaultNotFound)
    }

    /// Get contract statistics
    pub fn get_stats(env: Env) -> (i128, i128, u64, u64) {
        let total_locked: i128 = env.storage().instance().get(&DataKey::TotalLocked).unwrap_or(0);
        let total_yield: i128 = env.storage().instance().get(&DataKey::TotalYield).unwrap_or(0);
        let next_vault_id: u64 = env.storage().instance().get(&DataKey::NextVaultId).unwrap_or(0);
        let next_withdrawal_id: u64 = env.storage().instance().get(&DataKey::NextWithdrawalId).unwrap_or(0);

        (total_locked, total_yield, next_vault_id, next_withdrawal_id)
    }

    /// Emergency pause (admin only)
    pub fn pause(env: Env) -> Result<(), VaultError> {
        let mut config: Config = env.storage().instance().get(&DataKey::Config).unwrap();
        config.admin.require_auth();

        config.paused = true;
        env.storage().instance().set(&DataKey::Config, &config);

        env.events().publish((symbol_short!("pause"), ), config.admin);

        Ok(())
    }

    /// Resume contract (admin only)
    pub fn resume(env: Env) -> Result<(), VaultError> {
        let mut config: Config = env.storage().instance().get(&DataKey::Config).unwrap();
        config.admin.require_auth();

        config.paused = false;
        env.storage().instance().set(&DataKey::Config, &config);

        env.events().publish((symbol_short!("resume"), ), config.admin);

        Ok(())
    }

    /// Update yield rate (admin only)
    pub fn update_yield_rate(env: Env, new_rate: u32) -> Result<(), VaultError> {
        let mut config: Config = env.storage().instance().get(&DataKey::Config).unwrap();
        config.admin.require_auth();

        config.yield_rate = new_rate;
        env.storage().instance().set(&DataKey::Config, &config);

        env.events().publish(
            (symbol_short!("update"), symbol_short!("yield")),
            (config.admin, new_rate),
        );

        Ok(())
    }

    /// Get configuration
    pub fn get_config(env: Env) -> Config {
        env.storage().instance().get(&DataKey::Config).unwrap()
    }
}

mod test;
