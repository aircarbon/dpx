### Workflow for launching the ACT token, creating multisig wallets for the Treasury and Team Vesting, creating vesting schedule with Hedgey, creating DAO with Tally.

Token Launch flow:
1. Create Treasury Multisig account (for Bill, Thom, Dom)
```
1. Go to safe.global
2. Connect with one of the admin's wallet
3. Click on "Create account", enter a name, select a network
4. Add signers and set voting threshold
5. Set voting threshold and create a wallet
6. Confirm transaction and create account
```

2. Deploy a token
```bash
source .env
TOKEN_NAME="ACT Test N" TOKEN_SYMBOL="ACT-Test-N" INITIAL_SUPPLY=0 \
  forge script script/Deploy.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --mnemonics "$MNEMONIC" \
  --mnemonic-indexes 0
```

3. Change the ownership to the Treasury Multisig address
```bash
source .env
cast send 0xTokenAddr \
  "transferOwnership(address)" \
  0xTreasuryMultisigAddr \
  --rpc-url sepolia \
  --mnemonic "$MNEMONIC" \
  --mnemonic-index 0
```

4. Min to 1b tokens to the Treasury Multising address
```
1. Go to safe.global
2. Click on "New transaction" button -> "Transaction builder"
3. Enter ACT token's address (the proxy address!)
4. Enter ABI (copy from the ./out/ACT.sol/ACT.json) - just the "abi" value (the array)
5. Select "mint" method
6. Enter Treasury Multisig address (created in step 1)
7. Enter amount: 1000000000000000000000000000
8. Click "Add new transaction" -> "Create Batch" -> "Send Batch", then Execute or Sign
*9. If you need more than one signer, connect to the safe.global from another treasury admin account and execute the transaction
10. After transaction is mined and indexed, you should see 1b tokens in the "Assets" tab
```

5. Deploy governor & connect to Tally
```
1. Make sure you have Governor specific environment variables provided in .env file
2. Deploy the Governor contract with the comand below:
```
```bash
source .env
ACT_TOKEN_ADDRESS="0xACTTokenAddr" forge script script/ACTGovernor.s.sol --rpc-url sepolia --broadcast --mnemonics "$MNEMONIC" --mnemonic-indexes 0
```
```
3. Go to tally.xyz -> "Use Tally" -> "Connect wallet" -> "Wallet connect" -> select network -> "View all" -> "Safe" -> it will open Safe Global, connect to one of the admin accounts of the Treasury Multisig accounts and select the Treasury Multisig account.
4. It will ask you to sign a connection. Sign it. Sometimes it is glitching and you need to refresh the page. Also, you may need to re-connect to the Safe Global from another admin accounts if the Treasury Multisig requires more than one signature.
5. Go back to Tally, Treasury Multisig account should be connected to Tally at this point. Click on "Add a DAO" -> "Deploy Myself" -> "Deploy Contracts Yourself" -> Select all checboxes -> "Get Started"
6. Enter Governor contract address (deployed in the previous step), select network, click "Fetch details", then "Enter details manually". Select "Open Zeppelin Governor" in Governor Type. Enter Token address and block numbers for the transactions when the Token and the Governor contracts were deployed (check on the blockchain explorer for that). Enter Name and Description for the DAO, click "Submit"
```
6. Delegate the voting power to yourself (this is a technical must do step in order to make proposals & vote)
```
1. Click on your connected account (top right) -> Click on "My Voting Power" -> "Delegated To" -> "Delegate" -> "Myself". It will redirect you to Safe Global, where you need to sign the transactions and execute them. You may need to refresh the page several times, it is a bit buggy. Also, if you havae more than one voting threshold, then you need to do it from more than one account.
2. Wait a bit and you should see that your voting power is 1B tokens in Tally dashboard.
```

7. Create a proposal on tally about creating a vesting plan on hedgey - 15% for the team.
```
1. In Tally -> "Proposals" -> "New proposal" -> Enter title and description -> Publish
2. It will redirect you to Safe Global, you need to sign with the Treasury Multisig addres. Again, it can be a bit buggy, so you may need to refresh the page several times. Also, if the Treasury Multisig wallet requires more than one signer to enforce the transaction, you will have to connect with another wallet to sign the transaction again.
3. Wait for a bit for transaction to mine and get indexed, and for the proposal to appear in Tally dashboard.
```

8. The Treasury Multisig votes for it (and it is accepted / executed)
```
1. Click on the proposal -> "Vote onchain" -> select "yes" or "no" -> it will redirect you to safe, you should sign transactions there.
2. Wait for a bit and your vote will appear on Tally
3. Wait for longer and the proposal will finish, you can execute it after that.
```

9. Create Team Vesting Multisig account on Safe Global with a different set of signer accounts (e.g. Dom, Anton, Illia, etc.)
```
1. Similar how in the step nr. 1 but for different set of signer addresses
```

10. Create a vesting plan with the Team Vesting Multisig as the receiver address (created in step 8). 15% total supply.
```
1. Go to app.hedgey.finance -> "Vesting Plans" -> "View on Safe" (near "Issued Vesting Plans") -> Connect with Treasury Multisig
2. It will open a Hedgey window inside the Safe Global -> "Create Vesting Plan"
3. Enter the ACT token address, select unlock frequency, vesting term and cliff, click "Next"
4. Allow admin transfer of plans. "Allow on-chain governance" - ???, click "Next"
5. Enter Team Vesting Multisig address, enter 150,000,000 as token amount (15% from total supply), select a vesting start date, click "Next"
6. Review and confirm, sign on Safe Global, sign with another signer if needed to execute the transaction
```

11. Delegate the voting power from the vesting contract (step10) to the the Team Vesting Multisig
```
1. Go back to Hedgey, connect with Safe Global with Team Vesting Multisig account, and you should see a record in "Received Vesting". Click on "details"
2. In "Active Vesting Plans" click on "More" -> "Delegate" -> Enter Team Vesting Multisig address -> "Delegate" -> Confirm through Safe Global
```

12. Ensure the team vesting multisig can create proposals & vote on Tally
```
1. Go to Tally -> Connect with Team Vesting Multisig account -> Try to create a proposal and vote for it.
```