import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Cannot add memory to inactive vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "bloom-vault",
        "delete-vault",
        [types.uint(1)],
        wallet_1.address
      ),
      Tx.contractCall(
        "bloom-vault",
        "add-memory",
        [
          types.uint(1),
          types.utf8("Should fail"),
          types.uint(1630454400),
          types.none()
        ],
        wallet_1.address
      )
    ]);
    
    block.receipts[1].result.expectErr(105);
  }
});

Clarinet.test({
  name: "Can reactivate deleted vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "bloom-vault",
        "delete-vault",
        [types.uint(1)],
        wallet_1.address
      ),
      Tx.contractCall(
        "bloom-vault",
        "reactivate-vault",
        [types.uint(1)],
        wallet_1.address
      )
    ]);
    
    block.receipts[1].result.expectOk().expectBool(true);
  }
});
