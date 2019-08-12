# B9lab_Remittance
Project 2: B9lab's Ethereum Community Blockstar

# What

You will create a smart contract named Remittance whereby:

- There are three people: Alice, Bob & Carol.
- Alice wants to send funds to Bob, but she only has ether & Bob does not care about Ethereum and wants to be paid in local currency.
- Luckily, Carol runs an exchange shop that converts ether to local currency.


Therefore, to get the funds to Bob, Alice will allow the funds to be transferred through Carol's exchange shop. Carol will collect the ether from Alice and give the local currency to Bob.


The steps involved in the operation are as follows:

- Alice creates a Remittance contract with Ether in it and a puzzle.
- Alice sends a one-time-password to Bob; over SMS, say.
- Alice sends another one-time-password to Carol; over email, say.
- Bob treks to Carol's shop.
- Bob gives Carol his one-time-password.
- Carol submits both passwords to Alice's remittance contract.
- Only when both passwords are correct does the contract yield the Ether to Carol.
- Carol gives the local currency to Bob.
- Bob leaves.
- Alice is notified that the transaction went through.


Since they each have only half of the puzzle, Bob & Carol need to meet in person so they can supply both passwords to the contract. This is a security measure. It may help to understand this use-case as similar to a 2-factor authentication.

Stretch goals:

- Did you implement the basic specs airtight, without any exploit, before ploughing through the stretch goals?
- Add a deadline, after which Alice can claim back the unchallenged Ether
- Add a limit to how far in the future the deadline can be
- Add a kill switch to the whole contract
- Plug a security hole (which one?) by changing one password to the recipient's address
- Make the contract a utility that can be used by David, Emma and anybody with an address
- Make you, the owner of the contract, take a cut of the Ethers. How much? Your call. Perhaps smaller than what it would cost Alice to deploy the same contract herself
- Did you degrade safety in the name of adding features?

# Low Difficulty

- Did you make sure to have a single source of hashing truth, or do you have 2 different algorithms in Solidity and Javascript that happen to yield same results?

# Medium Difficulty

- Did you store supposedly secret information in the contract?
- Did you understand a private statement a bit too literally?
- Did you send passwords in the clear too early?
- Did you cover the game theoretic elements right?
- Did you prevent sabotage / overwriting?
- Did you keep off-chain what can be kept off-chain?

# High Difficulty

- Did you let passwords be reused?
- Did you think about miners possibly front-running your users with a competing transaction?
- When you prevent an action < deadline and the other > deadline, did you actually mean to prevent anything happening at == deadline?

# Before moving on

In the next module, you will work on your last small project. As previously, we would like you to take your Remittance to a satisfactory level. And this level is:

- Proper Solidity code.
- Game theoretic situations covered.
- Hash complexity covered.
- Reasonable number of unit tests that cover regular situations.
