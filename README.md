# ARC Freelance Pay (Escrow Smart Contract)

An automated and secure milestone-based Escrow Smart Contract built for the **Arc Network Testnet**. This contract ensures secure payments between a Buyer and a Freelancer, managed step-by-step through project milestones with an independent Arbiter to resolve disputes.

---

## 🚀 Features

* **Milestone-Based Payments:** Funds are split equally across milestones and released sequentially.
* **Dust Amount Fix:** Automatically handles division remainder (dust amount) by sending the total remaining contract balance to the freelancer on the final milestone.
* **Security Guards:** Protected against reentrancy attacks using a custom `nonReentrant` modifier.
* **Dispute Resolution:** In case of disagreements, a trusted third-party Arbiter can resolve the dispute and transfer funds to either the freelancer or refund the buyer.

---

## 🛠️ Smart Contract Details

* **Compiler Version:** Solidity `^0.8.20`
* **License:** MIT
* **Network:** Arc Network Testnet (Chain ID: `5042002`)

### Roles
1.  **Buyer:** Deposits the total budget and triggers milestone releases.
2.  **Freelancer:** Receives payments upon successful completion of each milestone.
3.  **Arbiter:** A trusted third-party referee who resolves disputes if raised.

---

## 📖 Deployment & Testing Guide (Remix IDE)

### 1. Deployment Parameters
When deploying the contract, provide the following parameters in the constructor:
* `_freelancer`: Wallet address of the freelancer.
* `_arbiter`: Wallet address of the trusted arbiter.
* `_milestones`: Total number of milestones (e.g., `3`).
* `_totalAmount`: Total budget in Wei (e.g., `1000000000000000000` for 1 native token).

> ⚠️ **Note:** Keep the global Remix **Value** field as `0 wei` during deployment.

### 2. Deposit Funds (Buyer)
1.  Set the main **Value** field in Remix to your total budget (e.g., `1000000000000000000` Wei).
2.  Select `depositFund` from the contract functions dropdown.
3.  Click the button and confirm the MetaMask popup. Contract status changes to `Active`.

### 3. Release Milestones
1.  Set the main **Value** field back to `0 wei`.
2.  Select `releaseMilestone` from the functions dropdown and click transact.
3.  Repeat for subsequent milestones. On the last milestone, any remaining fractions (dust) are automatically cleared out, leaving the contract balance at exactly `0 ETH`.

### 4. Dispute Workflow (Optional)
* **Raise Dispute:** Either Buyer or Freelancer can call `raiseDispute()` if a conflict occurs.
* **Resolve Dispute:** The Arbiter account must connect and call `resolveDispute(bool payFreelancer)`. Passing `true` sends remaining funds to the freelancer, while `false` refunds the buyer.

---

## 📜 License

This project is licensed under the MIT License - see the [ARCEscrow.sol](ARCEscrow.sol) file for details.
