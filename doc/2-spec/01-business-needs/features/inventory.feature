Feature: Inventory
  The store knows what it holds, what is set aside for orders in progress, and what can still be sold.

  Rule: Available quantity is stock on hand minus reserved quantity, and is never negative

    @BDD-INV-001 @UC-INV-001 @FR-INV-001 @FR-INV-007 @FR-INV-008 @nominal
    Scenario: Increasing the stock of a product
      Given a signed-in administrator
      And the product "KB-001" with 3 units on hand and 0 reserved
      When the administrator adds 10 units to "KB-001" with the reason "delivery received"
      Then "KB-001" has 13 units on hand and 13 available
      And a stock movement of +10 is recorded with the reason and the administrator
      And the catalog shows "KB-001" as "IN_STOCK" within 5 seconds

    @BDD-INV-002 @UC-INV-001 @FR-INV-006 @error
    Scenario: Decreasing the stock below the reserved quantity
      Given a signed-in administrator
      And the product "KB-001" with 5 units on hand and 4 reserved
      When the administrator removes 2 units from "KB-001" with the reason "damaged"
      Then the adjustment is refused
      And "KB-001" still has 5 units on hand

    @BDD-INV-003 @UC-INV-001 @FR-INV-002 @FR-INV-003 @invariant
    Scenario: Concurrent reservations never make the available quantity negative
      Given the product "KB-001" with 5 units on hand and 0 reserved
      When 10 orders each try to reserve 1 unit of "KB-001" at the same time
      Then exactly 5 reservations are held
      And exactly 5 reservations are rejected
      And "KB-001" has 0 units available

  Rule: A reservation that is neither confirmed nor released in time expires

    @BDD-INV-005 @UC-ORD-001 @FR-INV-004 @edge
    Scenario: A reservation expires
      Given the product "KB-001" with 5 units on hand
      And a reservation of 2 units of "KB-001" held for the order "ORD-1001"
      When the reservation lifetime elapses without confirmation or release
      Then the reservation is expired
      And "KB-001" has 5 units available

  Rule: The administrator sees the three stock quantities

    @BDD-INV-004 @UC-INV-002 @FR-INV-002 @nominal
    Scenario: Reviewing the products that are low on stock
      Given a signed-in administrator
      And the stock levels
        | sku    | on hand | reserved |
        | KB-001 | 20      | 2        |
        | CB-001 | 6       | 3        |
        | AC-001 | 0       | 0        |
      When the administrator reviews the products that are low or out of stock
      Then the list shows
        | sku    | on hand | reserved | available |
        | CB-001 | 6       | 3        | 3         |
        | AC-001 | 0       | 0        | 0         |
