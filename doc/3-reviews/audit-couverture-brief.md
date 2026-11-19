# Audit de couverture du brief — toute la spécification

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport de l'auditeur](#3-rapport-de-lauditeur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un auditeur indépendant, en lecture seule. Il a relevé dans le brief (`doc/1-prompt/1a-prompt-initial.md`) chaque demande, question, contrainte et suggestion, puis cherché où la spécification y répond, au commit `21c08e2` (le document `08-05` n'existait pas encore et n'est pas audité). Résultat : 143 points relevés, 136 répondus, 7 répondus en partie, aucun sans réponse, aucun contredit. Il a aussi contrôlé la cohérence de quelques chiffres entre documents et la forme imposée par le brief. Son classement repose sur des recherches ciblées, pas sur une lecture intégrale. Le rapport est conservé tel quel en section 3.

## 2. État des corrections

FAIT le 2026-11-19 : les seize points sont corrigés, par le commit « spec LOT 8 : corrections de la relecture indépendante et de l'audit du brief » qui suit celui de ce rapport. Cette passe de correction n'a pas été relue par un tiers.

Deux choix sont des précisions de règle plutôt que des ajouts de contenu, et se discutent : l'étiquette de rôle d'un document vaut pour toutes ses sections ; « jamais de version tapée » vaut pour la version que la plateforme utilise. La version de Grafana (13.2) vient d'une recherche web du 2026-11-19 qui n'a pas pu être confirmée sur la page officielle : à revérifier à l'installation.

| Remarque | Correction retenue | Documents | État |
|---|---|---|---|
| Question « stratégie » absente de 20 sections de premier niveau (13 epics, 7 groupes de cas d'utilisation) | Une question par section | `01-04`, `01-05` (fichiers `uc/`) | fait |
| « Microfrontends » cité par le brief, jamais traité | Dit en clair : une seule application Angular, pas de micro front ends, et pourquoi | `04-01` | fait |
| Étiquettes de rôle : une ou deux lignes « Owner » par document seulement | Règle écrite : l'étiquette d'un document vaut pour toutes ses sections, sauf mention contraire | `00-01` | fait |
| Mermaid, Graphviz et VS Code jamais nommés | Ajoutés aux outils envisagés et non retenus, avec la raison ; extensions VS Code citées | `04-01`, `08-01` | fait |
| Cloud Build jamais mentionné | Ajouté aux outils envisagés et non retenus | `04-01`, `04-07` | fait |
| Cinq outils avec « Current » au lieu d'un numéro de version | Grafana et Podman ont leur numéro ; Renovate, CodeQL et SonarQube sont des services hébergés, dit comme tel ; nginx n'était pas utilisé (la passerelle web sert l'interface) et passe dans les outils non retenus | `04-01`, `_shared/versions.adoc` | fait |
| Diagrammes de séquence : dix documents sans aucun diagramme, et la règle du guide plus étroite que la phrase du brief sans le dire | La lecture du brief est écrite dans le guide, avec la liste des documents qui portent des diagrammes de séquence | `00-01` | fait |
| Le mot « JWT » n'apparaît nulle part | Nommé là où les jetons sont décrits | `05-04` | fait |
| Schéma de la stack : « Cloud Deploy » encore affiché | Remplacé par GitHub Actions et Helm | `04-01` (schéma) | fait |
| Fournisseur de paiement simulé : dessiné comme un système externe, avec une adresse sortante « pour les appels aux fournisseurs » | Un seul énoncé partout : dans cette version, dans tous les environnements, les deux fournisseurs sont simulés par un adaptateur ; le système externe et l'adresse sortante sont la cible pour un vrai fournisseur | `04-02` (texte et schémas), `06-01`, `06-02` | fait |
| Réplicas : « chaque service » alors que la notification et le fournisseur d'identité font exception | Renvoi explicite aux exceptions | `06-01` | fait |
| Coût du POC : euros dans deux documents, dollars dans le chiffrage | Dollars partout, plafond en euros | `06-01`, `04-07` | fait |
| SonarQube : version d'un serveur alors que l'édition hébergée est retenue | Édition hébergée dite, sans numéro ; le serveur cité comme alternative | `04-01` | fait |
| Renvoi faux vers `08-02` pour les serveurs MCP | Corrigé | `04-01` | fait |
| Neuf plugins listés, cinq commandes d'installation | Les quatre commandes manquantes ajoutées | `08-01` | fait |
| Versions tapées en dur alors que le guide dit « jamais » | La règle est précisée : elle vaut pour la version que la plateforme utilise ; les autres mentions (plage de compatibilité, alternative, norme) restent en clair. Les mentions de NOTRE version passent par l'attribut | `00-01`, `04-01` | fait |

## 3. Rapport de l'auditeur

Texte de l'auditeur, conservé tel quel (anglais). Les chemins sont relatifs à `doc/2-spec/`.

**Coverage audit of `doc/2-spec` against `doc/1-prompt/1a-prompt-initial.md`**

### 1. Overall coverage

I listed 143 distinct items in the brief after merging repetitions (the CLAUDE.md item is excluded). Of these, 136 are ANSWERED, 7 are PARTLY, 0 are NOT ANSWERED and 0 are CONTRADICTED. Every deviation from the brief that I found is stated and justified in `04-01`, `04-07` or `03-03`:
- H2 limited to persistence slices;
- three stores for catalog and cart only;
- OpenFeign, Zipkin, Loki, Jenkins and the Pub/Sub binder replaced;
- stock reserved before payment;
- BootUI in development profiles only.

Classification rests on greps and targeted reads, not on a full reading. The 46 PDFs exist in `doc/9-generated/pdf`, but I did not open them. Nothing was modified.

### 2. Items PARTLY answered (most important first)

1. **Strategy pattern** — "à chaque fois dans la documentation tu utilises le mot stratégie". Twenty first-level sections have no strategy question (listed in section 4). "microfrontends", cited in the brief's cross-layer error question, appears nowhere; `05-01` covers the layers, but there is no statement that the storefront is a single application.
2. **Role tags** — "tags… tout au long de toutes les documentations pour savoir qui est le responsable des parties". The 11 coloured tags exist (`00-01`, `_shared/roles.adoc`). In 38 of 46 documents they appear on only one or two "Owner:" lines (e.g. `03-03` line 27 only, `02-03` line 28 only), so most sections carry no owner. Tagging is per item only in `04-01`, `04-07`, `01-04`, `01-07`.
3. **Diagram tool** — "graphise, ou mermaid, ou point dot… que j'utilise avec VSCode… J'ai pensé à Mermed". PlantUML is chosen (`00-01`, `04-01`). Mermaid, Graphviz and VS Code are never named: they are absent from "What was considered and not retained" in `04-01` and from ADR-PLT-029, and only IntelliJ preview plugins are given (`08-01`:126-127).
4. **CI/CD** — "peut-être que Google a déjà sa technologie". Jenkins is rejected and Cloud Deploy is evaluated then rejected (ADR-PLT-027, ADR-PLT-031). Cloud Build, Google's build service, is never mentioned.
5. **Versions** — "le numéro des versions de toutes les technologies". Five tools carry "Current" instead of a number in `04-01`: Grafana (238), nginx (308), Podman/Docker (324), Renovate (347), CodeQL (367).
6. **Sequence diagrams** — "au moins un diagramme de séquences… dans tous nos documents". They appear in 8 documents (`00-02`, `01-02`, `03-03`, `03-06`, `04-02`, `04-06`, `05-01`, `05-04`). Ten documents have no diagram at all: `00-03`, `01-04`, `01-07`, `01-08`, `03-02`, `03-04`, `04-07`, `06-07`, `07-02`, `08-01`. The spec's own rule (`00-01`:286) is narrower than the brief's sentence and does not say so.
7. **Security** — "JWT et KeyClock". The substance is answered (ADR-PLT-020, `05-04`), but the word "JWT" appears nowhere in the specification; only "signed token" is used.

### 3. Consistency mismatches

- **Delivery tool:** `04-architecture/diagrams/stack-layers.puml:33` still shows "Cloud Deploy"; `04-01`:412 and ADR-PLT-031 (`04-07`:509) reject it.
- **Simulated payment provider location:**
  - `07-03`:48 and `08-01`:180 say it is an adapter inside the payment service, with no container.
  - `04-architecture/diagrams/c4-container.puml:6,34` and `c4-context.puml:11,17` draw it as an external system reached over HTTPS.
  - `06-02`:34,128,217 and `06-01`:60 keep Cloud NAT "for calls to providers" in the full profile, and give "simulated inside" as the proof-of-concept difference.
  - `06-01`:136 and `07-01`:155 say it is simulated in every environment, production included.
- **Replicas:**
  - `06-01`:133 says "each service" has 2 in integration and "2 or more, autoscaled" in prod, and `01-07`:176 (NFR-SCAL-001) says 2 to 6.
  - `06-03`:115 fixes the notification service at 2 in prod, and `06-03`:117 gives the identity provider 1 in integration.
  - The proof-of-concept profile (one replica of everything) is consistent everywhere.
- **Proof-of-concept cost:**
  - The 0.18 USD per hour and 8.50 USD for 48 hours figures agree (`00-02`:247, `06-06`:70,78), and the table sums are correct.
  - Currency drifts: `06-01`:64 says "about four euros per day" where `06-06`:77 says "About 4 USD"; `04-07`:505 says "of the order of ten euros for 48 hours" where `06-06`:78 says 8.50 USD.
- **SonarQube:** `04-01`:288 quotes `{v-sonarqube}` = "2026.5 LTA" (`_shared/versions.adoc`:78), which looks like a self-hosted release name, while `06-05`:66 chooses the hosted edition. To be checked.
- **Cross-reference:** `04-01`:427 sends the reader to `08-02` for MCP servers; the table is in `08-01`:244.
- **Plugins:** `08-01` lists nine plugins (224-232) but only five install commands (237-241).
- **No mismatch found** on:
  - six services;
  - deadlines of 2, 5 and 15 minutes (including `07-03`:58-60);
  - quoted counts against actual definitions: 19 saga scenarios, 29 error codes, 26 architecture rules, 96 acceptance scenarios, 6 critical paths, 43 creation prompts and 14 verification prompts, 40 endpoints, 47 documents.
- **Never quoted in prose:** the counts of use cases (24), functional requirements (66) and decision records (34; the index in `04-07`:36-69 lists all 34).

### 4. Form defects

- **English:** no French text found in `doc/2-spec` (documents, diagrams, features, BPMN sources, build scripts; `node_modules` excluded).
- **Strategy question missing:**
  - `01-04`: the 13 `== EPIC-…` sections, at lines 99, 154, 209, 290, 342, 409, 461, 548, 590, 628, 679, 717, 754.
  - `01-05`, through its hand-written includes `uc/*.adoc`: 7 sections (Identity and access, Catalog, Inventory, Cart and favorites, Order, Payment, Notification).
  - All other documents pass.
- **Typed versions**, against the rule in `00-01`:287:
  - `04-01`:
    - 43: "Java 17 to 27"
    - 44: "Jakarta EE 11"
    - 45-47: "Spring Boot 4.0 and 4.1", "8.x line"
    - 48: "Node.js 22, 24 or 26"
    - 58-61: 3.5, 4.0, 4.1, 4.2
    - 101, 103, 169, 192, 234, 263: "Spring Boot 4", "3.x line"
    - 123, 410: Liquibase "5.0"
    - 258-259: "Java 25"
    - 264: WireMock "version 4"
    - 283: "Maven 4"
    - 287: "Spring Framework 7"
    - 440-441: "Spring Boot 4.2", "Jackson 3", "Jackson 2"
  - `00-01`:457 and `08-01`:67: "Python 3.11".
  - `08-01`:23: "Fedora 44".
  - `03-04`:95: Protocol Buffers "version 3 of the language".
  - `01-07`:119: "TLS 1.2".
  - Standards such as BPMN 2.0, OAuth 2.0 and RFC 9457 are not counted.

`08-05-proposed-claude-md.adoc` was committed during the audit (f53033c). It was not audited for coverage; its five sections pass the strategy-question check and contain no accented characters.
