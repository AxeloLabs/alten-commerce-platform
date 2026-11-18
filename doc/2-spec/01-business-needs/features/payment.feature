Feature: Payment
  The store is paid exactly once for each confirmed order, and gives back what it should not keep.

  Rule: An order is charged at most once, for exactly its total

    @BDD-PAY-001 @UC-PAY-001 @FR-PAY-002 @FR-PAY-003 @nominal
    Scenario: A payment is captured for the order total
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_ok"
      Then one payment of 119.87 EUR is "CAPTURED" for "ORD-1001"
      And no card data is stored

    @BDD-PAY-002 @UC-PAY-001 @FR-PAY-001 @invariant @critical-path
    Scenario: A duplicate payment request charges once
      Given a payment of 119.87 was captured for the order "ORD-1001"
      When the same payment request for "ORD-1001" is received again
      Then the answer is "CAPTURED"
      And the payment provider was called exactly once for "ORD-1001"

    @BDD-PAY-007 @UC-PAY-001 @FR-PAY-001 @edge
    Scenario: A transient provider failure is retried without charging twice
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_flaky"
      Then the payment is "CAPTURED"
      And exactly one charge of 119.87 exists at the provider

  Rule: A refused payment is recorded with its reason

    @BDD-PAY-003 @UC-PAY-001 @FR-PAY-004 @error
    Scenario: The payment provider refuses the payment
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_declined"
      Then the payment is "REFUSED" with the provider's reason
      And nothing is captured

  Rule: An unanswered payment is unknown until it is canceled or found captured

    @BDD-PAY-004 @UC-PAY-001 @FR-PAY-005 @edge @critical-path
    Scenario: The payment provider does not answer
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_timeout"
      Then the payment is "UNKNOWN"
      And nothing is recorded as captured

    @BDD-PAY-008 @UC-PAY-001 @FR-PAY-005 @FR-PAY-007 @error
    Scenario: The payment provider fails with a technical error on every attempt
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_error"
      Then the payment is "UNKNOWN"
      And nothing is captured at the provider

    @BDD-PAY-009 @UC-PAY-001 @FR-PAY-005 @nominal @critical-path
    Scenario: An unknown payment is canceled and can no longer be captured
      Given the payment of the order "ORD-1001", requested with the token "tok_timeout", is "UNKNOWN"
      When the cancellation of the payment is requested
      Then the payment is "CANCELED"
      And nothing is captured at the provider

    @BDD-PAY-010 @UC-PAY-001 @FR-PAY-005 @edge @critical-path
    Scenario: Canceling a payment that was captured after all
      Given the payment of the order "ORD-1001", requested with the token "tok_late_capture", is "UNKNOWN"
      When the cancellation of the payment is requested
      Then the payment is "CAPTURED"
      And exactly one charge of 119.87 exists at the provider

  Rule: A refund returns the full amount, once

    @BDD-PAY-005 @UC-PAY-002 @FR-PAY-006 @nominal
    Scenario: A captured payment is refunded in full
      Given a payment of 119.87 was captured for the order "ORD-1001"
      When a refund is requested for "ORD-1001"
      Then the payment is "REFUNDED"
      And the amount refunded is 119.87

    @BDD-PAY-006 @UC-PAY-002 @FR-PAY-006 @invariant
    Scenario: A duplicate refund request refunds once
      Given the payment of the order "ORD-1001" was refunded
      When the same refund request for "ORD-1001" is received again
      Then the answer is "REFUNDED"
      And the payment provider was asked to refund exactly once for "ORD-1001"
