Feature: Catalog
  Anyone discovers the products on sale; only the administrator decides what is sold and at what price.

  Background:
    Given the categories "Keyboards", "Cables" and "Accessories"

  Rule: Only published products are visible to visitors and customers

    @BDD-CAT-001 @UC-CAT-001 @FR-CAT-003 @nominal
    Scenario: Browsing lists only published products
      Given the products
        | sku    | name                | status    |
        | KB-001 | Mechanical keyboard | PUBLISHED |
        | KB-002 | Compact keyboard    | DRAFT     |
        | CB-001 | USB-C cable         | RETIRED   |
      When a visitor browses the catalog
      Then the list contains exactly "KB-001"

    @BDD-CAT-005 @UC-CAT-002 @FR-CAT-003 @FR-CAT-005 @error
    Scenario Outline: Viewing a product that is not on sale
      Given a product "KB-009" with the status "<status>"
      When a visitor opens the product "KB-009"
      Then the answer is "not found"

      Examples:
        | status  |
        | DRAFT   |
        | RETIRED |

  Rule: An administrator sees the products of every status

    @BDD-CAT-017 @UC-CAT-001 @FR-CAT-011 @nominal
    Scenario: An administrator lists drafts and retired products
      Given a signed-in administrator
      And the products
        | sku    | status    |
        | KB-001 | PUBLISHED |
        | KB-002 | DRAFT     |
        | CB-001 | RETIRED   |
      When the administrator lists the products with the status "DRAFT" or "RETIRED"
      Then the list contains exactly "KB-002" and "CB-001"

  Rule: Catalog lists are paginated and can be filtered and sorted

    @BDD-CAT-002 @UC-CAT-001 @FR-CAT-010 @nominal
    Scenario: Filtering by category and price range
      Given the published products
        | sku    | category  | price |
        | KB-001 | Keyboards | 89.90 |
        | KB-003 | Keyboards | 149.00 |
        | CB-001 | Cables    | 9.99  |
      When a visitor searches the category "Keyboards" with a price between 50.00 and 100.00
      Then the list contains exactly "KB-001"

    @BDD-CAT-003 @UC-CAT-001 @FR-CAT-007 @edge
    Scenario: Asking for more than the maximum page size
      Given 150 published products
      When a visitor asks for a page of 500 products
      Then the page contains 100 products
      And the total number of results is 150

  Rule: The displayed availability follows the available quantity

    @BDD-CAT-004 @UC-CAT-002 @FR-CAT-008 @edge
    Scenario Outline: Viewing a product shows its availability level
      Given a published product "KB-001" with <available> units available
      When a visitor opens the product "KB-001"
      Then its availability is "<level>"

      Examples:
        | available | level        |
        | 0         | OUT_OF_STOCK |
        | 1         | LOW_STOCK    |
        | 5         | LOW_STOCK    |
        | 6         | IN_STOCK     |

  Rule: A product has a unique SKU and a price within the allowed range

    @BDD-CAT-006 @UC-CAT-003 @FR-CAT-001 @nominal
    Scenario: Creating a product as a draft
      Given a signed-in administrator
      When the administrator creates the product "KB-010" named "Silent keyboard" in "Keyboards" at 59.00
      Then the product "KB-010" exists with the status "DRAFT"
      And a visitor who opens the product "KB-010" gets "not found"

    @BDD-CAT-007 @UC-CAT-003 @FR-CAT-001 @error
    Scenario: Creating a product with a SKU that already exists
      Given a signed-in administrator
      And a product "KB-001"
      When the administrator creates the product "KB-001" named "Another keyboard" in "Keyboards" at 59.00
      Then the creation is refused as a conflict
      And the product "KB-001" is unchanged

    @BDD-CAT-008 @UC-CAT-003 @FR-CAT-002 @edge
    Scenario Outline: Creating a product with a price at and beyond the limits
      Given a signed-in administrator
      When the administrator creates the product "KB-011" named "Test keyboard" at <price>
      Then the creation is <outcome>

      Examples:
        | price     | outcome  |
        | 0.00      | refused  |
        | 0.01      | accepted |
        | 99999.99  | accepted |
        | 100000.00 | refused  |
        | 10.999    | refused  |

  Rule: An update never overwrites a change it has not seen

    @BDD-CAT-009 @UC-CAT-004 @FR-CAT-001 @nominal
    Scenario: Updating the description of a product
      Given a signed-in administrator
      And a published product "KB-001"
      When the administrator changes the description of "KB-001" to "Hot-swappable switches"
      Then a visitor who opens "KB-001" reads "Hot-swappable switches"

    @BDD-CAT-010 @UC-CAT-004 @FR-CAT-009 @error
    Scenario: Updating a product that someone else just changed
      Given two signed-in administrators who both opened the product "KB-001"
      And the first administrator saved a new name
      When the second administrator saves a new description
      Then the update is refused as a conflict
      And the current version of "KB-001" is returned

  Rule: A price change applies to future orders only

    @BDD-CAT-011 @UC-CAT-005 @FR-CAT-006 @FR-ORD-002 @invariant @critical-path
    Scenario: Changing a price does not change an order already placed
      Given a published product "KB-001" priced 89.90
      And a confirmed order "ORD-1001" with 1 unit of "KB-001" at 89.90
      And a customer cart holding 1 unit of "KB-001"
      When the administrator changes the price of "KB-001" to 99.90
      Then the order "ORD-1001" still shows "KB-001" at 89.90
      And the cart shows "KB-001" at 99.90, flagged as changed

  Rule: Publishing puts a product on sale, retiring withdraws it for good

    @BDD-CAT-012 @UC-CAT-006 @FR-CAT-004 @nominal
    Scenario: Publishing a complete draft
      Given a signed-in administrator
      And a draft product "KB-010" with a name, a description, a category and a price
      When the administrator publishes "KB-010"
      Then a visitor who browses the catalog sees "KB-010"

    @BDD-CAT-015 @UC-CAT-006 @FR-CAT-004 @error
    Scenario: Publishing an incomplete draft
      Given a signed-in administrator
      And a draft product "KB-012" with a name and a price, but no description and no category
      When the administrator publishes "KB-012"
      Then the publication is refused
      And the missing description and category are listed
      And the product "KB-012" is still a draft

    @BDD-CAT-016 @UC-CAT-006 @FR-CAT-005 @invariant
    Scenario: A retired product is never published again
      Given a signed-in administrator
      And a retired product "KB-001"
      When the administrator publishes "KB-001"
      Then the publication is refused
      And the product "KB-001" is still retired

    @BDD-CAT-013 @UC-CAT-006 @FR-CAT-005 @nominal
    Scenario: Retiring a product keeps it readable where it is referenced
      Given a published product "KB-001"
      And a confirmed order "ORD-1001" containing "KB-001"
      And a customer who marked "KB-001" as favorite
      When the administrator retires "KB-001"
      Then a visitor who browses the catalog does not see "KB-001"
      And the order "ORD-1001" still shows "KB-001"
      And the customer's favorites show "KB-001" flagged as unavailable

    @BDD-CAT-014 @UC-CAT-006 @UC-INV-001 @UC-CART-001 @FR-CAT-003 @FR-INV-007 @nominal @critical-path
    Scenario: A newly published product becomes purchasable
      Given a signed-in administrator
      And a complete draft product "KB-010" priced 59.00
      And the administrator added 20 units to the stock of "KB-010"
      When the administrator publishes "KB-010"
      Then within 5 seconds a visitor sees "KB-010" at 59.00 with the availability "IN_STOCK"
      And a customer can add "KB-010" to the cart
