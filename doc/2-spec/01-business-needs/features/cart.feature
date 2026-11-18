Feature: Cart and favorites
  A customer gathers what to buy, sees what it costs, and keeps track of liked products.

  Background:
    Given a signed-in customer
    And the published product "KB-001" named "Mechanical keyboard" priced 89.90 with 5 units available
    And the published product "CB-001" named "USB-C cable" priced 9.99 with 50 units available

  Rule: A cart line holds one published product, within the quantity limits

    @BDD-CART-001 @UC-CART-001 @FR-CART-002 @FR-CART-006 @nominal
    Scenario: Adding an available product to an empty cart
      Given an empty cart
      When the customer adds 2 units of "KB-001" to the cart
      Then the cart contains 1 line with 2 units of "KB-001"
      And the cart counter shows 2

    @BDD-CART-002 @UC-CART-001 @FR-CART-003 @nominal
    Scenario: Adding a product that is already in the cart
      Given a cart with 2 units of "KB-001"
      When the customer adds 1 unit of "KB-001" to the cart
      Then the cart contains 1 line with 3 units of "KB-001"

    @BDD-CART-003 @UC-CART-001 @FR-CART-002 @FR-CART-004 @edge
    Scenario Outline: Adding up to and beyond the limits
      Given <in cart> units of "<sku>" are already in the cart
      When the customer adds <added> units of "<sku>" to the cart
      Then the addition is <outcome>

      Examples:
        | sku    | in cart | added | outcome  | why                                   |
        | KB-001 | 0       | 5     | accepted | exactly the 5 units available         |
        | KB-001 | 0       | 6     | refused  | above the 5 units available           |
        | KB-001 | 4       | 2     | refused  | the line would exceed availability    |
        | CB-001 | 0       | 10    | accepted | exactly the maximum per line          |
        | CB-001 | 0       | 11    | refused  | above the maximum per line            |
        | CB-001 | 9       | 2     | refused  | the line would exceed the maximum     |

    @BDD-CART-004 @UC-CART-001 @FR-CAT-003 @error
    Scenario Outline: Adding a product that cannot be sold
      Given the product "AC-001" is <situation>
      When the customer adds 1 unit of "AC-001" to the cart
      Then the addition is refused
      And the cart is unchanged

      Examples:
        | situation    |
        | out of stock |
        | retired      |
        | a draft      |

  Rule: Cart amounts are computed from current catalog prices

    @BDD-CART-005 @UC-CART-002 @FR-CART-005 @FR-CART-006 @nominal
    Scenario: Viewing the cart with its totals and counter
      Given a cart with 1 unit of "KB-001" and 3 units of "CB-001"
      When the customer opens the cart
      Then the cart shows
        | sku    | unit price | quantity | line total |
        | KB-001 | 89.90      | 1        | 89.90      |
        | CB-001 | 9.99       | 3        | 29.97      |
      And the cart total is 119.87
      And the cart counter shows 4

    @BDD-CART-006 @UC-CART-002 @FR-CART-005 @FR-CAT-006 @edge
    Scenario: A price change is reflected and flagged in the cart
      Given a cart with 1 unit of "KB-001" added at 89.90
      And the administrator changed the price of "KB-001" to 99.90
      When the customer opens the cart
      Then the line "KB-001" shows the unit price 99.90, flagged as changed from 89.90
      And the cart total is 99.90

  Rule: A line that can no longer be bought is flagged, left out of the totals, and blocks the checkout

    @BDD-CART-013 @UC-CART-002 @FR-CART-010 @FR-CART-005 @FR-CART-006 @edge
    Scenario: A retired product is flagged in the cart and left out of the totals
      Given a cart with 1 unit of "KB-001" and 3 units of "CB-001"
      And the administrator retired "CB-001"
      When the customer opens the cart
      Then the line "CB-001" is flagged as unavailable
      And the cart total is 89.90
      And the cart counter shows 1
      And the checkout is not offered

  Rule: A customer changes quantities and removes lines freely

    @BDD-CART-007 @UC-CART-003 @FR-CART-002 @FR-CART-005 @nominal
    Scenario: Changing a quantity
      Given a cart with 1 unit of "CB-001"
      When the customer sets the quantity of "CB-001" to 4
      Then the cart contains 1 line with 4 units of "CB-001"
      And the cart total is 39.96

    @BDD-CART-008 @UC-CART-003 @FR-CART-006 @edge
    Scenario: Removing the last line empties the cart
      Given a cart with 1 unit of "CB-001"
      When the customer sets the quantity of "CB-001" to 0
      Then the cart is empty
      And the cart counter shows 0

  Rule: A customer has one cart, kept between sessions and devices

    @BDD-CART-009 @UC-CART-002 @FR-CART-001 @FR-IAM-004 @nominal
    Scenario: The cart is kept between sessions
      Given a cart with 2 units of "KB-001"
      When the customer signs out and signs in again on another device
      Then the cart contains 1 line with 2 units of "KB-001"

  Rule: A product appears at most once in the favorites, which survive unavailability

    @BDD-CART-010 @UC-CART-004 @FR-CART-008 @invariant
    Scenario: Marking a product as favorite twice
      Given the customer marked "KB-001" as favorite
      When the customer marks "KB-001" as favorite again
      Then the favorites contain "KB-001" exactly once

    @BDD-CART-011 @UC-CART-004 @FR-CART-009 @edge
    Scenario: The favorites flag products that became unavailable
      Given the customer marked "KB-001" and "CB-001" as favorites
      And "KB-001" is now out of stock
      And "CB-001" is now retired
      When the customer opens the favorites
      Then both favorites are listed, flagged as unavailable

    @BDD-CART-012 @UC-CART-004 @UC-CART-001 @FR-CART-003 @nominal
    Scenario: Adding a favorite to the cart
      Given the customer marked "CB-001" as favorite
      And an empty cart
      When the customer adds the favorite "CB-001" to the cart
      Then the cart contains 1 line with 1 unit of "CB-001"
      And "CB-001" is still a favorite
