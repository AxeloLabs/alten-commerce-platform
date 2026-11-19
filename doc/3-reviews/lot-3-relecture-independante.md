# Relecture indépendante du LOT 3 — domaine et événements

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les neuf PDF des dossiers `02-domain-design` et `03-event-driven-architecture`, les documents métier validés et le brief, sans connaître le raisonnement de l'auteur. Verdict : pas encore bon pour construire ; 6 remarques bloquantes, 10 majeures, 4 mineures.

Les références de lignes visent les sources `.adoc` et `diagrams/*.puml` au commit `5c827d6`.

## 2. État des corrections

Aucune remarque n'est encore corrigée. Ordre conseillé par le relecteur : remarques 1 à 6 d'abord, dans `02-03-state-machines.adoc`, sous la forme d'UNE matrice complète état × événement (état `SUSPENDED` compris, et réponses du service de paiement selon son statut), puis réalignement de `03-03`, `02-01` et des diagrammes de classes et de tables. Les remarques de messagerie (11 à 13, 15) sont des corrections locales.

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais).

Bases for the references below: `doc/2-spec/02-domain-design/` (files 02-xx) and `doc/2-spec/03-event-driven-architecture/` (files 03-xx). Line numbers are those of the `.adoc` and `diagrams/*.puml` sources; the nine PDFs match them.

## Findings

**1. BLOCKER — A suspended saga has no rule for the answer it was waiting for.** `02-03-state-machines.adoc` l.25, l.155-166; 03-03 SC-ORD-011 (`diagrams/sc-ord-011.puml` l.17-21).
- Quote: "an unexpected event in a given state is refused or ignored"; the `SUSPENDED` rows list only the three administrator actions.
- Problem: the unanswered command stays in the participant's subscription (SC-ORD-004 relies on this) and runs when the service returns. In SC-ORD-011 the queued `ConfirmReservation` decrements on-hand stock, and `ReservationConfirmed` is dropped by the suspended saga. If the administrator then rejects, the refund succeeds and `ReleaseReservation` is a no-op on a `CONFIRMED` reservation (l.237-238): order `REJECTED`, stock lost. The same applies to `PaymentCaptured`, `PaymentCanceled`, `PaymentRefused` and `StockReturned`, so the "payment captured / unknown" guard is stale.
- Correction: add "`SUSPENDED` × answer of the remembered step → handled as in that step", list the other events, and never drop `ReservationConfirmed` or `PaymentCaptured` (reject after confirmation sends `ReturnStock`).

**2. BLOCKER — `CANCELING_PAYMENT` has no exit on `PaymentRefused`.** `02-03-state-machines.adoc` l.123-130, l.220-221; `03-02-command-event-catalog.adoc` l.86.
- Quote: `CancelPayment` is answered by "{EVT-PAY-004} or {EVT-PAY-001}".
- Problem: the payment service is slow or was down, the order deadline queues `CancelPayment` behind `ChargePayment`, then the provider declines. `PaymentRefused` has no row and is ignored; `CancelPayment` on a `REFUSED` payment has no transition and no listed answer. The order goes under review, where retry and reject both resend `CancelPayment` and confirm is refused.
- Correction: add "`CANCELING_PAYMENT` × `PaymentRefused` → `ReleaseReservation`, reject `PAYMENT_REFUSED`". Add a table of the payment service's answer to `CancelPayment` and `RefundPayment` in every status, including "no payment yet" and UC-PAY-002 1b "nothing to refund", which has no event.

**3. BLOCKER — Deadlines are undefined once an administrator resumes a saga.** `03-03-order-saga-specification.adoc` l.96, l.105-107; `02-03-state-machines.adoc` l.79-81, l.147, l.150-153; `diagrams/saga-place-order.puml` l.32-35.
- Quote: "Each saga row holds two instants, set when the saga starts."
- Problem: after retry, confirm or reject the saga is in a working state with both instants in the past. Read literally, the deadline task re-suspends it seconds later, before the answer arrives. If deadlines are one-shot, a silent participant leaves it working forever, not counted as suspended and out of reach of administrator commands. `REFUNDING_PAYMENT` is absent from the review-deadline row, though the diagram note and 03-03 l.102 say "any state still working". The states table gives order statuses that are false after a resume.
- Correction: "each administrator action sets a new review deadline"; add `REFUNDING_PAYMENT` to the row (same for the cancel saga); say which deadline is handled first when both are due.

**4. BLOCKER — `ReturnStock` is not idempotent, so an administrator retry counts the stock twice.** `02-03-state-machines.adoc` l.197-198; `diagrams/saga-cancel-order.puml` l.18; `diagrams/class-inventory.puml` l.33-38; `02-02-domain-model.adoc` l.90.
- Quote: "Sends again the request of the remembered step"; `ReservationStatus` = `HELD, CONFIRMED, RELEASED, EXPIRED`.
- Problem: a cancel saga suspended in `RETURNING_STOCK` still has its first `ReturnStock` queued. The retry sends a second one with a new identifier, which the inbox cannot catch, and nothing in the inventory model records that the order's stock was already returned. On-hand is inflated and overselling becomes possible (NFR-REL-002).
- Correction: add reservation status `RETURNED` (`CONFIRMED` → `RETURNED`), in the lifecycle diagram too; a repeated `ReturnStock` answers `StockReturned` from state.

**5. BLOCKER — The administrator's rejection is specified three different ways.** `02-03-state-machines.adoc` l.124-130, l.164-166; `03-03-order-saga-specification.adoc` l.357; `diagrams/sc-ord-015.puml` l.22-28.
- Quote: "Payment unknown: sends `CancelPayment`. Sends `ReleaseReservation`." against SC-ORD-015, which releases after `PaymentCanceled` and ends "`REJECTED` with `ADMIN_DECISION`".
- Problem: the table releases at once and rejects with `TIMED_OUT`; the scenario releases afterwards with `ADMIN_DECISION` (FR-ORD-018). If the cancellation answers "already captured", the table sends `ConfirmReservation`: the order is confirmed against the decision, on a reservation just released. Confirming a `RELEASED` reservation has no defined answer.
- Correction: record "rejection requested". In `CANCELING_PAYMENT`: `PaymentCanceled` → release, reject `ADMIN_DECISION`; `PaymentCaptured` → `RefundPayment`. Release only once no payment is held.

**6. BLOCKER — "Payment service down" contradicts the saga.** `02-01-bounded-contexts-context-map.adoc` l.152; `02-03-state-machines.adoc` l.119-121; `03-02-command-event-catalog.adoc` l.81, l.85.
- Quote: "New orders are rejected at the order deadline, uncharged."
- Problem: per 02-03 the deadline only sends `CancelPayment`, which queues behind `ChargePayment`. Every order goes under review at 5 minutes, and when the service returns, the charge is executed, up to 7 days later. `ReserveStock` carries an expiry time; `ChargePayment` carries none. No scenario covers this, though 01-02 lists "the provider or the payment service does not answer".
- Correction: fix the row; add a "not after" instant to `ChargePayment` (past it the payment is recorded `CANCELED` and nothing is charged); add the scenario.

**7. MAJOR — The order model and tables cannot hold what the transition tables need.** `diagrams/class-order.puml` l.54-78; `diagrams/er-order.puml` l.38-48; `diagrams/er-inventory.puml` l.13-20; `03-03-order-saga-specification.adoc` l.77.
- Quote: "Remembers the step in progress"; "Refused unless the payment is captured"; "`ADMIN_DECISION` when an administrator asked for it".
- Problem: there is no field or column for the remembered step, the known payment and stock state (UC-ORD-007 step 2 shows them), or the administrator's intent. `CancelOrderSaga` has no review deadline. `reservation` has no `saga_id`, although 03-03 says it does. The payment token must survive from `PlaceOrder` to `StockReserved` but has no home, and "never stored" ignores the outbox payload and Pub/Sub retention.
- Correction: add these fields and columns; restate the token rule as "kept only until charged, encrypted, purged with the outbox row".

**8. MAJOR — Order events cannot produce the e-mails required.** `03-02-command-event-catalog.adoc` l.152-160; `diagrams/er-order.puml` l.6-19.
- Quote: "Order events are self-sufficient: they carry what a listener needs".
- Problem: FR-NOT-004 and UC-NOT-001 require order number, lines, total and status in every e-mail. Only `OrderConfirmed` carries lines and total. The customer's e-mail address "comes from the token" but is stored nowhere, and `OrderShipped` is triggered by an administrator's token.
- Correction: add lines and total to the five other events; add `customer_email` to `orders`.

**9. MAJOR — Idempotence is defined three ways, and a payment can stay `PENDING` forever.** `03-02-command-event-catalog.adoc` l.76; `03-06-reliable-messaging-spring-boot.adoc` l.111, l.180; `02-03-state-machines.adoc` l.216-219.
- Quote: "answers what it answered the first time"; "the provider is not called, the recorded outcome is published again".
- Problem: SC-ORD-013 and SC-ORD-015 need a repeated `RefundPayment` or `CancelPayment` to call the provider again; replaying the first answer makes every administrator retry useless. The provider call sits inside the single transaction of the unit of work. UC-PAY-001 records `PENDING` first; after a crash the redelivered `ChargePayment` finds a payment with no outcome to publish. The notification's "second sending impossible" has the same send-then-commit gap.
- Correction: one rule, "answer from the current status; `PENDING` or a failed attempt means call the provider again with the same reference"; describe the transactions around an external call.

**10. MAJOR — The "no longer expected" table contradicts itself.** `02-03-state-machines.adoc` l.173-177; `03-05-pubsub-topology.adoc` l.113.
- Quote: "the saga sends `RefundPayment` and raises an alert" against "Any event in `COMPLETED` or `COMPENSATED` | Ignored."
- Problem: two rows apply to the same event. A refund sent from a final state has nobody to receive `PaymentRefundFailed`, leaving a rejected order holding a payment (FR-ORD-008). "Cannot happen" is false: a dead-lettered `ChargePayment` replayed after `CancelPayment` was answered charges a rejected order.
- Correction: word the last row "any other event"; let `CancelPayment` on an absent payment record `CANCELED`; say who follows that refund.

**11. MAJOR — Relay ordering does not hold across replicas.** `03-06-reliable-messaging-spring-boot.adoc` l.71-74.
- Quote: "each claims the rows it takes so that two relays never take the same row".
- Problem: with row-level claims, replica A takes row 1 of an order and replica B takes row 2, then publishes it first. The ordering key only preserves the order Pub/Sub received. A row Pub/Sub refuses permanently, for example on schema validation, "is tried again" forever and blocks its key.
- Correction: claim per ordering key (no row taken while an older unpublished row of the same key exists), and park a permanently refused row with an alert.

**12. MAJOR — An unknown message type is both acknowledged and dead-lettered.** `03-04-messaging-contracts.adoc` l.144, l.234-235; `03-06-reliable-messaging-spring-boot.adoc` l.123; `03-05-pubsub-topology.adoc` l.70.
- Quote: "What still arrives unexpectedly is acknowledged and counted." against "Does not acknowledge; after 10 attempts Pub/Sub moves it to the dead-letter topic."
- Problem: adding a message type is declared compatible, and the order service's filter is negative ("everything except"). Under the 03-06 rule a new inventory event blocks its order's key for the whole retry cycle and raises a dead-letter alert.
- Correction: unknown type → acknowledge and count; only a malformed known type is dead-lettered.

**13. MAJOR — `ce-type` does not name the payload actually published.** `03-04-messaging-contracts.adoc` l.48, l.64, l.102, l.117-124.
- Quote: "The full name of the payload type, for example `altencommerce.inventory.v1.StockReserved`"; "The message data is the Protobuf payload, untouched."
- Problem: the topic schema forces the data to be the wrapper `InventoryEvent`; the nested type's real name is `…v1.InventoryEvent.StockReserved`. A developer can publish the bare message, which the topic schema will not accept, or the wrapper. Nothing says which of `ce-type` and the `oneof` wins if they differ.
- Correction: state "data = the topic wrapper; `ce-type` = logical name, must match the `oneof` case, checked by the subscriber".

**14. MAJOR — Nothing says which saga receives an event, or what confirm/reject do to a suspended cancellation.** `03-02-command-event-catalog.adoc` l.133-134; `diagrams/class-payment.puml` l.8; `02-03-state-machines.adoc` l.46-47, l.193-198.
- Quote: "Consumed by: Order sagas".
- Problem: the payment stores the placing saga's identifier. If `PaymentRefunded` for a cancellation echoes it, the event reaches the completed place-order saga and is ignored. `ConfirmOrderUnderReview` and `RejectOrderUnderReview` exist, the cancel saga defines only "retries", and the order table's guard "payment captured and reservation confirmed" would pass for a cancellation whose stock was already returned.
- Correction: "an answer carries the `sagaid` of the command it answers; routing is by `sagaid`"; refuse confirm and reject when the suspended saga is a cancellation.

**15. MAJOR — The inbox is missing where it is needed, and has no retention.** `diagrams/er-catalog-cart-notification.puml`; `03-06-reliable-messaging-spring-boot.adoc` l.28, l.76, l.189-190; `03-05-pubsub-topology.adoc` l.52, l.113.
- Quote: "Four mechanisms, used together in every service".
- Problem: the cart has no inbox table, and `removeOrdered` subtracts quantities, so a redelivered `OrderConfirmed` removes them twice. Inbox retention is never stated, while topic replay and dead-letter replay assume duplicates are recognized for at least 7 days. "One atomic write" over an inbox entry and a per-cart document or file is asserted, not designed.
- Correction: add the inbox to the cart; set retention above the longest replay window; say the inbox entry lives inside the aggregate document for the two non-SQL adapters.

**16. MAJOR — "The product exists" (UC-INV-001) cannot be checked by the inventory.** `02-01-bounded-contexts-context-map.adoc` l.69, l.140-142.
- Quote: "It knows a product only by its SKU."; "The three synchronous calls between our services are reads."
- Problem: there is no inventory-to-catalog relation and the catalog publishes nothing, so `AdjustStock` on a mistyped SKU creates stock for a product that does not exist.
- Correction: either a fourth synchronous read (inventory → catalog), or state that the precondition is not enforced.

**17. MINOR — Names and lifecycles differ between documents.** `02-03-state-machines.adoc` l.52, l.175, l.238; `03-01-business-workflows-commands-events.adoc` l.176; `diagrams/class-inventory.puml` l.33-38.
- `ReservationExpired` is handled in 02-03 but is "not published" and absent from the catalog.
- `ReservationStatus` lacks the `REJECTED` drawn in the lifecycle, and the lifecycle lacks the `EXPIRED` → `CONFIRMED` path the text states.
- `CANCELING` → `UNDER_REVIEW` on "review delay expires" widens the validated 01-06 trigger ("the refund keeps failing").
- Correction: align the three.

**18. MINOR — A version conflict is retried two ways.** `02-02-domain-model.adoc` l.25; `03-06-reliable-messaging-spring-boot.adoc` l.122, l.140; `03-05-pubsub-topology.adoc` l.88.
- Quote: "the use case is retried on the fresh state" against "Does not acknowledge. Pub/Sub delivers the message again, with increasing delays."
- Problem: redelivery costs at least 5 seconds, counts toward the 10 attempts and holds the key; that alone uses the NFR-PERF-003 budget (95th percentile below 5 s).
- Correction: retry in-process a few times, then leave unacknowledged.

**19. MINOR — Types and envelope details.** `02-02-domain-model.adoc` l.98, l.176-177; `diagrams/class-inventory.puml` l.7-8; `03-04-messaging-contracts.adoc` l.52-54, l.104.
- `Quantity` is "1 or more" but types `onHand` and `reserved`, which must reach 0.
- Locking "can never block each other" should read "can never deadlock".
- `Money` is "decimal with two decimals … carried by the message contracts" in 02-02, but integer cents in 03-04.
- `dataschema` is not a URI.
- `sagaid` and `causationid` are not marked optional for `OrderShipped`, `StockAvailabilityChanged` or deadline-triggered commands.

**20. MINOR — Coverage against the brief.** `03-03-order-saga-specification.adoc` l.148-167; `03-01-business-workflows-commands-events.adoc` l.92-101; `03-06-reliable-messaging-spring-boot.adoc`.
- No scenario for: a payment service down, an administrator rejecting a paid order (BDD-ORD-021), a confirmation that succeeds late but before the review delay (UC-ORD-001 8a), or a cancellation with a silent inventory.
- SC-ORD-002 reserves then releases, while the brief says "le stock n'est jamais réservé"; the deviation is flagged only for scenario 3.
- SC-ORD-001 omits the cart reaction.
- The 03-01 failure table has no row for the order deadline while reserving.
- 03-06 is titled "in Spring Boot" but names no Spring or Google client component, though the versions file lists them.

## Verdict

No, not yet. The first pass of the automatic flow is sound, but everything after "the system could not decide alone" is under-specified: what a suspended saga does with late answers, how deadlines work after a resume, and how the administrator's decisions run (findings 1, 3, 5, 7). Two holes then cost stock or strand an order: finding 4 double-counts returned stock, and finding 2 leaves a declined card with no exit. Fix findings 1 to 6 in 02-03 first, as one complete state × event matrix including `SUSPENDED` and the payment service's answers per status, then realign 03-03, 02-01 and the class and table diagrams. The messaging findings (11 to 13, 15) are local corrections.

Checked and clean: catalog counts (25 commands, 19 events) and every name used in 03-01, 03-03 and 02-03 except `ReservationExpired`; topics, subscriptions, filters, dead-letter counts and access rights against the "consumed by" columns; the 12 order transitions, statuses, rejection reasons and payment statuses against 01-06; the 2 / 5 / 15-minute delays; the automatic flow (no path to rejected-with-payment, confirmed-without-`ReservationConfirmed`, double charge or double refund), with SC-ORD-001 to 010 and 014 matching the tables; database support for FR-ORD-006, 009, 017, FR-INV-003 and FR-CART-007; the Pub/Sub facts as stated (at-least-once, no delayed delivery, single top-level Protobuf message without imports, ordering with dead letters, attribute filters).
