Feature: Notification
  The customer learns by e-mail what happens to an order; an e-mail never stands in the way of an order.

  Rule: The customer is e-mailed once for each change that matters, and told the truth about the money

    @BDD-NOT-001 @UC-NOT-001 @FR-NOT-001 @FR-NOT-004 @nominal
    Scenario: A confirmation e-mail is sent
      Given the order "ORD-1001" of "alice@example.com" with a total of 119.87
      When the order "ORD-1001" is confirmed
      Then one e-mail is sent to "alice@example.com"
      And it contains the order number, the lines, the total 119.87 and the status "CONFIRMED"
      And it contains no payment data

    @BDD-NOT-004 @UC-NOT-001 @FR-NOT-001 @FR-NOT-004 @nominal
    Scenario Outline: A rejection e-mail states the reason and what happened to the money
      Given the order "ORD-1001" of "alice@example.com"
      And its payment was <payment>
      When the order "ORD-1001" is rejected with the reason "<reason>"
      Then one e-mail is sent to "alice@example.com"
      And it says "<message>"

      Examples:
        | reason          | payment         | message                                                         |
        | OUT_OF_STOCK    | never requested | a product was no longer available; nothing was charged          |
        | OUT_OF_STOCK    | refunded        | a product was no longer available; your payment was refunded    |
        | PAYMENT_REFUSED | refused         | your payment was declined; nothing was charged                  |
        | TIMED_OUT       | canceled        | we could not complete your order in time; nothing was charged   |
        | ADMIN_DECISION  | refunded        | your order was closed after a review; your payment was refunded |

    @BDD-NOT-005 @UC-NOT-001 @FR-NOT-001 @nominal
    Scenario: The customer is told when an order is put under review
      Given the order "ORD-1001" of "alice@example.com" is "PENDING"
      When the order "ORD-1001" is put under review
      Then one e-mail is sent to "alice@example.com"
      And it says that the store is checking the order and will come back with the outcome

    @BDD-NOT-002 @UC-NOT-001 @FR-NOT-002 @invariant
    Scenario: The same event received twice sends one e-mail
      Given the confirmation of the order "ORD-1001" was already notified
      When the same confirmation event is received again
      Then no new e-mail is sent

  Rule: A notification failure never affects the order

    @BDD-NOT-003 @UC-NOT-001 @FR-NOT-003 @error
    Scenario: The e-mail provider is down
      Given the e-mail provider fails every request
      When the order "ORD-1001" is confirmed
      Then the order "ORD-1001" stays "CONFIRMED"
      And after the last retry the e-mail is recorded as not sent
