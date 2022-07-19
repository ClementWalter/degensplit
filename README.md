# Degensplit

Degensplit is expense tracking software that allows you to split expenses in between people, DeFied degen way.

Unlike usual expenses splitting apps, Degensplit is fully decentralized and relies on account abstraction.

It thus allows for:

- native login functionnality
- modular groups of expenses
  - each expense can be grouped with others to simplify final counts in between addresses only
  - no frozen set of expenses: debts from event A can be used to settle debts from event B
- DeFied expenses
  - possibility to sell an expense seen as a micro lending
  - brings liquidity to peer-to-peer finance organisations
- native multi currencies app with spot market prices used at settlement
- automatic immediate or future payout
  - any user can trigger a settlement at any time shouuld they need liquidity
- no risk for lender not to be paid
  - optional pre-approval of settlement funds when adding an expense
  - optional borrower solvability check
- reimbursements preference ordering
  - deficit can pay out debts in a preferred order of lenders when funded

## How to use it

Degensplit is under active development.
Test app is deployed on [Goerli](https://beta-goerli.voyager.online/contract/0x03125d10deef7db705b4f9a1392586a0f03adbae0c01b3e8cccc1c3da227ca95)

Current functionnalities are:

- `addLending`: add an expense where sender writes that _borrower_ owns them _amount_ in currency _symbol_ (ascii value of symbol, e.g. str_to_felt("usd"))
  - each lending is an NFT (ERC721Enumerable) where borrower owns amount to owner.
  - all NFTs functionnality to transfer and sell an expenses available by design
- `getLending`: return an expense data
- `getDebts` : returns all lendings of a given address
- `getGroupBalance`: compute the balance of all expenses of a given group of users
