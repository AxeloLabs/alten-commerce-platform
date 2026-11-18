Feature: Identity and access
  Visitors become customers, people sign in, and each function is reached only by the roles entitled to it.

  Rule: An account is identified by a unique e-mail address and starts as a customer

    @BDD-IAM-001 @UC-IAM-001 @FR-IAM-001 @FR-IAM-002 @nominal
    Scenario: Registering with a new e-mail address
      Given no account exists for "alice@example.com"
      When a visitor registers with the e-mail address "alice@example.com" and a valid password
      Then an account exists for "alice@example.com"
      And its only role is "CUSTOMER"
      And its cart is empty

    @BDD-IAM-002 @UC-IAM-001 @FR-IAM-001 @error
    Scenario: Registering with an e-mail address that is already used
      Given an account exists for "alice@example.com"
      When a visitor registers with the e-mail address "alice@example.com" and a valid password
      Then the registration is refused
      And exactly one account exists for "alice@example.com"

  Rule: Every function except reading the catalog requires an authenticated actor

    @BDD-IAM-003 @UC-IAM-002 @FR-IAM-003 @nominal
    Scenario: Signing in with valid credentials
      Given a customer "alice@example.com"
      When she signs in with her password
      Then she is signed in as "alice@example.com" with the role "CUSTOMER"
      And she can open her cart

    @BDD-IAM-004 @UC-IAM-002 @FR-IAM-007 @error
    Scenario: Signing in with a wrong password
      Given a customer "alice@example.com"
      When she signs in with a wrong password
      Then the sign-in is refused
      And the message does not say whether the address or the password is wrong

    @BDD-IAM-005 @UC-IAM-002 @FR-IAM-003 @error @critical-path
    Scenario: A visitor is asked to sign in before using the cart
      Given a visitor who is not signed in
      When the visitor adds the product "KB-001" to the cart
      Then the visitor is asked to sign in
      And no cart is created

  Rule: A role reaches only its own functions, and a customer only their own data

    @BDD-IAM-006 @UC-IAM-002 @FR-IAM-005 @error @critical-path
    Scenario Outline: A customer cannot use an administration function
      Given a signed-in customer
      When the customer tries to <action>
      Then the action is refused as forbidden
      And nothing is changed

      Examples:
        | action                              |
        | create a product                    |
        | change the price of "KB-001"        |
        | retire the product "KB-001"         |
        | adjust the stock of "KB-001"        |
        | resolve an order under review       |

    @BDD-IAM-007 @UC-IAM-002 @FR-IAM-004 @invariant @critical-path
    Scenario: A customer cannot read another customer's order
      Given a customer "alice@example.com" with the order "ORD-1001"
      And a signed-in customer "bob@example.com"
      When Bob opens the order "ORD-1001"
      Then the answer is "not found"
