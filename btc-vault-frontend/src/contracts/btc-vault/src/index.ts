import { Buffer } from "buffer";
import { Address } from '@stellar/stellar-sdk';
import {
  AssembledTransaction,
  Client as ContractClient,
  ClientOptions as ContractClientOptions,
  MethodOptions,
  Result,
  Spec as ContractSpec,
} from '@stellar/stellar-sdk/contract';
import type {
  u32,
  i32,
  u64,
  i64,
  u128,
  i128,
  u256,
  i256,
  Option,
  Typepoint,
  Duration,
} from '@stellar/stellar-sdk/contract';
export * from '@stellar/stellar-sdk'
export * as contract from '@stellar/stellar-sdk/contract'
export * as rpc from '@stellar/stellar-sdk/rpc'

if (typeof window !== 'undefined') {
  //@ts-ignore Buffer exists
  window.Buffer = window.Buffer || Buffer;
}


export const networks = {
  testnet: {
    networkPassphrase: "Test SDF Network ; September 2015",
    contractId: "CAT6TSOXE4KSQK2HEN7PDDZ5ACLRCIBZPHLHALWUINRSWQTN5RTWLLKA",
  }
} as const

/**
 * Error codes for the BTC Vault contract
 */
export const VaultError = {
  1: {message:"AlreadyInitialized"},
  2: {message:"Unauthorized"},
  3: {message:"InvalidAmount"},
  4: {message:"VaultNotFound"},
  5: {message:"VaultLocked"},
  6: {message:"InsufficientBalance"},
  7: {message:"InvalidBtcAddress"},
  8: {message:"InvalidDuration"},
  9: {message:"WithdrawalNotApproved"},
  10: {message:"AlreadyApproved"},
  11: {message:"ContractPaused"},
  12: {message:"InvalidFee"},
  13: {message:"VaultAlreadyClaimed"}
}


/**
 * Vault deposit information
 */
export interface Vault {
  amount: i128;
  btc_address: string;
  created_at: u64;
  lock_duration: u64;
  owner: string;
  yield_amount: i128;
  yield_claimed: boolean;
}


/**
 * Withdrawal request requiring multi-sig approval
 */
export interface WithdrawalRequest {
  amount: i128;
  approvals: Array<string>;
  btc_address: string;
  executed: boolean;
  requested_at: u64;
  requester: string;
  required_approvals: u32;
}


/**
 * Contract configuration
 */
export interface Config {
  admin: string;
  deposit_fee: u32;
  max_lock_duration: u64;
  min_lock_duration: u64;
  paused: boolean;
  required_approvals: u32;
  signers: Array<string>;
  withdrawal_fee: u32;
  yield_rate: u32;
}

/**
 * Storage keys
 */
export type DataKey = {tag: "Initialized", values: void} | {tag: "Config", values: void} | {tag: "Vault", values: readonly [u64]} | {tag: "NextVaultId", values: void} | {tag: "UserVaults", values: readonly [string]} | {tag: "WithdrawalRequest", values: readonly [u64]} | {tag: "NextWithdrawalId", values: void} | {tag: "TotalLocked", values: void} | {tag: "TotalYield", values: void};

export interface Client {
  /**
   * Construct and simulate a initialize transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Initialize the BTC Vault contract
   */
  initialize: ({admin, min_lock_duration, max_lock_duration, deposit_fee, withdrawal_fee, yield_rate, signers, required_approvals}: {admin: string, min_lock_duration: u64, max_lock_duration: u64, deposit_fee: u32, withdrawal_fee: u32, yield_rate: u32, signers: Array<string>, required_approvals: u32}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a create_vault transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Create a new vault and lock BTC
   */
  create_vault: ({owner, amount, lock_duration, btc_address}: {owner: string, amount: i128, lock_duration: u64, btc_address: string}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<u64>>>

  /**
   * Construct and simulate a claim_yield transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Calculate and claim yield for a vault
   */
  claim_yield: ({vault_id}: {vault_id: u64}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<i128>>>

  /**
   * Construct and simulate a request_withdrawal transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Request withdrawal from vault (requires multi-sig approval)
   */
  request_withdrawal: ({vault_id, btc_address}: {vault_id: u64, btc_address: string}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<u64>>>

  /**
   * Construct and simulate a approve_withdrawal transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Approve a withdrawal request (multi-sig)
   */
  approve_withdrawal: ({signer, withdrawal_id}: {signer: string, withdrawal_id: u64}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a execute_withdrawal transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Execute approved withdrawal
   */
  execute_withdrawal: ({withdrawal_id, vault_id}: {withdrawal_id: u64, vault_id: u64}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a get_vault transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Get vault information
   */
  get_vault: ({vault_id}: {vault_id: u64}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<Vault>>>

  /**
   * Construct and simulate a get_user_vaults transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Get user's vault IDs
   */
  get_user_vaults: ({user}: {user: string}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Array<u64>>>

  /**
   * Construct and simulate a get_withdrawal_request transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Get withdrawal request
   */
  get_withdrawal_request: ({withdrawal_id}: {withdrawal_id: u64}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<WithdrawalRequest>>>

  /**
   * Construct and simulate a get_stats transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Get contract statistics
   */
  get_stats: (options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<readonly [i128, i128, u64, u64]>>

  /**
   * Construct and simulate a pause transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Emergency pause (admin only)
   */
  pause: (options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a resume transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Resume contract (admin only)
   */
  resume: (options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a update_yield_rate transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Update yield rate (admin only)
   */
  update_yield_rate: ({new_rate}: {new_rate: u32}, options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Result<void>>>

  /**
   * Construct and simulate a get_config transaction. Returns an `AssembledTransaction` object which will have a `result` field containing the result of the simulation. If this transaction changes contract state, you will need to call `signAndSend()` on the returned object.
   * Get configuration
   */
  get_config: (options?: {
    /**
     * The fee to pay for the transaction. Default: BASE_FEE
     */
    fee?: number;

    /**
     * The maximum amount of time to wait for the transaction to complete. Default: DEFAULT_TIMEOUT
     */
    timeoutInSeconds?: number;

    /**
     * Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default: true
     */
    simulate?: boolean;
  }) => Promise<AssembledTransaction<Config>>

}
export class Client extends ContractClient {
  static async deploy<T = Client>(
    /** Options for initializing a Client as well as for calling a method, with extras specific to deploying. */
    options: MethodOptions &
      Omit<ContractClientOptions, "contractId"> & {
        /** The hash of the Wasm blob, which must already be installed on-chain. */
        wasmHash: Buffer | string;
        /** Salt used to generate the contract's ID. Passed through to {@link Operation.createCustomContract}. Default: random. */
        salt?: Buffer | Uint8Array;
        /** The format used to decode `wasmHash`, if it's provided as a string. */
        format?: "hex" | "base64";
      }
  ): Promise<AssembledTransaction<T>> {
    return ContractClient.deploy(null, options)
  }
  constructor(public readonly options: ContractClientOptions) {
    super(
      new ContractSpec([ "AAAABAAAACZFcnJvciBjb2RlcyBmb3IgdGhlIEJUQyBWYXVsdCBjb250cmFjdAAAAAAAAAAAAApWYXVsdEVycm9yAAAAAAANAAAAAAAAABJBbHJlYWR5SW5pdGlhbGl6ZWQAAAAAAAEAAAAAAAAADFVuYXV0aG9yaXplZAAAAAIAAAAAAAAADUludmFsaWRBbW91bnQAAAAAAAADAAAAAAAAAA1WYXVsdE5vdEZvdW5kAAAAAAAABAAAAAAAAAALVmF1bHRMb2NrZWQAAAAABQAAAAAAAAATSW5zdWZmaWNpZW50QmFsYW5jZQAAAAAGAAAAAAAAABFJbnZhbGlkQnRjQWRkcmVzcwAAAAAAAAcAAAAAAAAAD0ludmFsaWREdXJhdGlvbgAAAAAIAAAAAAAAABVXaXRoZHJhd2FsTm90QXBwcm92ZWQAAAAAAAAJAAAAAAAAAA9BbHJlYWR5QXBwcm92ZWQAAAAACgAAAAAAAAAOQ29udHJhY3RQYXVzZWQAAAAAAAsAAAAAAAAACkludmFsaWRGZWUAAAAAAAwAAAAAAAAAE1ZhdWx0QWxyZWFkeUNsYWltZWQAAAAADQ==",
        "AAAAAQAAABlWYXVsdCBkZXBvc2l0IGluZm9ybWF0aW9uAAAAAAAAAAAAAAVWYXVsdAAAAAAAAAcAAAAAAAAABmFtb3VudAAAAAAACwAAAAAAAAALYnRjX2FkZHJlc3MAAAAAEAAAAAAAAAAKY3JlYXRlZF9hdAAAAAAABgAAAAAAAAANbG9ja19kdXJhdGlvbgAAAAAAAAYAAAAAAAAABW93bmVyAAAAAAAAEwAAAAAAAAAMeWllbGRfYW1vdW50AAAACwAAAAAAAAANeWllbGRfY2xhaW1lZAAAAAAAAAE=",
        "AAAAAQAAAC9XaXRoZHJhd2FsIHJlcXVlc3QgcmVxdWlyaW5nIG11bHRpLXNpZyBhcHByb3ZhbAAAAAAAAAAAEVdpdGhkcmF3YWxSZXF1ZXN0AAAAAAAABwAAAAAAAAAGYW1vdW50AAAAAAALAAAAAAAAAAlhcHByb3ZhbHMAAAAAAAPqAAAAEwAAAAAAAAALYnRjX2FkZHJlc3MAAAAAEAAAAAAAAAAIZXhlY3V0ZWQAAAABAAAAAAAAAAxyZXF1ZXN0ZWRfYXQAAAAGAAAAAAAAAAlyZXF1ZXN0ZXIAAAAAAAATAAAAAAAAABJyZXF1aXJlZF9hcHByb3ZhbHMAAAAAAAQ=",
        "AAAAAQAAABZDb250cmFjdCBjb25maWd1cmF0aW9uAAAAAAAAAAAABkNvbmZpZwAAAAAACQAAAAAAAAAFYWRtaW4AAAAAAAATAAAAAAAAAAtkZXBvc2l0X2ZlZQAAAAAEAAAAAAAAABFtYXhfbG9ja19kdXJhdGlvbgAAAAAAAAYAAAAAAAAAEW1pbl9sb2NrX2R1cmF0aW9uAAAAAAAABgAAAAAAAAAGcGF1c2VkAAAAAAABAAAAAAAAABJyZXF1aXJlZF9hcHByb3ZhbHMAAAAAAAQAAAAAAAAAB3NpZ25lcnMAAAAD6gAAABMAAAAAAAAADndpdGhkcmF3YWxfZmVlAAAAAAAEAAAAAAAAAAp5aWVsZF9yYXRlAAAAAAAE",
        "AAAAAgAAAAxTdG9yYWdlIGtleXMAAAAAAAAAB0RhdGFLZXkAAAAACQAAAAAAAAAAAAAAC0luaXRpYWxpemVkAAAAAAAAAAAAAAAABkNvbmZpZwAAAAAAAQAAAAAAAAAFVmF1bHQAAAAAAAABAAAABgAAAAAAAAAAAAAAC05leHRWYXVsdElkAAAAAAEAAAAAAAAAClVzZXJWYXVsdHMAAAAAAAEAAAATAAAAAQAAAAAAAAARV2l0aGRyYXdhbFJlcXVlc3QAAAAAAAABAAAABgAAAAAAAAAAAAAAEE5leHRXaXRoZHJhd2FsSWQAAAAAAAAAAAAAAAtUb3RhbExvY2tlZAAAAAAAAAAAAAAAAApUb3RhbFlpZWxkAAA=",
        "AAAAAAAAACFJbml0aWFsaXplIHRoZSBCVEMgVmF1bHQgY29udHJhY3QAAAAAAAAKaW5pdGlhbGl6ZQAAAAAACAAAAAAAAAAFYWRtaW4AAAAAAAATAAAAAAAAABFtaW5fbG9ja19kdXJhdGlvbgAAAAAAAAYAAAAAAAAAEW1heF9sb2NrX2R1cmF0aW9uAAAAAAAABgAAAAAAAAALZGVwb3NpdF9mZWUAAAAABAAAAAAAAAAOd2l0aGRyYXdhbF9mZWUAAAAAAAQAAAAAAAAACnlpZWxkX3JhdGUAAAAAAAQAAAAAAAAAB3NpZ25lcnMAAAAD6gAAABMAAAAAAAAAEnJlcXVpcmVkX2FwcHJvdmFscwAAAAAABAAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAAB9DcmVhdGUgYSBuZXcgdmF1bHQgYW5kIGxvY2sgQlRDAAAAAAxjcmVhdGVfdmF1bHQAAAAEAAAAAAAAAAVvd25lcgAAAAAAABMAAAAAAAAABmFtb3VudAAAAAAACwAAAAAAAAANbG9ja19kdXJhdGlvbgAAAAAAAAYAAAAAAAAAC2J0Y19hZGRyZXNzAAAAABAAAAABAAAD6QAAAAYAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAACVDYWxjdWxhdGUgYW5kIGNsYWltIHlpZWxkIGZvciBhIHZhdWx0AAAAAAAAC2NsYWltX3lpZWxkAAAAAAEAAAAAAAAACHZhdWx0X2lkAAAABgAAAAEAAAPpAAAACwAAB9AAAAAKVmF1bHRFcnJvcgAA",
        "AAAAAAAAADtSZXF1ZXN0IHdpdGhkcmF3YWwgZnJvbSB2YXVsdCAocmVxdWlyZXMgbXVsdGktc2lnIGFwcHJvdmFsKQAAAAAScmVxdWVzdF93aXRoZHJhd2FsAAAAAAACAAAAAAAAAAh2YXVsdF9pZAAAAAYAAAAAAAAAC2J0Y19hZGRyZXNzAAAAABAAAAABAAAD6QAAAAYAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAAChBcHByb3ZlIGEgd2l0aGRyYXdhbCByZXF1ZXN0IChtdWx0aS1zaWcpAAAAEmFwcHJvdmVfd2l0aGRyYXdhbAAAAAAAAgAAAAAAAAAGc2lnbmVyAAAAAAATAAAAAAAAAA13aXRoZHJhd2FsX2lkAAAAAAAABgAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAABtFeGVjdXRlIGFwcHJvdmVkIHdpdGhkcmF3YWwAAAAAEmV4ZWN1dGVfd2l0aGRyYXdhbAAAAAAAAgAAAAAAAAANd2l0aGRyYXdhbF9pZAAAAAAAAAYAAAAAAAAACHZhdWx0X2lkAAAABgAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAABVHZXQgdmF1bHQgaW5mb3JtYXRpb24AAAAAAAAJZ2V0X3ZhdWx0AAAAAAAAAQAAAAAAAAAIdmF1bHRfaWQAAAAGAAAAAQAAA+kAAAfQAAAABVZhdWx0AAAAAAAH0AAAAApWYXVsdEVycm9yAAA=",
        "AAAAAAAAABRHZXQgdXNlcidzIHZhdWx0IElEcwAAAA9nZXRfdXNlcl92YXVsdHMAAAAAAQAAAAAAAAAEdXNlcgAAABMAAAABAAAD6gAAAAY=",
        "AAAAAAAAABZHZXQgd2l0aGRyYXdhbCByZXF1ZXN0AAAAAAAWZ2V0X3dpdGhkcmF3YWxfcmVxdWVzdAAAAAAAAQAAAAAAAAANd2l0aGRyYXdhbF9pZAAAAAAAAAYAAAABAAAD6QAAB9AAAAARV2l0aGRyYXdhbFJlcXVlc3QAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAABdHZXQgY29udHJhY3Qgc3RhdGlzdGljcwAAAAAJZ2V0X3N0YXRzAAAAAAAAAAAAAAEAAAPtAAAABAAAAAsAAAALAAAABgAAAAY=",
        "AAAAAAAAABxFbWVyZ2VuY3kgcGF1c2UgKGFkbWluIG9ubHkpAAAABXBhdXNlAAAAAAAAAAAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAABxSZXN1bWUgY29udHJhY3QgKGFkbWluIG9ubHkpAAAABnJlc3VtZQAAAAAAAAAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAAB5VcGRhdGUgeWllbGQgcmF0ZSAoYWRtaW4gb25seSkAAAAAABF1cGRhdGVfeWllbGRfcmF0ZQAAAAAAAAEAAAAAAAAACG5ld19yYXRlAAAABAAAAAEAAAPpAAAD7QAAAAAAAAfQAAAAClZhdWx0RXJyb3IAAA==",
        "AAAAAAAAABFHZXQgY29uZmlndXJhdGlvbgAAAAAAAApnZXRfY29uZmlnAAAAAAAAAAAAAQAAB9AAAAAGQ29uZmlnAAA=" ]),
      options
    )
  }
  public readonly fromJSON = {
    initialize: this.txFromJSON<Result<void>>,
        create_vault: this.txFromJSON<Result<u64>>,
        claim_yield: this.txFromJSON<Result<i128>>,
        request_withdrawal: this.txFromJSON<Result<u64>>,
        approve_withdrawal: this.txFromJSON<Result<void>>,
        execute_withdrawal: this.txFromJSON<Result<void>>,
        get_vault: this.txFromJSON<Result<Vault>>,
        get_user_vaults: this.txFromJSON<Array<u64>>,
        get_withdrawal_request: this.txFromJSON<Result<WithdrawalRequest>>,
        get_stats: this.txFromJSON<readonly [i128, i128, u64, u64]>,
        pause: this.txFromJSON<Result<void>>,
        resume: this.txFromJSON<Result<void>>,
        update_yield_rate: this.txFromJSON<Result<void>>,
        get_config: this.txFromJSON<Config>
  }
}