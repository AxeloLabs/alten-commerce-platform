# Relecture indépendante du LOT 7 — qualité et tests

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les quatre documents du LOT 7 (`07-01` à `07-04`) au commit `3140a8b`, le brief et les lots précédents, sans connaître le raisonnement de l'auteur. Verdict : pas encore bon pour construire les tests. Deux remarques bloquantes, dix majeures, quatre mineures. Le rapport est conservé tel quel en section 3 ; la section 2 dit ce qui est fait de chaque remarque.

## 2. État des corrections

À CORRIGER — plan arrêté le 2026-11-19, avant toute modification des documents.

| Remarque | Correction retenue | Documents | État |
|---|---|---|---|
| BLOQUANT — fiche TI-ORD-012 impossible : personne n'achète quand l'inventaire est arrêté, et une réservation tenue est confirmée au retour | Nouveau moyen de contrôle : une « porte » entre un sujet et son consommateur, tenue par le banc de test, qui retient un type de message pour un participant pendant que celui-ci continue de tourner. La fiche laisse expirer la réservation, met le stock à zéro, relance en administrateur. TI-ORD-013 est amené par un rejet d'administrateur | `07-03` | à faire |
| BLOQUANT — TI-ORD-009 : un redémarrage dure plus que l'échéance de 5 s | Deux profils de délais pour les scénarios : « rapide » (échéances en secondes, on gèle ou on retient, jamais de redémarrage) et « réel » (délais de production, pour les scénarios de redémarrage). Le test de l'outbox coupe le relais par configuration | `07-03`, `03-06` | à faire |
| Délais « dans le même ordre qu'en production » : faux (limite d'appel 10 s, tâche d'échéance, durée de vie de la réservation) | Une table qui met à l'échelle TOUS les réglages de temps ensemble | `07-03` | à faire |
| Où tournent les scénarios de saga : contradiction entre `07-01`, `07-03` et `06-05` | Un seul endroit : une composition de conteneurs, dans le pipeline. Étape ajoutée au pipeline. Sur un environnement déployé : seulement le sous-ensemble pilotable par les jetons | `07-01`, `07-03`, `06-05` | à faire |
| Fenêtres de quelques millisecondes impossibles à viser (« arrêté après la réservation », « dès que la capture est observée ») | Retenir un type de message AVANT de passer la commande ; geler au lieu d'arrêter ; le balayage « arrêt à chaque étape » devient « traité, tué, relivré » | `07-03` | à faire |
| Niveau des scénarios d'acceptation : `07-01` contredit `01-08` ; des scénarios de chemin critique exigent une panne qu'un navigateur ne provoque pas | Tous les scénarios tournent dans un seul processus, sur le code métier des services avec des adaptateurs en mémoire, comme `01-08` le dit. Les scénarios de chemin critique qui demandent une panne portent une étiquette et ne sont pas rejoués par le navigateur | `07-01`, `07-02`, `01-08`, `04-03` | à faire |
| H2 absent de `07-01` alors que `04-04` et ADR-PLT-015 y renvoient | Tests de tranche de persistance sur H2 ajoutés : niveau, outil, entrée au catalogue | `07-01`, `07-02` | à faire |
| Performance : pas d'autoscaling en intégration, limite de débit par adresse, modèle de charge incohérent, mesure attribuée à tort à Gatling | Cible avec autoscaling nommée, exemption de l'injecteur, modèle ouvert à débit d'arrivée fixe, phrase sur la mesure retirée | `07-04` | à faire |
| Couverture : 17 règles sans test au catalogue, inscription et connexion non testées, et la fabrication ne vérifie pas « toute règle a un test » | Entrées ajoutées ; la fabrication refuse désormais une règle métier sans test | `07-02`, `_tools/ids.py` | à faire |
| Alertes : huit alertes sans test ; « alerte levée » affirmé là où aucun système d'alerte ne tourne | Table complétée ; en conteneurs on affirme la mesure, pas l'alerte | `07-03` | à faire |
| `tok_error` : rejet impossible si l'annulation échoue aussi | L'annulation réussit ; précisé dans les règles métier | `01-06`, `07-03` | à faire |
| TI-ORD-003 et TE2E-ORD-003 instables selon l'ordre d'arrivée | En conteneurs : l'événement de disponibilité est retenu. De bout en bout : les deux issues sont acceptées | `07-03`, `07-02` | à faire |
| Mineur — message rejoué « comme un message neuf » : un second e-mail | Réservé aux commandes | `07-03` | à faire |
| Mineur — « toutes les lignes de la table des pannes » : il en manque | Lignes ajoutées ou phrase corrigée | `07-03` | à faire |
| Mineur — test de fumée avec un compte de test en production | Aligné sur `06-01` | `07-02`, `07-04` | à faire |
| Mineur — séquences générées sans outil ni graine ; collision de TI-ORD-010 impossible à viser | Générateur à graine imprimée ; la porte relâche la réponse à l'instant de l'échéance | `07-01`, `07-03` | à faire |

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais). Les chemins sont relatifs à `doc/2-spec/` ; « 07-0x » désigne `07-quality-testing/07-0x-*.adoc` au commit `3140a8b`. « Not verified » : le relecteur n'a pas pu contrôler ce point sur une source.

### Verdict

Not yet. The strategy, the catalog and the unit-level proof are sound, but the multi-service saga scenarios cannot be built as written (delays, means of control, place of execution), and several coverage and "where it runs" claims contradict validated lots.

### Findings

**BLOCKER** — 07-03:128 (TI-ORD-012) — "the unit bought by another customer meanwhile … Start the inventory" — Nobody can buy while the inventory is stopped, and on restart a HELD reservation is confirmed whatever its age (02-03:459): the order ends CONFIRMED. 03-03:356 goes through P17, absent from the sheet. TI-ORD-013 (:129) inherits it. — Add a control that holds one participant's commands while its interface and tasks run; let the reservation expire, adjust the stock to zero, retry as administrator. Arrange 013 by an administrator's rejection.

**BLOCKER** — 07-03:50, :119 (TI-ORD-009) — "order deadline of 5 s" / "reaches the outcome of TI-ORD-001" — Restarting the inventory or the order service takes longer than 5 s: P04 rejects TIMED_OUT first. The outbox test the brief asks for fails by construction. — Delays per scenario, longer than a measured restart.

**MAJOR** — 07-03:50, :63 — "the same order as in production" — False: the provider call limit stays 10 s (05-02:102), above the deadline, so "shorter than the time limit of the call, hence than the order deadline" is wrong; the deadline task runs "every few seconds" (03-06:214); TI-ORD-018 (:110) needs stop and start within 15 s; TI-ORD-015 (:130) "still reserved" lapses at 45 s. — One table scaling every setting together.

**MAJOR** — 07-01:58, :206 vs 07-03:222 — "after deployment, in test and integration" / "in the composition of containers of the pipeline" — Contradictory. 06-05:53-68 has no such stage and promises 15 minutes (:70); delays are not among the values that differ (06-01:129-142); the scale-to-nothing job cannot hit "after the reservation". — Choose one place; add the stage to 06-05.

**MAJOR** — 07-03:52, :110, :117, :127, :131, :159 — "stopped after the reservation" with tok_ok; "as soon as the capture is observed"; "after its transaction and before its acknowledgement" — Millisecond windows with no means to hit them; TI-ORD-007 usually passes without exercising the restart; the payment service has no interface to observe (04-05:292). — tok_slow, freeze instead of stop, stop the order service before the capture; declare a fault hook or drop that sweep.

**MAJOR** — 07-01:131 — "runs as a component test of that service … critical path runs end to end as well" — 01-08:54 says in-memory adapters. Scenarios assert across services (stock, cart, e-mail); the 25 @critical-path ones include a restart (BDD-ORD-011), a one-hour outage (BDD-ORD-035), a stale catalog (BDD-ORD-003), which Playwright through screens (07-02:204) cannot provoke. — State the level per scenario; bind failure scenarios to the saga harness; amend 01-08.

**MAJOR** — 07-01, whole — H2 never appears — 04-04:266, :278 and ADR-PLT-015 defer "which test goes where" to 07-01; the brief imposes H2. — Add level, tool, catalog entry.

**MAJOR** — 07-04:207, :252 — "replicas were added" on integration — No autoscaler there (06-03:143). :199: one injector address meets limits "by address", stricter on checkout (05-04:222). :173-178: 100 customers pausing "a few seconds" cannot produce 50 requests per second; open or closed model unstated. :218 "from the instant a request was due": not a Gatling measure (not verified). — Name an autoscaled target, an injector exemption, an arrival-rate model.

**MAJOR** — 07-01:24, 07-02:285 — "has no test fails the build … today" — The build enforces only CP→TE2E and SC→TI (_tools/ids.py:56-71). Seventeen rules appear in no catalog entry: FR-IAM-001/002/003/006/007, FR-CAT-006/011, FR-INV-007, FR-CART-001/003/006/009, FR-ORD-005/013, FR-PAY-003/004, FR-NOT-001; FR-IAM-006 in no scenario either. Untested: registration (UC-IAM-001), slowing of failed sign-ins (05-04:68), refresh token reuse (05-04:309), NFR-AVAIL-005. — Add entries; enforce FR→test.

**MAJOR** — 07-03:203-216 — "Each alert must fire within 5 minutes of its cause" — Eight alerts of 05-03:214-233 have no test: slow burn, subscription backlog, database connections, pod restarting, failover, unexpected errors, invalid requests, access refused. "Orders under review" needs 30 minutes. Sheets assert "the alert raised" (:127) where no alerting backend runs. — Complete; assert the metric in containers.

**MAJOR** — 07-03:67 vs :196 — "Fails every call" / "rejected uncharged when it closes" — Rejection needs a cancellation that succeeds. — Define tok_error's cancellation; 01-06 is silent.

**MAJOR** — 07-03:105, 07-02:211 — "at the same instant" — If the catalog copy refreshes first, the second checkout is refused (FR-ORD-003) and no order is rejected: flaky. — Accept both outcomes, or hold the availability event.

**MINOR** — 07-03:118 — "once as a new message": an event with a new identifier gives a second e-mail (03-06:52). Commands only.

**MINOR** — 07-03:178 — "Every row … appears here": not Catalog, Cart, Pub/Sub (05-02:191-193), nor the zone test (05-02:234).

**MINOR** — 07-02:217, 07-04:251 — smoke with a test account, smoke load "everywhere": 06-01:181 forbids generic accounts in prod; the smoke skips checkout although 07-01:82 says critical paths.

**MINOR** — 07-01:114 — generated sequences: no tool, no seed. 07-03:120: TI-ORD-010 cannot aim its collision.

### Clean

Counts and ranges of 07-02 (36/26/30/10); P01–P23, C01–C06 and both answer tables have unit entries; outcomes of sheets TI-ORD-001, 002, 004, 006, 011, 015, 016, 017, 019 agree with 02-03 and 03-03; tokens match 01-06; schemas and filters go to the real bus; proof-of-concept exclusions match 06-01; nothing assumes a second factor.
