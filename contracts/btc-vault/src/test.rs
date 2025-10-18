#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::{Address as _, Ledger}, vec, Address, Env, String};

fn create_test_env() -> (Env, Address, Vec<Address>) {
    let env = Env::default();
    env.mock_all_auths();

    let admin = Address::generate(&env);
    let signer1 = Address::generate(&env);
    let signer2 = Address::generate(&env);
    let signer3 = Address::generate(&env);
    
    let signers = vec![&env, signer1.clone(), signer2.clone(), signer3.clone()];

    (env, admin, signers)
}

#[test]
fn test_initialize() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(
        &admin,
        &86400,      // min 1 day
        &31536000,   // max 1 year
        &50,         // 0.5% deposit fee
        &50,         // 0.5% withdrawal fee
        &1000,       // 10% annual yield
        &signers,
        &2,          // require 2 approvals
    );
}

#[test]
#[should_panic(expected = "AlreadyInitialized")]
fn test_initialize_twice() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);
    
    // Try to initialize again - should panic
    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);
}

#[test]
fn test_create_vault() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(
        &user,
        &100_000_000, // 1 BTC in satoshis
        &86400,       // 1 day lock
        &btc_address,
    );

    assert_eq!(vault_id, 0);

    // Verify vault was created
    let vault = client.get_vault(&vault_id);
    assert_eq!(vault.amount, 99_500_000); // After 0.5% fee
}

#[test]
#[should_panic(expected = "InvalidAmount")]
fn test_create_vault_invalid_amount() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    client.create_vault(&user, &0, &86400, &btc_address);
}

#[test]
#[should_panic(expected = "InvalidDuration")]
fn test_create_vault_invalid_duration() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    // Try to lock for less than minimum duration
    client.create_vault(&user, &100_000_000, &100, &btc_address);
}

#[test]
#[should_panic(expected = "InvalidBtcAddress")]
fn test_create_vault_invalid_btc_address() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "invalid");
    
    client.create_vault(&user, &100_000_000, &86400, &btc_address);
}

#[test]
fn test_claim_yield() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    // Advance time by 30 days
    env.ledger().with_mut(|li| {
        li.timestamp = li.timestamp + 2_592_000; // 30 days in seconds
    });

    let yield_claimed = client.claim_yield(&vault_id);
    assert!(yield_claimed > 0);
}

#[test]
#[should_panic(expected = "VaultLocked")]
fn test_request_withdrawal_before_unlock() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    // Try to withdraw before lock expires
    client.request_withdrawal(&vault_id, &btc_address);
}

#[test]
fn test_request_withdrawal_after_unlock() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    // Advance time past lock duration
    env.ledger().with_mut(|li| {
        li.timestamp = li.timestamp + 86401; // 1 day + 1 second
    });

    let _withdrawal_id = client.request_withdrawal(&vault_id, &btc_address);
}

#[test]
fn test_multi_sig_approval_and_execution() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    // Advance time past lock duration
    env.ledger().with_mut(|li| {
        li.timestamp = li.timestamp + 86401;
    });

    let withdrawal_id = client.request_withdrawal(&vault_id, &btc_address);

    // Get signers
    let signer1 = signers.get(0).unwrap();
    let signer2 = signers.get(1).unwrap();

    // First approval
    client.approve_withdrawal(&signer1, &withdrawal_id);

    // Second approval
    client.approve_withdrawal(&signer2, &withdrawal_id);

    // Now execute withdrawal
    client.execute_withdrawal(&withdrawal_id, &vault_id);
}

#[test]
#[should_panic(expected = "WithdrawalNotApproved")]
fn test_execute_withdrawal_without_enough_approvals() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    // Advance time
    env.ledger().with_mut(|li| {
        li.timestamp = li.timestamp + 86401;
    });

    let withdrawal_id = client.request_withdrawal(&vault_id, &btc_address);

    // Only one approval (need 2)
    let signer1 = signers.get(0).unwrap();
    client.approve_withdrawal(&signer1, &withdrawal_id);

    // Try to execute without enough approvals
    client.execute_withdrawal(&withdrawal_id, &vault_id);
}

#[test]
#[should_panic(expected = "AlreadyApproved")]
fn test_duplicate_approval() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    let vault_id = client.create_vault(&user, &100_000_000, &86400, &btc_address);

    env.ledger().with_mut(|li| {
        li.timestamp = li.timestamp + 86401;
    });

    let withdrawal_id = client.request_withdrawal(&vault_id, &btc_address);

    let signer1 = signers.get(0).unwrap();
    client.approve_withdrawal(&signer1, &withdrawal_id);
    
    // Try to approve again - should panic
    client.approve_withdrawal(&signer1, &withdrawal_id);
}

#[test]
fn test_pause_and_resume() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    // Pause contract
    client.pause();

    let config = client.get_config();
    assert!(config.paused);

    // Resume contract
    client.resume();

    let config2 = client.get_config();
    assert!(!config2.paused);
}

#[test]
#[should_panic(expected = "ContractPaused")]
fn test_create_vault_when_paused() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    // Pause contract
    client.pause();

    // Try to create vault while paused
    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    client.create_vault(&user, &100_000_000, &86400, &btc_address);
}

#[test]
fn test_update_yield_rate() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let config_before = client.get_config();
    assert_eq!(config_before.yield_rate, 1000);

    // Update yield rate
    client.update_yield_rate(&2000); // 20%

    let config_after = client.get_config();
    assert_eq!(config_after.yield_rate, 2000);
}

#[test]
fn test_get_user_vaults() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    // Create multiple vaults
    client.create_vault(&user, &100_000_000, &86400, &btc_address);
    client.create_vault(&user, &200_000_000, &172800, &btc_address);
    client.create_vault(&user, &300_000_000, &259200, &btc_address);

    let user_vaults = client.get_user_vaults(&user);
    assert_eq!(user_vaults.len(), 3);
}

#[test]
fn test_get_stats() {
    let (env, admin, signers) = create_test_env();
    let contract_id = env.register(BtcVaultContract, ());
    let client = BtcVaultContractClient::new(&env, &contract_id);

    client.initialize(&admin, &86400, &31536000, &50, &50, &1000, &signers, &2);

    let user = Address::generate(&env);
    let btc_address = String::from_str(&env, "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");
    
    client.create_vault(&user, &100_000_000, &86400, &btc_address);
    client.create_vault(&user, &200_000_000, &172800, &btc_address);

    let (total_locked, _total_yield, vault_count, withdrawal_count) = client.get_stats();
    
    assert!(total_locked > 0);
    assert_eq!(vault_count, 2);
    assert_eq!(withdrawal_count, 0);
}
