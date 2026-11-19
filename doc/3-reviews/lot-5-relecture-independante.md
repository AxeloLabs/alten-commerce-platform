# Relecture indépendante du LOT 5 — préoccupations transverses

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les quatre documents du LOT 5 (`05-01` à `05-04`) au commit `6cf6c09`, le brief et les lots précédents, sans connaître le raisonnement de l'auteur. Verdict : squelette sain, mais pas encore bon pour construire ; 1 remarque bloquante, 8 majeures, 9 mineures. Toutes les corrections demandées touchent le texte de ce lot, aucune ne remet en cause une décision antérieure.

## 2. État des corrections

Toutes les remarques sont corrigées par le commit « spec LOT 5 : corrections de la relecture indépendante », qui suit celui de ce rapport. Ces corrections n'ont pas été relues par un tiers.

| N° | Gravité | Sujet | Où c'est corrigé |
|---|---|---|---|
| 1 | bloquante | Jeton de renouvellement à usage unique présenté deux fois par des requêtes parallèles | `05-04` : renouvellement une fois par session, sous verrou de la session |
| 2 | majeure | « Rien n'a été changé » faux quand la réponse n'arrive pas à temps | `05-01` : code `ERR-PLT-011` (504, issue inconnue) ; `04-05` ; le checkout est renvoyé avec le même identifiant |
| 3 | majeure | Annulation de paiement jamais rejouée ; limite de 3 s incompatible avec un paiement lent mais valide | `02-03`, `03-02`, `03-03`, `05-02` : l'annulation reste non acquittée et revient jusqu'au retour du fournisseur ; limite d'appel à 10 s |
| 4 | majeure | Limites de temps non emboîtées | `05-02` : budget décroissant par saut, requêtes SQL sous la limite de la lecture |
| 5 | majeure | Fournisseur d'identité en panne : comportement de la passerelle non spécifié | `05-02`, `05-04`, `05-01` : session conservée, `ERR-IAM-001`, réglages de l'appel |
| 6 | majeure | Keycloak sur le même hôte que la boutique | `05-04`, `06-01`, `06-02`, `api-routing.puml` : nom d'hôte propre, seules les adresses de connexion routées, clients par défaut désactivés |
| 7 | majeure | Un pod compromis voit les jetons relayés ; sortie possible par les API Google | `05-04` : risques résiduels nommés ; `06-02` : périmètre de service en évolution |
| 8 | majeure | Réponses sans corps du pare-feu et du load balancer ; statuts 405, 413, 415 | `05-01` : règle de la boutique pour les réponses sans code ; `ERR-PLT-001` étendu ; `05-02` : un pod ne devient pas indisponible quand la base tombe |
| 9 | majeure | Erreurs de la couche conteneur absentes | `05-01` : tableau des erreurs du conteneur et de la plateforme |
| 10 à 18 | mineures | Liste des flux réseau autorisés ; une trace par commande ; mesure de la disponibilité et fenêtres de consommation du budget ; alertes alignées ; métriques manquantes ; compteur d'envois d'e-mail ; vérification d'adresse e-mail retirée ; décision répétée ; états du disjoncteur | `05-04`, `05-03`, `05-02`, `05-01`, `04-05`, `03-03` |

Décisions d'ax du 2026-11-19, inscrites avec ces corrections : les trois risques (une région, un cluster, une instance de base partagée) sont acceptés (`05-02`) ; aucun second facteur à la connexion, pour personne (`05-04`).

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais). Les chemins sont relatifs à `doc/2-spec/` ; « 05-04:69 » désigne la ligne 69 de `05-cross-cutting/05-04-security-architecture.adoc` au commit `6cf6c09`.

### Verdict

LOT 5 is not yet fit to build from: one session rule fails by construction, and some ten settings or claims contradict the saga, the API guidelines or what the edge can do. The skeleton is sound, and every correction below changes this lot's text, not an earlier decision.

### Findings

**BLOCKER** — 05-04:69 — "Refresh tokens are single-use… a reused one ends the session" — The storefront sends parallel requests (cart counter, order polling) to two or more gateway replicas, so two renewals with one refresh token are certain and the second ends the session; nothing serializes renewal. Fix: one renewal per session (lock or version on the session row), the loser re-reads. Keycloak's behavior on reuse: not verified.

**MAJOR** — 05-01:119, :233; 05-02:90, :111 — "Nothing was changed" — ERR-PLT-008 is the only code left when the gateway's 5 s limit expires on POST /orders, yet the order may be committed and will be charged; the sample message says "Nothing was charged". Fix: an "outcome unknown" code (504) that makes the storefront resubmit the same checkout identifier.

**MAJOR** — 05-02:210 against :109 and 02-03 P11 — "payments canceled when the provider returns" — Nothing re-sends CancelPayment: P11 "sends nothing". While the breaker is open (30 s), charge and cancellation are "unknown" at once, so every order of the window waits for an administrator: 60 at peak. Also :93: past 3 s a charge is "unknown" and P07 cancels at once, so UC-ORD-001 7a (slow, yet before the order deadline) cannot happen. Fix: leave CancelPayment unacknowledged while the provider is unreachable; align the limit with 7a.

**MAJOR** — 05-02:92, :99 — "A limit is always shorter than the limit of the caller above it" — Checkout nests order→cart→catalog (04-05:298-299), both at 400 ms with one retry, above a 2 s statement limit (:95); the cart's fallback can never arrive in time. Fix: a decreasing budget per hop; statement limit below the read limit.

**MAJOR** — 05-02:62, :214; 05-01:128 — "signed-in users continue until their token expires" — That is 5 minutes (05-04:69); then carts, checkout and administration stop. What the gateway answers when renewal fails is unspecified; gateway→identity provider has no time limit or retry (:112 covers keys only); ERR-IAM-001 has no producer, registration being a direct link (04-05:289). Fix: specify it; keep the session, answer ERR-IAM-001.

**MAJOR** — 05-04:63, :87; trust-boundaries.puml:31 against api-routing.puml:16 — "sign-in pages only" vs "/auth/**" — Keycloak shares the store's host. The public paths are not listed (admin console, master realm), nor are its built-in browser clients said to be disabled: a script in the page could obtain real tokens by a silent same-origin flow (not verified). Fix: path allow-list, built-in clients off, or a separate host.

**MAJOR** — 05-04:227-228 — "holds one service's rights" — It also holds every relayed token, valid on all services (ADR-PLT-021): a taken-over inventory pod receives ADMIN tokens and may call the catalog's /v1/admin (:221 allows it). "Cannot… call out to the internet": Google API endpoints serve every project, so data can leave without a service perimeter (not verified). Fix: state the residual risk.

**MAJOR** — 05-01:67, :118; 05-04:220 — "Every refusal and every failure… problem-details" — 429 and firewall 403 come from Cloud Armor, 502/503 from the load balancer when no gateway pod is ready (05-02:131, :183 make every pod unready during a failover): no code, no trace identifier, no retry time (not verified). 405, 413, 415 have no code. Fix: a storefront rule for answers without a code; map those statuses.

**MAJOR** — 05-01:44-56 — brief: "les erreurs dans Docker", "toutes les couches : Docker, microservices…" — No container or platform layer: failed start, wrong configuration, missing secret, memory kill, crash loop, failed migration, image pull. Neither answered nor deferred. Fix: one layer row and a table, or a pointer to 06-03.

**MINOR**, one line each:
- 05-04:221-224 — the allow-list omits load balancer and health checks → gateway and identity provider, services → trace collector, metric scraping across namespaces (:222), identity provider → database, DNS.
- 05-03:56, :64, :156 against :66 — every hop continues the trace, so a saga is one trace, not "one per exchange"; where sampling is decided is unsaid.
- 05-03:184, :191 — "entry point" undefined (gateway metrics are blind when no gateway is ready); no burn windows, no synthetic probe.
- 05-01:26, :252 "first occurrence" against 05-03:224 "a sustained rate otherwise"; the alert of 05-01:250 does not exist in 05-03.
- 05-03:116, :126, :176 — NFR-REL-005 (p99 5 s) has no metric; 03-03's "events with no effect" and "compensations", and the order reads of NFR-PERF-001, are missing.
- 05-02:110 against 03-05:91, 05-03:215/:220 — how "the last attempt" is known is unsaid; a dead letter would page for a "ticket".
- 05-04:66 "verification of the e-mail address" against UC-IAM-001 step 6, "can sign in at once"; Keycloak's mail credential is absent from :177-185.
- 05-01:163 against 04-05:147 — a repeated decision: 409, or the order?
- 05-02:105-110 — brief: circuit breaker not illustrated; half-open unspecified.

### Checked and clean

The eleven {v-…} tokens exist in _shared/versions.adoc. The 28 codes use the statuses of 04-05; every exception flow of the six uc files maps to a code, an identity-provider page or a named outcome. Two retries match tok_flaky; delays, redelivery (5 s–5 min, 10 attempts) and retention agree with 03-03, 03-05, 03-06; alerts cover what 03-03 marks as alerting. Roles, ownership, public reads and inter-service calls agree with the matrix, 04-05 and ADR-PLT-018 to 021.
