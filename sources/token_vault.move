#[lint_allow(self_transfer)]
#[allow(unused_use)]
module token_vault::token_vault {
    use std::ascii::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::balance::{Self, Balance};
    use sui::package;
    use sui::dynamic_object_field as ofield;
    use sui::pay;
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::vec_map;
    use sui::object::{Self, ID, UID};

    // Token struct definition
    public struct Token has store, drop {
        value: u64,
    }

    // Request struct definition
    public struct Request has store, drop {
        amount: u64,
        approved: bool,
    }

    // Vault struct definition
    public struct Vault has store, drop {
        tokens: vector<Token>,
        requests: vector<Request>,
        admin: address,
    }

    // Initializes the vault with an admin
    public fun init_vault(admin: address): Vault {
        Vault {
            tokens: vector::empty<Token>(),
            requests: vector::empty<Request>(),
            admin: admin,
        }
    }

    // User requests tokens
    public fun request_tokens(vault: &mut Vault, amount: u64) {
        let request:Request = Request {
            amount,
            approved: false,
        };
        vector::push_back(&mut vault.requests, request);
    }

    // Admin approves a token request
    public fun approve_request(vault: &mut Vault, request_id: u64, admin: address) {
        assert!(admin == vault.admin, 1);
        assert!(request_id < vector::length(&vault.requests), 2);
        let request: &mut Request = &mut vault.requests[request_id];
        request.approved = true;
    }

    // User mints approved tokens
    public fun mint_tokens(vault: &mut Vault, request_id: u64) {
        assert!(request_id < vector::length(&vault.requests), 2);
        let request: &Request = &mut vault.requests[request_id];
        assert!(request.approved, 3);
        let token: Token = Token {
            value: request.amount,
        };
        vector::push_back(&mut vault.tokens, token);
    }

    #[test]
    public fun test_vault(ctx: &mut TxContext ) {
        // Create a mock transaction context
        // let ctx: &mut TxContext  = test_scenario::ctx(scenario);
        let admin:address = @0x1;

        // Initialize the vault
        let mut vault: Vault = init_vault(admin);

        // User requests tokens
        request_tokens(&mut vault, 100);

        // Verify the request is created and not approved
        let request_id = 0;
        assert!(vector::length(&vault.requests) == 1, 100);
        assert!(vault.requests[request_id].amount == 100, 101);
        assert!(!vault.requests[request_id].approved, 102);

        // Admin approves the request
        approve_request(&mut vault, request_id, admin);

        // Verify the request is approved
        assert!(vault.requests[request_id].approved, 103);

        // User mints approved tokens
        mint_tokens(&mut vault, request_id);

        // Verify the token is minted
        assert!(vector::length(&vault.tokens) == 1, 104);
        assert!(vault.tokens[0].value == 100, 105);
        ();
    }
}
