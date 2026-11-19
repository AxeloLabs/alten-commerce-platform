Feature: Order
  A cart becomes a confirmed, paid order, or the customer is told why not and has paid nothing.

  Background:
    Given a signed-in customer "alice@example.com"
    And the published product "KB-001" priced 89.90 with 5 units on hand
    And the published product "CB-001" priced 9.99 with 50 units on hand

  Rule: An order is confirmed only when its payment is captured and its stock is secured

    @BDD-ORD-001 @UC-ORD-001 @FR-ORD-006 @FR-ORD-007 @FR-INV-005 @FR-CART-007 @nominal @critical-path
    Scenario: Order placed and confirmed
      Given a cart with 1 unit of "KB-001" and 3 units of "CB-001"
      When the customer places the order with the payment token "tok_ok"
      Then the order is acknowledged at once with the status "PENDING"
      And within 15 seconds the order is "CONFIRMED"
      And one payment of 119.87 is captured
      And "KB-001" has 4 units on hand and "CB-001" has 47 units on hand
      And the cart is empty
      And one confirmation e-mail is sent to "alice@example.com"

    @BDD-ORD-008 @UC-ORD-001 @FR-ORD-002 @FR-ORD-004 @nominal
    Scenario Outline: The order total is the sum of its lines
      Given a cart with the lines <lines>
      When the customer places the order with the payment token "tok_ok"
      Then the order total is <total>

      Examples:
        | lines                      | total  |
        | 1 x KB-001                 | 89.90  |
        | 1 x CB-001                 | 9.99   |
        | 2 x KB-001 and 10 x CB-001 | 279.70 |
        | 5 x KB-001 and 3 x CB-001  | 479.47 |

  Rule: Stock is reserved before payment; an order whose stock cannot be reserved is never charged

    @BDD-ORD-003 @UC-ORD-001 @FR-ORD-006 @FR-ORD-008 @FR-INV-003 @error @critical-path
    Scenario: Order rejected when the stock is gone but the catalog does not know it yet
      Given a cart with 3 units of "KB-001" and 1 unit of "CB-001"
      And another customer just bought 4 units of "KB-001"
      And the catalog still shows 5 units of "KB-001" available
      When the customer places the order with the payment token "tok_ok"
      Then within 15 seconds the order is "REJECTED" with the reason "OUT_OF_STOCK"
      And no payment was requested
      And nothing is reserved for the order, not even "CB-001"
      And the cart is kept
      And one rejection e-mail is sent to "alice@example.com"

    @BDD-ORD-004 @UC-ORD-001 @FR-INV-002 @FR-INV-003 @invariant @critical-path
    Scenario: Two customers compete for the last unit
      Given "KB-001" has 1 unit on hand
      And the customers "alice@example.com" and "bob@example.com" each have 1 unit of "KB-001" in their cart
      When both place their order at the same time with the payment token "tok_ok"
      Then exactly one order is "CONFIRMED" and the other is "REJECTED" with the reason "OUT_OF_STOCK"
      And exactly one payment is captured
      And "KB-001" has 0 units on hand

  Rule: A refused payment rejects the order and frees the stock

    @BDD-ORD-002 @UC-ORD-001 @FR-ORD-008 @FR-PAY-004 @FR-CART-007 @error @critical-path
    Scenario: Order rejected when the payment is refused
      Given a cart with 2 units of "KB-001"
      When the customer places the order with the payment token "tok_declined"
      Then within 15 seconds the order is "REJECTED" with the reason "PAYMENT_REFUSED"
      And no payment is captured
      And "KB-001" has 5 units available
      And the cart is kept

  Rule: A checkout is refused when what the customer reviewed is no longer true

    @BDD-ORD-005 @UC-ORD-001 @FR-ORD-003 @error
    Scenario: Checkout refused when a price changed since the review
      Given a cart with 1 unit of "KB-001"
      And the customer reviewed the checkout at 89.90
      And the administrator changed the price of "KB-001" to 99.90
      When the customer submits the checkout
      Then no order is created
      And the customer is told that "KB-001" changed from 89.90 to 99.90

    @BDD-ORD-024 @UC-ORD-001 @FR-ORD-003 @error
    Scenario: Checkout refused when the catalog knows the stock no longer covers a line
      Given a cart with 3 units of "KB-001"
      And the customer reviewed the checkout
      And another customer bought 4 units of "KB-001", which the catalog now knows
      When the customer submits the checkout
      Then no order is created
      And the customer is told that only 1 unit of "KB-001" is available

    @BDD-ORD-025 @UC-ORD-001 @FR-ORD-001 @FR-CART-010 @error
    Scenario: Checkout refused while the cart holds a flagged line
      Given a cart with 1 unit of "KB-001" and 1 unit of "CB-001"
      And the administrator retired "CB-001"
      When the customer submits the checkout
      Then no order is created
      And the customer is told to remove "CB-001" from the cart

    @BDD-ORD-006 @UC-ORD-001 @FR-ORD-001 @edge
    Scenario: Checkout refused with an empty cart
      Given an empty cart
      When the customer submits the checkout
      Then no order is created

  Rule: One checkout gives at most one order and one payment, and one order is pending at a time

    @BDD-ORD-007 @UC-ORD-001 @FR-ORD-009 @FR-PAY-001 @invariant @critical-path
    Scenario: Submitting the same checkout twice
      Given a cart with 1 unit of "KB-001"
      When the customer submits the same checkout twice in a row with the payment token "tok_ok"
      Then both answers carry the same order number
      And exactly one order exists
      And exactly one payment is captured

    @BDD-ORD-026 @UC-ORD-001 @FR-ORD-017 @invariant @critical-path
    Scenario: A second checkout is refused while an order is pending
      Given a cart with 1 unit of "KB-001"
      And the customer placed an order with the payment token "tok_slow", which is still "PENDING"
      When the customer submits a new checkout from another device
      Then the checkout is refused and points to the pending order
      And exactly one order exists

  Rule: An order always reaches an outcome, whatever fails

    @BDD-ORD-028 @UC-ORD-001 @FR-ORD-006 @FR-ORD-008 @edge @critical-path
    Scenario: Order rejected when the inventory does not answer before the order deadline
      Given a cart with 1 unit of "KB-001"
      And the inventory does not answer
      When the customer places the order with the payment token "tok_ok"
      And the order deadline expires
      Then the order is "REJECTED" with the reason "TIMED_OUT"
      And no payment was requested
      And the cart is kept

    @BDD-ORD-009 @UC-ORD-001 @FR-ORD-015 @FR-PAY-005 @edge @critical-path
    Scenario: Order rejected when the payment gives no answer before the order deadline
      Given a cart with 1 unit of "KB-001"
      When the customer places the order with the payment token "tok_timeout"
      And the order deadline expires
      Then the payment is "CANCELED" and nothing is captured
      And the order is "REJECTED" with the reason "TIMED_OUT"
      And "KB-001" has 5 units available

    @BDD-ORD-010 @UC-ORD-001 @FR-ORD-015 @FR-PAY-005 @edge @critical-path
    Scenario: A payment found captured at the order deadline is carried through
      Given a cart with 1 unit of "KB-001"
      When the customer places the order with the payment token "tok_late_capture"
      And the order deadline expires
      Then the payment is "CAPTURED"
      And the order is "CONFIRMED"
      And "KB-001" has 4 units on hand

    @BDD-ORD-027 @UC-ORD-001 @UC-ORD-007 @FR-ORD-016 @edge @critical-path
    Scenario: An order whose payment outcome cannot be established goes under review
      Given a cart with 1 unit of "KB-001"
      When the customer places the order with the payment token "tok_blackout"
      And the review delay expires
      Then the order is "UNDER_REVIEW"
      And the payment is "UNKNOWN"
      And 1 unit of "KB-001" is still reserved for the order
      And an alert is raised for the administrators
      And one e-mail tells the customer that the order is being checked

    @BDD-ORD-023 @UC-ORD-001 @UC-ORD-007 @FR-ORD-016 @FR-ORD-007 @edge @critical-path
    Scenario: A paid order whose stock is not confirmed in time goes under review
      Given the customer placed an order for 1 unit of "KB-001" and its payment is captured
      And the inventory stopped answering before the reservation was confirmed
      When the review delay expires
      Then the order is "UNDER_REVIEW"
      And the payment is still "CAPTURED"
      And an alert is raised for the administrators

    @BDD-ORD-038 @UC-ORD-001 @FR-ORD-007 @edge
    Scenario: A paid order waits for a slow inventory and is confirmed
      Given the customer placed an order for 1 unit of "KB-001" and its payment is captured
      And the inventory answers the confirmation late, but before the review delay expires
      When the inventory answers
      Then the order is "CONFIRMED"
      And the order was never "UNDER_REVIEW"

    @BDD-ORD-034 @UC-ORD-001 @UC-ORD-007 @FR-ORD-016 @FR-ORD-007 @edge @critical-path
    Scenario: An order under review settles by itself when the missing answer arrives
      Given the order "ORD-1001" for 1 unit of "KB-001" is "UNDER_REVIEW" with a captured payment
      And the inventory had stopped answering before the reservation was confirmed
      When the inventory works again
      Then the reservation is confirmed exactly once
      And the order is "CONFIRMED"
      And no decision of an administrator is recorded
      And one confirmation e-mail is sent to the customer

    @BDD-ORD-035 @UC-ORD-001 @FR-ORD-015 @FR-PAY-001 @edge @critical-path
    Scenario: An order placed while the payment service is down is never charged late
      Given a cart with 1 unit of "KB-001"
      And the payment service is down
      When the customer places the order with the payment token "tok_ok"
      And the order deadline expires
      And the payment service works again one hour later
      Then the payment is "CANCELED" and nothing is captured
      And the order is "REJECTED" with the reason "TIMED_OUT"
      And 5 units of "KB-001" are available

    @BDD-ORD-011 @UC-ORD-001 @FR-ORD-009 @FR-PAY-001 @invariant @critical-path
    Scenario: Order placement survives a restart of the order service after the payment
      Given a cart with 1 unit of "KB-001"
      And the customer placed the order with the payment token "tok_ok"
      And the order service stopped right after the payment was captured, before recording it
      When the order service restarts
      Then the order is "CONFIRMED"
      And exactly one payment is captured
      And "KB-001" has 4 units on hand

  Rule: A paid order whose stock is lost is refunded before it is rejected

    @BDD-ORD-029 @UC-ORD-001 @UC-PAY-002 @FR-INV-005 @FR-ORD-008 @FR-PAY-006 @error @critical-path
    Scenario: Paid, then the stock is gone: refunded and rejected
      Given the order "ORD-1001" for 1 unit of "KB-001" is "UNDER_REVIEW" with a captured payment of 89.90
      And the inventory was unavailable for longer than the reservation lifetime
      And another customer bought the last units of "KB-001" meanwhile
      When the administrator retries the stock confirmation with the comment "inventory is back"
      Then the payment of 89.90 is refunded in full exactly once
      And the order is "REJECTED" with the reason "OUT_OF_STOCK"
      And one e-mail tells the customer that the charge was refunded

    @BDD-ORD-012 @UC-ORD-001 @UC-ORD-007 @FR-ORD-014 @error @critical-path
    Scenario: A refund that keeps failing never passes for done
      Given the order "ORD-1001" is "UNDER_REVIEW", paid with the token "tok_refund_fails", its stock gone
      When the administrator rejects the order with the comment "stock gone"
      Then the order is still "UNDER_REVIEW"
      And the payment is still "CAPTURED"
      And the failed refund is added to the history of the order

  Rule: A customer sees only their own orders, and a final status never changes

    @BDD-ORD-013 @UC-ORD-002 @FR-IAM-004 @FR-ORD-005 @nominal
    Scenario: Viewing the order history
      Given the customer has the orders "ORD-1001" placed yesterday and "ORD-1002" placed today
      And another customer has the order "ORD-2001"
      When the customer opens the order history
      Then the list shows "ORD-1002" then "ORD-1001"
      And it does not show "ORD-2001"

    @BDD-ORD-014 @UC-ORD-003 @FR-ORD-011 @nominal
    Scenario: Viewing the status timeline of an order
      Given the customer's order "ORD-1001" was placed, then confirmed
      When the customer opens the order "ORD-1001"
      Then the order shows its lines with the prices paid and its shipping address
      And its timeline shows "PENDING" then "CONFIRMED", each with its date

    @BDD-ORD-022 @UC-ORD-003 @FR-ORD-010 @invariant
    Scenario Outline: A rejected order never changes again
      Given the order "ORD-1001" is "REJECTED" with the reason "PAYMENT_REFUSED"
      When <something arrives>
      Then the order is still "REJECTED" with the reason "PAYMENT_REFUSED"
      And no payment is captured and nothing is reserved for it

      Examples:
        | something arrives                                |
        | a duplicate "payment refused" answer is received |
        | a late "stock reserved" answer is received       |
        | an administrator asks to confirm the order       |

  Rule: An administrator finds any order

    @BDD-ORD-017 @UC-ORD-005 @FR-IAM-005 @nominal
    Scenario: An administrator searches the orders of all customers
      Given a signed-in administrator
      And the orders "ORD-1001" of "alice@example.com" and "ORD-2001" of "bob@example.com", both "CONFIRMED"
      When the administrator searches the orders with the status "CONFIRMED"
      Then the list shows "ORD-1001" and "ORD-2001"

  Rule: An administrator decides an order under review under the same rules as the system

    @BDD-ORD-020 @UC-ORD-007 @FR-ORD-014 @FR-PAY-006 @nominal
    Scenario: An administrator retries a refund that had failed
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW": its stock is gone and the refund of its payment failed
      And the payment provider works again
      When the administrator retries the failed step with the comment "provider back"
      Then the payment is refunded in full exactly once
      And the order is "REJECTED" with the reason "OUT_OF_STOCK"
      And the decision is recorded with the administrator and the comment

    @BDD-ORD-021 @UC-ORD-007 @FR-ORD-018 @FR-PAY-006 @nominal
    Scenario: An administrator rejects a paid order under review
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW" with a captured payment and its stock still reserved
      When the administrator rejects the order with the comment "customer asked to stop"
      Then the payment is refunded in full exactly once
      And the reserved stock is released exactly once
      And the order is "REJECTED" with the reason "ADMIN_DECISION"
      And one e-mail tells the customer the outcome and that the charge was refunded

    @BDD-ORD-032 @UC-ORD-007 @FR-ORD-018 @FR-ORD-007 @nominal
    Scenario: An administrator confirms a paid order under review
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW" with a captured payment and its stock still reserved
      And the inventory works again
      When the administrator confirms the order with the comment "inventory is back"
      Then the reservation is confirmed
      And the order is "CONFIRMED"
      And one confirmation e-mail is sent to the customer

    @BDD-ORD-033 @UC-ORD-007 @FR-ORD-018 @error
    Scenario: An administrator cannot confirm an order that is not paid
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW" with a payment whose outcome is "UNKNOWN"
      When the administrator confirms the order with the comment "looks fine"
      Then the decision is refused
      And the order is still "UNDER_REVIEW"

    @BDD-ORD-037 @UC-ORD-007 @FR-ORD-018 @FR-ORD-008 @FR-PAY-006 @edge
    Scenario: Rejecting a paid order returns its stock even when the stock is confirmed meanwhile
      Given a signed-in administrator
      And the order "ORD-1001" for 1 unit of "KB-001" is "UNDER_REVIEW" with a captured payment
      And the inventory has not answered the confirmation yet
      When the administrator rejects the order with the comment "customer asked to stop"
      And the inventory works again and confirms the reservation after the rejection
      Then the payment is refunded in full exactly once
      And the order is "REJECTED" with the reason "ADMIN_DECISION"
      And 5 units of "KB-001" are available

  Rule: A confirmed order can be canceled until it ships

    @BDD-ORD-015 @UC-ORD-004 @FR-ORD-012 @FR-PAY-006 @nominal
    Scenario: Canceling a confirmed order
      Given the customer's order "ORD-1001" is "CONFIRMED" with 2 units of "KB-001", paid 179.80
      When the customer cancels the order "ORD-1001"
      Then the order is "CANCELED"
      And the payment of 179.80 is refunded in full
      And the 2 units of "KB-001" are available again
      And one cancellation e-mail is sent to "alice@example.com"

    @BDD-ORD-016 @UC-ORD-004 @FR-ORD-012 @FR-ORD-010 @error
    Scenario Outline: Canceling an order that cannot be canceled
      Given the customer's order "ORD-1001" is "<status>"
      When the customer cancels the order "ORD-1001"
      Then the cancellation is refused
      And the order is still "<status>"

      Examples:
        | status    |
        | PENDING   |
        | SHIPPED   |
        | DELIVERED |
        | REJECTED  |

    @BDD-ORD-030 @UC-ORD-004 @UC-ORD-007 @FR-ORD-012 @FR-ORD-014 @error
    Scenario: A cancellation whose refund keeps failing goes under review
      Given the customer's order "ORD-1001" is "CONFIRMED", paid with the token "tok_refund_fails"
      When the customer cancels the order "ORD-1001"
      Then the order is "UNDER_REVIEW", not "CANCELED"
      And the payment is still "CAPTURED"
      And the order can no longer ship

    @BDD-ORD-036 @UC-ORD-004 @UC-ORD-007 @FR-ORD-012 @FR-ORD-016 @edge
    Scenario: A cancellation that does not finish goes under review and returns the stock once
      Given a signed-in administrator
      And the customer's order "ORD-1001" is "CONFIRMED" with 2 units of "KB-001", paid 179.80
      And the inventory does not answer
      When the customer cancels the order "ORD-1001"
      And the review delay expires
      Then the order is "UNDER_REVIEW"
      When the administrator retries the failed step with the comment "inventory is back"
      And the inventory works again
      Then the 2 units of "KB-001" are returned exactly once
      And the payment of 179.80 is refunded in full
      And the order is "CANCELED"

  Rule: Only an administrator takes a confirmed order to delivery, one step at a time

    @BDD-ORD-018 @UC-ORD-006 @FR-ORD-013 @nominal
    Scenario: Shipping a confirmed order
      Given a signed-in administrator
      And the order "ORD-1001" is "CONFIRMED"
      When the administrator marks "ORD-1001" as shipped
      Then the order is "SHIPPED"
      And its timeline records the administrator and the date
      And one shipment e-mail is sent to the customer

    @BDD-ORD-031 @UC-ORD-006 @FR-ORD-013 @nominal
    Scenario: Delivering a shipped order
      Given a signed-in administrator
      And the order "ORD-1001" is "SHIPPED"
      When the administrator marks "ORD-1001" as delivered
      Then the order is "DELIVERED"
      And one delivery e-mail is sent to the customer

    @BDD-ORD-019 @UC-ORD-006 @FR-ORD-010 @FR-ORD-013 @error
    Scenario Outline: Fulfillment out of order is refused
      Given a signed-in administrator
      And the order "ORD-1001" is "<status>"
      When the administrator marks "ORD-1001" as <action>
      Then the change is refused
      And the order is still "<status>"

      Examples:
        | status    | action    |
        | CONFIRMED | delivered |
        | PENDING   | shipped   |
        | CANCELING | shipped   |
        | DELIVERED | shipped   |
