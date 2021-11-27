# Multi Signiture Wallets

- What is the importance of multi signiture wallets

  - We can have multiple accounts able to withdraw from one account
  - We can implement a restriction on who and what percentage will be able to withdraw
  - On the event of losing access to an account another person can withdraw funds

- Logic
  - Create the transaction
  - After transaction is created ( As pending transaction ) it will need to be signed or confirmed
  - After confirmation the transaciton should be deleted from the pending transaction
