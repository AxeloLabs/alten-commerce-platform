# Relecture indépendante du LOT 4 — architecture

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les six documents du LOT 4 (`04-02` à `04-07`) au commit `7555578`, le brief, et les lots précédents, sans connaître le raisonnement de l'auteur. Verdict : cohérent sur les conteneurs, les sujets, les appels synchrones et la correspondance entre points d'entrée et commandes, mais pas encore bon pour construire ; 1 remarque bloquante, 6 majeures, 8 mineures.

## 2. État des corrections

Toutes les remarques sont corrigées par le commit qui précède celui de ce fichier (« spec LOT 4 : corrections de la relecture indépendante »). Ces corrections n'ont pas été relues par un tiers.

| N° | Gravité | Sujet | Où c'est corrigé |
|---|---|---|---|
| 1 | bloquante | Règles ArchUnit incompatibles avec les conventions (journalisation, annotations, modèles des ports, encodeur) | `04-03` : paquet `application.model`, annotations de marquage et façade de journalisation admises, règles AR-PLT-001, 002, 004, 016, 018, 026 réécrites ; l'encodeur de messages est un port |
| 2 | majeure | Produit retiré visible par un visiteur ; quantité exacte nécessaire au panier et à la commande | `04-05` : lecture publique « introuvable » pour un brouillon ou un produit retiré ; `/v1/product-references`, réservé aux acteurs connectés et non routé depuis l'extérieur ; ADR-PLT-021 complétée |
| 3 | majeure | Recherche par mot-clé sur le nom seul, accents | `04-04` : nom et description dans les trois stockages, accents retirés |
| 4 | majeure | Spring Modulith : ce qu'un module publie, configuration par module, propriétaire de l'unité de travail | `04-03`, section des modules |
| 5 | majeure | Verrous et transactions : un verrou ne peut pas couvrir « charger, décider, sauver » | `04-04` : écritures du stock dans l'ordre des SKU à la sauvegarde ; les tâches planifiées prennent un bail ; colonnes `claimed_until` ; la tâche d'échéance passe par un cas d'utilisation |
| 6 | majeure | Origine du schéma H2 | `04-04` et ADR-PLT-014, 015 : schéma généré depuis les entités pour H2, entités validées contre le schéma PostgreSQL migré |
| 7 | majeure | L'émulateur Firestore ne prouve ni les index ni la concurrence ; catégories absentes du modèle | `04-04` : suite de contrat rejouée sur le vrai Firestore en pipeline ; collection et fichier des catégories |
| 8 | mineure | Taille de page au-delà du maximum | `04-05` : ramenée au maximum |
| 9 | mineure | Panier quand le catalogue est en panne | `04-05`, `04-06` : derniers prix connus, signalés, pas de checkout |
| 10 | mineure | Raisons réelles du choix de PostgreSQL | `04-04`, ADR-PLT-013 |
| 11 | mineure | Clés de signature en cache ; échange de jeton ; autre fournisseur d'identité | ADR-PLT-020, 021 |
| 12 | mineure | Liste des données personnelles incomplète | `04-04` : messages et sessions ajoutés |
| 13 | mineure | Règles non vérifiables faute de marqueurs | `04-03` : annotations de marquage, convention de nommage des tests |
| 14 | mineure | Couverture du brief : tranches verticales, chorégraphie, technologie par pattern de résilience, Spring Cloud Circuit Breaker | ADR-PLT-002, 025 ; `04-06` : tableau de résilience avec technologie, cas et réaction |
| 15 | mineure | Réplicas en production ; configuration des stockages inactifs | `c4-deployment.puml` ; `04-04`, règles de l'échange |

Décisions validées par ax le 2026-11-19 à la porte du LOT 4 : la passerelle web en bordure (ADR-PLT-018) et le relais du jeton de la personne entre services (ADR-PLT-021).

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais). Les numéros de ligne visent les sources au commit `7555578`.

### Verdict

LOT 4 is consistent on containers, topics, synchronous calls and the endpoint-to-command mapping, but it is not yet fit to build from. Its ArchUnit rule set contradicts its own conventions, and several API and persistence statements contradict validated use cases and acceptance scenarios.

### Findings

**BLOCKER** — 04-03:206, :205, :232, :97 — "depend only on application, domain and the Java platform" — The first use case cannot pass the rules. (a) :185 wants structured logging in use cases, which needs a non-platform logging API. (b) :95 allows nullness annotations; JSpecify annotations are bytecode dependencies that ArchUnit reports against AR-PLT-001/002. (c) AR-PLT-016 makes every application.port type an interface, and the layout (:75-88) has no package for use-case inputs, results or the read models of 04-04:55; in "usecase" they create a cycle (AR-PLT-005). (d) "Must not use: Another adapter", yet the unit of work (out.persistence) stores "Protobuf bytes, already encoded" (03-06:78) produced by out.messaging. Correction: whitelist JSpecify and one logging facade, add an application.model package, define an encoder port.

**MAJOR** — 04-05:228, :227 — "Published or retired; never a draft" — Public endpoints return retired products to anyone; 01-05:93 denies it and BDD-CAT-005 expects "not found". Root cause: :303 "No endpoint exists for services only". Also :227 returns "availability" where FR-CART-004, FR-ORD-003 and 02-01:125 need the numeric quantity. Correction: 404 on public reads; an authenticated read of referenced SKUs carrying the quantity; amend ADR-PLT-021.

**MAJOR** — 04-04:130, :186 — "on the product name" — US-CAT-002: "A keyword matches the name and the description". Also the "simple" text-search configuration does not ignore accents; the unaccent extension is needed. Correction: index descriptions in both stores, or amend the story.

**MAJOR** — 04-03:123 — "each with its own three rings" — In Spring Modulith every sub-package of a module is internal by default: "sagas" can reach nothing of "orders", and a top-level "config" becomes a third module. 02-02 saves saga and order in one transaction while AR-PLT-010 confines entities: the owning module is undefined. Correction: name the published interfaces, per-module configuration, and the owner of that unit of work.

**MAJOR** — 04-04:126-127; c4-component-order.puml:31 — "Locked for update in SKU order" — Use cases never open a transaction; load and save are separate transactions. A row lock or skip-locked claim cannot span load-decide-save or claim-handle; 04-06 "Waiting under contention" is really version-conflict retries. The diagram's deadline task queries the database directly, against AR-PLT-018. Correction: say locks live inside the unit-of-work transaction, define claiming as a lease, route the task through a port.

**MAJOR** — 04-04:261-264 — "H2 in PostgreSQL mode" — Nothing creates the H2 schema: migrations "are PostgreSQL SQL" and ADR-PLT-014 dismisses generated schemas. Correction: specify its source; validate entities against migrated PostgreSQL.

**MAJOR** — 04-04:187, :266 — "composite index" / "Firestore emulator" — The emulator does not track compound indexes and lacks full transaction behavior. Contract tests there prove neither indexes nor "exactly one succeeds". Correction: run them on real Firestore in the test environment. Related gap: categories have no collection or file.

**MINOR** — 04-05:92 — "a larger size is refused" — UC-CAT-001 3b and BDD-CAT-003 return 100. Clamp.

**MINOR** — 04-06:64 — "cannot be priced while the catalog is down" — UC-CART-002 2c returns last known prices, which 02-02 stores. Align; answer 200, not 503.

**MINOR** — 04-07:252; 04-04:35 — "which only PostgreSQL offers" — Firestore has multi-document transactions; and notification needs none of the separating guarantees, yet is PostgreSQL-only. State the real reasons.

**MINOR** — 04-07:353, :365, :349 — "since signing keys are cached" — Untrue for new replicas and after cache expiry (not checked against a source). ADR-PLT-021 omits token exchange, and the consequence that one audience must be accepted everywhere. ADR-PLT-020 weighs no other provider, though the brief asks.

**MINOR** — 04-04:299 — "The customer identifier only" — Order events carry the e-mail in retained topics and dead letters; gateway sessions hold tokens with name and e-mail. Complete the list.

**MINOR** — 04-03:254, :234 — AR-PLT-026, "aggregate method" — Nothing marks aggregates or domain services, and tests are named "after the behavior": not checkable as stated. Define markers.

**MINOR** — brief coverage — 04-07 ignores the vertical-slice question; 04-06 lists choreography only as unused, though 03-01 uses it; 04-06 names no technology per resilience pattern; "Spring Circuit Breaker" is neither adopted nor rejected.

**MINOR** — c4-deployment.puml:16 — "each on the order path" contradicts NFR-AVAIL-002. Also 04-04:90: not said how JPA and Flyway auto-configuration is disabled under Firestore or file.

### Checked and clean

- Conventions: strategy boxes open every first-level section; 29 ADRs follow the template; 26 rules.
- Messaging: five topics, seven subscriptions, publishers and consumers match 03-02 and 03-05.
- Endpoints: every REST command and use case maps to one endpoint; payment and notification without REST agree with the authorization matrix.
- Synchronous calls: the four calls match 02-01; none is needed outside a person's request.
- Edge: the gateway flavor fits ADR-PLT-003 and database sessions.
- Also consistent: status codes, ETag handling, outbox and inbox placement, two-phase commit, OpenFeign and load-balancer answers.
- Version numbers: not verified.
