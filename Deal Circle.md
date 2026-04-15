# Swift Space Deal Circles

This document outlines the complete lifecycle of transactions ("Deal Circles") within the Swift Space application. It covers everything from initial interest to the final release of funds, detailing both **Success** and **Failure** paths for Rentals, Purchases, and Inspections.

---

## 1. The Inspection Circle

Before a user commits to a rental or purchase, they typically book a physical or virtual inspection.

### **Success Path**
1. **Request**: The user selects a time and requests an inspection (`BookingStatus.pending`).
2. **Commitment Fee**: The user pays the booking footprint/commitment fee (e.g., ₦500) into Escrow. The fee status becomes `EscrowState.held`.
3. **Agent Confirmation**: The agent reviews the request and confirms (`BookingStatus.confirmed`).
4. **Inspection Commences**: On the agreed date, the agent starts the inspection (`BookingStatus.commenced`).
5. **Inspection Finalized**: The agent concludes the visit from their dashboard (`BookingStatus.finalized`).
6. **Client Approval**: The user rates the visit, drops a review, and marks it as a success (`BookingStatus.completed`).
7. **Escrow Release**: The inspection fee in the escrow vault is released to the agent (`EscrowState.released`).

### **Failure & Edge Cases**
* **Agent Declines**: Agent rejects the booking (`BookingStatus.declined`). The escrow fee changes to `EscrowState.refunded` and is returned to the user.
* **Client Cancels**: The user changes their mind and cancels (`BookingStatus.cancelled`). Dependent on platform policy, the baseline fee may be refunded or forfeited.
* **Rescheduling**: The agent cannot make the time and proposes a new one (`BookingStatus.postponed`).
* **Inspection Fails**: The user disputes the inspection (e.g., property vastly different from listing). Escrow is halted, and customer mediation is required.

---

## 2. The Negotiation Circle

Once an inspection is completed, the user can negotiate the price before proceeding to the final deal.

### **Success Path**
1. **Initial Offer**: The client inputs an offer lower than the asking price (`NegotiationStatus.clientOffer`). 
2. **Counter Offers (Iterative)**: The agent might counter (`NegotiationStatus.agentCountered`), and the client can respond (`NegotiationStatus.clientCountered`).
3. **Agreement**: Both parties agree on a final amount (`NegotiationStatus.agreed`). The deal proceeds to Escrow Setup based on this agreed price.

### **Failure Cases**
* **Rejection**: The agent explicitly rejects the client's offer without a counter (`NegotiationStatus.rejected`). The deal ends.
* **Client Withdraws**: The client decides not to proceed and withdraws their offer (`NegotiationStatus.withdrawn`).
* **Max Rounds Exceeded / Deal Ended**: Negotiations hit a stalemate, and either party terminates the session (`NegotiationStatus.dealEnded`).

---

## 3. The Rental Circle

When a client wants to rent a property, they initiate a rental escrow transaction. Rentals often involve singular payments or split payments (e.g., Rent, Caution fee, Agency fee).

### **Success Path**
1. **Escrow Initiation**: Following a successful agreement, the rental deal is documented. The system generates an `EscrowTransaction` reflecting the rental terms (Deal Type: "First Month Rent", "Full Year Rent", etc.).
2. **Awaiting Payment**: The status starts at `EscrowState.awaitingPayment`. The client evaluates the breakdown (Service Fee + Custom Installments).
3. **Funding Escrow**: The client pays via Card, Bank Transfer, or USSD. Upon success, the funds are securely stored in the Swift Space Vault (`EscrowState.held`).
4. **Legal & Document Check**: The agent processes the Tenancy Agreement and hands over the keys. The state transitions to `EscrowState.inspectionPassed`.
5. **Final Release**: The client confirms successful move-in and possession. Swift Space instantly releases the funds to the agent/landlord (`EscrowState.released`). An `AccountInvoice` (Receipt) is generated permanently.

### **Failure & Default Cases**
* **Overdue Payment**: The client fails to pay an installment before the dueDate. The status transitions to `EscrowState.overdue`.
* **Abandonment**: The client never funds the Escrow; the vault remains `awaitingPayment` until the agent cancels it to free up the property.
* **Property Dispute**: The client pays into Escrow but discovers severe undetected faults upon move-in attempt. The status remains `held`, funds are **frozen**, and a mediator intervenes. If resolved in favor of the client, it transitions to `EscrowState.refunded`.

---

## 4. The Purchase (Buying) Circle

Buying a property usually involves much larger sums and milestones.

### **Success Path**
1. **Milestone Setup**: The purchase is split into chunks via `EscrowInstallment` (e.g., Initial Deposit 30%, Second Milestone 30%, Final Balance 40%).
2. **Holding Phases**: The client funds the first milestone (`EscrowState.held`). 
3. **Progressive Unlocking**: As legal milestones are reached (e.g., Deeds signed, Title transferred), partial releases might happen, or the funds remain entirely held until the Final Balance is cleared.
4. **Complete Closure**: The final installment is paid, legal ownership transfers, verification is complete (`inspectionPassed`), and total funds leave escrow to the seller (`EscrowState.released`).

### **Failure & Default Cases**
* **Milestone Default**: The client pays the Initial Deposit but defaults on the "Second Milestone." The installment is flagged as `isOverdue = true` and the transaction becomes `EscrowState.overdue`.
* **Failed Verification**: The property title turns out to be contested during the holding phase. The deal is aborted, and funds are automatically pushed back (`EscrowState.refunded`).
* **Contract Nullification (Seller Side)**: If the seller decides to pull out after the initial deposit, the escrow is safely returned (`refunded`), and penalty logic may apply based on agreed terms.

---

## 5. The Vault Circle

Sometimes clients wish to plan ahead for a lease or purchase by gradually building up funds. The Vault system serves this purpose.

### **Success Path**
1. **Target Identification**: The client selects a target property type (e.g., Duplex, Apartment). The system calculates the average market price.
2. **Setup**: The client selects a rhythm (Daily, Weekly, Monthly) and a Partner Bank (offering an agreed APY/Interest).
3. **Automated Heatmap (Gamification)**: Funds are debited automatically. The consistency is visualized using a lively, gamified heatmap indicating completed savings cycles. 
4. **Maturity**: Once the target amount is hit or the timeline matures, the user can instantly initiate an Escrow/Rental deal using the compounded Vault balance, or withdraw it safely.

### **Failure & Default Cases**
* **Insufficient Funds**: If an auto-debit fails, that specific block on the heatmap is missed, and the countdown adjusts to the next cycle.
* **Early Breakage**: The client terminates the vault plan early out of necessity. Depending on partner bank terms, interest may be forfeited, but the principle is restored to the primary wallet (`EscrowState.refunded`).

---

## Summary of Core State Transitions

### Escrow Status Flow
`awaitingPayment` -> `held` -> `inspectionPassed` -> `released`
*(Alt Route)* -> `overdue` / `refunded`

### Booking Status Flow
`pending` -> `confirmed` -> `commenced` -> `finalized` -> `completed`
*(Alt Route)* -> `declined` / `postponed` / `cancelled`

### Negotiation Status Flow
`clientOffer` <-> `agentCountered` <-> `clientCountered` -> `agreed`
*(Alt Route)* -> `rejected` / `withdrawn` / `dealEnded`

