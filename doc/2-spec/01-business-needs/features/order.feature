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
      Given a cart with <kb> units of "KB-001" and <cb> units of "CB-001"
      When the customer places the order with the payment token "tok_ok"
      Then the order total is <total>

      Examples:
        | kb | cb | total  |
        | 1  | 0  | 89.90  |
        | 0  | 1  | 9.99   |
        | 2  | 10 | 279.70 |
        | 5  | 3  | 479.47 |

  Rule: Stock is reserved before payment; an order whose stock cannot be reserved is never charged

    @BDD-ORD-003 @UC-ORD-001 @FR-ORD-006 @FR-ORD-008 @FR-INV-003 @error @critical-path
    Scenario: Order rejected when the stock is no longer available
      Given a cart with 3 units of "KB-001" and 1 unit of "CB-001"
      And another customer just bought 4 units of "KB-001"
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

    @BDD-ORD-006 @UC-ORD-001 @FR-ORD-001 @edge
    Scenario: Checkout refused with an empty cart
      Given an empty cart
      When the customer submits the checkout
      Then no order is created

  Rule: One checkout gives at most one order and one payment

    @BDD-ORD-007 @UC-ORD-001 @FR-ORD-009 @FR-PAY-001 @invariant @critical-path
    Scenario: Submitting the same checkout twice
      Given a cart with 1 unit of "KB-001"
      When the customer submits the same checkout twice in a row with the payment token "tok_ok"
      Then both answers carry the same order number
      And exactly one order exists
      And exactly one payment is captured

  Rule: An order always reaches an outcome, whatever fails

    @BDD-ORD-009 @UC-ORD-001 @FR-ORD-015 @FR-PAY-005 @edge @critical-path
    Scenario: Order rejected when the payment gives no answer before the deadline
      Given a cart with 1 unit of "KB-001"
      When the customer places the order with the payment token "tok_timeout"
      And the order deadline expires
      Then the payment status is queried and found not captured
      And the order is "REJECTED" with the reason "TIMED_OUT"
      And "KB-001" has 5 units available
      And no payment is captured

    @BDD-ORD-010 @UC-ORD-001 @FR-ORD-015 @FR-PAY-005 @edge @critical-path
    Scenario: A payment found captured at the deadline is carried through
      Given a cart with 1 unit of "KB-001"
      When the customer places the order with the payment token "tok_late_capture"
      And the order deadline expires
      Then the payment status is queried and found captured
      And the order is "CONFIRMED"
      And "KB-001" has 4 units on hand

    @BDD-ORD-023 @UC-ORD-001 @UC-PAY-002 @FR-PAY-005 @FR-PAY-006 @FR-ORD-010 @edge @critical-path
    Scenario: A payment captured after the order was rejected is refunded
      Given a cart with 1 unit of "KB-001"
      And the customer placed the order with the payment token "tok_very_late_capture"
      And the order was rejected with the reason "TIMED_OUT" after the status query answered "not captured"
      When the provider reports the payment as captured
      Then the payment is refunded in full exactly once
      And the order is still "REJECTED" and shows the refund
      And "KB-001" has 5 units available

    @BDD-ORD-011 @UC-ORD-001 @FR-ORD-009 @FR-PAY-001 @invariant @critical-path
    Scenario: Order placement survives a restart of the order service
      Given a cart with 1 unit of "KB-001"
      And the customer placed the order with the payment token "tok_slow"
      When the order service stops after the payment was requested and restarts
      Then the order is "CONFIRMED"
      And exactly one payment is captured
      And "KB-001" has 4 units on hand

    @BDD-ORD-012 @UC-ORD-001 @UC-ORD-007 @FR-ORD-014 @error @critical-path
    Scenario: A refund that keeps failing puts the order under review
      Given an order whose payment was captured with the token "tok_refund_fails"
      And the order must be rejected because its stock can no longer be secured
      When every attempt to refund the payment fails
      Then the order is "UNDER_REVIEW"
      And an alert is raised for the administrators
      And the payment is still recorded as "CAPTURED", not as refunded

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
    Scenario Outline: A final status never changes
      Given an order with the status "<final status>"
      When any message or request tries to move it to "<other status>"
      Then the order still has the status "<final status>"

      Examples:
        | final status | other status |
        | REJECTED     | CONFIRMED    |
        | REJECTED     | PENDING      |
        | DELIVERED    | CANCELLED    |
        | CANCELLED    | SHIPPED      |

  Rule: A confirmed order can be cancelled until it ships

    @BDD-ORD-015 @UC-ORD-004 @FR-ORD-012 @FR-PAY-006 @nominal @proposed
    Scenario: Cancelling a confirmed order
      Given the customer's order "ORD-1001" is "CONFIRMED" with 2 units of "KB-001", paid 179.80
      When the customer cancels the order "ORD-1001"
      Then the order is "CANCELLED"
      And the payment of 179.80 is refunded in full
      And the 2 units of "KB-001" are available again
      And one cancellation e-mail is sent to "alice@example.com"

    @BDD-ORD-016 @UC-ORD-004 @FR-ORD-012 @FR-ORD-010 @error @proposed
    Scenario Outline: Cancelling an order that can no longer be cancelled
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

  Rule: Only an administrator takes a confirmed order to delivery, one step at a time

    @BDD-ORD-017 @UC-ORD-005 @FR-IAM-005 @nominal @proposed
    Scenario: An administrator searches the orders of all customers
      Given a signed-in administrator
      And the orders "ORD-1001" of "alice@example.com" and "ORD-2001" of "bob@example.com", both "CONFIRMED"
      When the administrator searches the orders with the status "CONFIRMED"
      Then the list shows "ORD-1001" and "ORD-2001"

    @BDD-ORD-018 @UC-ORD-006 @FR-ORD-013 @nominal @proposed
    Scenario: Shipping then delivering an order
      Given a signed-in administrator
      And the order "ORD-1001" is "CONFIRMED"
      When the administrator marks "ORD-1001" as shipped
      And the administrator marks "ORD-1001" as delivered
      Then the order is "DELIVERED"
      And its timeline shows "SHIPPED" then "DELIVERED", each with the administrator and the date
      And the customer received one e-mail for each change

    @BDD-ORD-019 @UC-ORD-006 @FR-ORD-010 @FR-ORD-013 @error @proposed
    Scenario: Delivering an order that has not shipped
      Given a signed-in administrator
      And the order "ORD-1001" is "CONFIRMED"
      When the administrator marks "ORD-1001" as delivered
      Then the change is refused
      And the order is still "CONFIRMED"

  Rule: An administrator settles what the system could not settle alone

    @BDD-ORD-020 @UC-ORD-007 @FR-ORD-014 @nominal
    Scenario: An administrator retries the failed step of an order under review
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW" because its refund failed
      And the payment provider works again
      When the administrator retries the failed step with the comment "provider back"
      Then the payment is refunded in full
      And the order is "REJECTED"
      And the decision is recorded with the administrator and the comment

    @BDD-ORD-021 @UC-ORD-007 @FR-ORD-014 @FR-PAY-006 @nominal
    Scenario: An administrator rejects and refunds an order under review
      Given a signed-in administrator
      And the order "ORD-1001" is "UNDER_REVIEW" with a captured payment and reserved stock
      When the administrator rejects the order with the comment "stock damaged"
      Then the payment is refunded in full exactly once
      And the reserved stock is released exactly once
      And the order is "REJECTED"
      And the customer is told the outcome by e-mail
