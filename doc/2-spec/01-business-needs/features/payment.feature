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

  Rule: A refused payment is recorded with its reason

    @BDD-PAY-003 @UC-PAY-001 @FR-PAY-004 @error
    Scenario: The payment provider refuses the payment
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_declined"
      Then the payment is "REFUSED" with the provider's reason
      And nothing is captured

  Rule: An unanswered payment has an unknown outcome until it is queried

    @BDD-PAY-004 @UC-PAY-001 @FR-PAY-005 @edge @critical-path
    Scenario: The payment provider does not answer
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_timeout"
      And the provider does not answer after the retries
      Then the payment is "UNKNOWN"
      And a status query for "ORD-1001" answers "not captured"

    @BDD-PAY-007 @UC-PAY-001 @FR-PAY-001 @edge
    Scenario: A transient provider failure is retried without charging twice
      Given the order "ORD-1001" with a total of 119.87 and its stock reserved
      When a payment is requested for "ORD-1001" with the token "tok_flaky"
      Then the payment is "CAPTURED" after 3 attempts
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
