Feature: Notification
  The customer learns by e-mail what happens to an order; an e-mail never stands in the way of an order.

  Rule: The customer is e-mailed once for each change that matters

    @BDD-NOT-001 @UC-NOT-001 @FR-NOT-001 @FR-NOT-004 @nominal
    Scenario: A confirmation e-mail is sent
      Given the order "ORD-1001" of "alice@example.com" with a total of 119.87
      When the order "ORD-1001" is confirmed
      Then one e-mail is sent to "alice@example.com"
      And it contains the order number, the lines, the total 119.87 and the status "CONFIRMED"
      And it contains no payment data

    @BDD-NOT-004 @UC-NOT-001 @FR-NOT-001 @FR-NOT-004 @nominal
    Scenario Outline: A rejection e-mail states the reason in plain language
      Given the order "ORD-1001" of "alice@example.com"
      When the order "ORD-1001" is rejected with the reason "<reason>"
      Then one e-mail is sent to "alice@example.com"
      And it says "<message>"

      Examples:
        | reason          | message                                                        |
        | OUT_OF_STOCK    | a product was no longer available; nothing was charged         |
        | PAYMENT_REFUSED | your payment was declined; nothing was charged                 |
        | TIMED_OUT       | we could not complete your order in time; nothing was charged  |

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
      And the e-mail is retried with increasing delays
      And after the last retry it is recorded as not sent and an alert is raised
