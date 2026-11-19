# Relecture indépendante du LOT 8 — usine logicielle et vue d'ensemble

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les documents `08-02`, `08-03`, `08-04` et `00-02` au commit `21c08e2`, les décisions ADR-PLT-032 à 034, le brief et les lots précédents, sans connaître le raisonnement de l'auteur. Il a vérifié plusieurs affirmations sur Claude Code dans sa documentation officielle (« verified »). Verdict : pas encore bon pour démarrer la construction. Deux remarques bloquantes, dix majeures, trois groupes de mineures. Le document `08-05` a été écrit pendant sa lecture : la remarque qui signale son absence est sans objet. Le rapport est conservé tel quel en section 3.

## 2. État des corrections

FAIT le 2026-11-19 : toutes les remarques sont corrigées, par le commit « spec LOT 8 : corrections de la relecture indépendante et de l'audit du brief » qui suit celui de ce rapport. Le catalogue passe de 43 à 51 incréments, le harnais de huit à neuf couches. La fabrication complète passe sans erreur. Cette passe de correction n'a pas été relue par un tiers.

Un point reste à PROUVER et non seulement à écrire : que le build, avec ses conteneurs, tourne bien sous un compte de session sans aucun identifiant cloud. La spécification en fait la condition de fin de l'incrément `CRE-PLT-002` et un risque du registre de `08-04`.

| Remarque | Correction retenue | Documents | État |
|---|---|---|---|
| BLOQUANT — les scénarios d'acceptation d'un cas d'utilisation (22 pour passer une commande) demandent le code de plusieurs services et d'incréments ultérieurs : la condition « fini » d'un incrément de service est inatteignable, et les pistes ne sont pas indépendantes | Les incréments de service sont prouvés par leurs tests unitaires et de composant seulement. Les scénarios d'acceptation sont liés au jalon M2, quand les six services existent, par des incréments à part | `08-03`, `08-04` | fait |
| BLOQUANT — le bac à sable ne peut pas contenir un build qui lance des conteneurs ; une fois exclu, ce build tourne avec les droits du compte, où se trouvent les identifiants cloud du développeur | Les sessions d'agent tournent sous un compte du poste à part, sans aucun identifiant cloud ni clé. C'est ce compte, et non le bac à sable, qui porte la garantie. À prouver sur le poste de référence au premier incrément ; risque inscrit au registre | `08-02`, `08-01`, `08-04` | fait |
| `08-05` absent | Écrit et commité pendant la relecture (`f53033c`) | `08-05` | fait |
| L'outillage de l'usine n'est construit par aucun incrément : autres portes du pipeline, fichiers des experts et leur workflow, hooks, générateur de règles, script du backlog | Incréments ajoutés au jalon M0 ; règle écrite : une étape du pipeline est ajoutée par l'incrément qui crée ce qu'elle contrôle | `08-03` | fait |
| Les scénarios de saga en conteneurs demandent les images des services (jalon M4) et le royaume du fournisseur d'identité (jalon M3) | L'image d'un service est construite par l'incrément du service ; le royaume passe au jalon M0 | `08-03` | fait |
| Tests de bout en bout « sur la plateforme locale » alors que `07-01` dit « déployé » ; pas de lanceur ; incréments de l'interface sans test nommé | Un seul énoncé : les tests de bout en bout tournent contre la plateforme complète, en conteneurs avant le déploiement, puis déployée. Tests de composant de l'interface ajoutés au catalogue et attachés aux incréments | `07-01`, `07-02`, `08-03`, `08-04`, `08-01` | fait |
| Incréments d'infrastructure en désaccord avec `06-04` (ce qui est fait à la main, ce qui est dans `shared`) et oublis : bord, verrou de dépense, attestation, plan nocturne, mise en sommeil, reconstruction de l'intégration | Incréments réécrits d'après `06-04`, `06-05`, `06-06` et `06-07` | `08-03` | fait |
| Coupes de `08-04` : la troisième retire deux scénarios de saga dits « jamais coupés », la quatrième les écrans dont un chemin critique a besoin | Coupes corrigées ; matrice des chemins critiques de `07-02` corrigée | `08-04`, `07-02` | fait |
| Secrets des agents du pipeline en contradiction avec `06-05` ; une branche peut modifier un workflow qui tourne avant la revue | Le jeton de l'agent n'a pas le droit de modifier les workflows ; le workflow des experts tourne depuis la définition de la branche principale et ne fait que lire le code proposé ; la clé du modèle est dans un environnement réservé à la branche principale | `08-02`, `06-05` | fait |
| « Nulle part ailleurs » : faux (un hôte autorisé qui accepte des dépôts, les serveurs d'outils locaux, le navigateur Playwright) | Limites dites telles quelles ; la réponse est que la session ne peut lire que ce dépôt | `08-02`, `08-01` | fait |
| Experts sans shell : plusieurs contrôles infaisables (demandes de fusion, rapports du pipeline, historique, registre) ; instantané d'environnement non spécifié | Entrées fournies en fichiers par un job ; contrôles reformulés ; contenu de l'instantané spécifié | `08-03`, `07-03` | fait |
| « Généré depuis le catalogue » : le catalogue n'a pas de périmètre, l'exemple contient plus que sa ligne | Périmètre par sorte d'incrément ; le prompt est écrit depuis la ligne et gardé dans le dépôt | `08-03` | fait |
| Mineurs, réglages de `08-02` : motifs fragiles, deux modes « désactivés » dont un seul montré, limites valables seulement sans terminal, plan Terraform par l'agent | Extrait corrigé ; affirmations ramenées à ce que le produit fait | `08-02` | fait |
| Mineur, `00-02` : « cinq minutes de plus », panne du fournisseur d'identité absente | Corrigé | `00-02` | fait |
| Mineur, `08-04` : étiquettes, jalons et sous-tickets non créés par les deux commandes ; rien ne ferme une story ; risques manquants | Complété | `08-04` | fait |

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais). Les chemins sont relatifs à `doc/2-spec/` ; « 08-0x » désigne `08-engineering-workflow/08-0x-*.adoc` au commit `21c08e2`. « Verified » : vérifié par le relecteur dans la documentation de Claude Code.

### Verdict

Not yet. The catalog has ordering defects that stop an agent inside M1–M3, and the harness as configured cannot run the project's own build without giving up the guarantee it claims.

### Findings

**BLOCKER** — 08-03:240-242 — "{UC-ORD-001}; {TC-ORD-001}…" — UC-ORD-001 has 22 acceptance scenarios (order.feature: deadlines, review, refund, restart). They need CRE-ORD-005 and CRE-ORD-007 (later) and the inventory, payment, cart and catalog use cases (other tracks). The done-when is unreachable, and line 158 "independent tracks… meet at M2" is false. Fix: attach UC-ORD-001 to CRE-ORD-005/007 and state cross-track prerequisites.

**BLOCKER** — 08-02:139-146, 172 — "Credential locations cannot be read, even by a command that the rules allow" — Verified (Claude Code sandboxing doc): on Linux a sandboxed command cannot reach host localhost, Docker is incompatible, and rootless Podman needs `excludedCommands`, which "run outside the sandbox with your full access". So `./mvnw` with Testcontainers (08-01:159-165) fails, or once excluded runs agent-written code unconfined without asking (line 115). The owner's gcloud login (08-01:193) is on the same account, so lines 70 and 76 ("does not depend on the harness", "nothing more") do not hold. Fix: make the disposable container of line 184 the default, or a separate OS user without cloud credentials; prove it on the reference workstation.

**MAJOR** — 08-03:169 — "Documents … 08-05" — 08-05 (00-01:136, "Proposed CLAUDE.md") does not exist, yet every prompt reads CLAUDE.md (line 88). The brief's two claude.md requests are neither answered nor deferred. 00-02:13 "forty-six other documents" counts it. Fix: write it, or defer explicitly.

**MAJOR** — 08-03:169 — "the pipeline of a pull request with its build stage" — Nothing in the catalog builds the factory's own tooling, so M0 "passes every gate" and line 50 "experts are present from the first pull request" cannot be met. Fix: add M0 increments for:
- the other stages of 06-05:57-69 (secrets, code analysis, dependencies, infrastructure, storefront, documentation);
- the 14 subagent files and their workflow (08-03:853-856);
- the hooks (08-02:249-257) and the generator of rules (08-02:105);
- the backlog script and prompt files (08-04:85, 96).

**MAJOR** — 08-03:262 — "in a composition of containers" — This needs images of six services and the identity provider with its realm (07-03:48). Images come with CRE-PLT-012 (M4) and the realm with CRE-IAM-001 (M3), although CRE-PLT-008 (M0) already needs it. Fix: an image per service in M1, the realm in M0.

**MAJOR** — 08-03:154 — "pass on the local platform" — 07-01:49,59, 07-02:208 and 00-02:283 say "deployed environment". The local platform is dependencies only (08-01:169-178), with services "started from the IDE" (06-01:23), and no increment builds a launcher. Storefront increments (line 281) have no named test, against line 67. 08-04:200 makes a critical-path story done only at M4. Fix: choose one place, add the launcher, name the tests.

**MAJOR** — 08-03:306-311 — "the storage of the states, the federation" — 06-04:138,178-179 and 06-07:259-260 say these are made by hand. CRE-PLT-014 puts network, cluster and database in the "environment module"; 06-04:56-80 puts them in `shared`. No increment names edge, the spending latch (06-06:201), attestor and admission (06-05:181-182), the nightly plan (06-04:129), evening sleep, or rebuild-integration.

**MAJOR** — 08-04:171-172 — "no critical path is affected" — Cut 3 removes CRE-ORD-003, but TI-ORD-014 and TI-ORD-019 are among the nineteen "never cut" (line 175) and sit under CP-ORD-004 (07-02:275). Cut 4 removes the screens TE2E-CAT-001 (CP-CAT-001) drives.

**MAJOR** — 08-02:287 — "The key of the model provider and nothing else" — This contradicts 06-05:201 "The token of the code analysis, and nothing else… Readable by runs of branches". An agent may push a branch that changes a workflow (08-02:92,199); it would run before review with those secrets and the pull-request cloud identity. No control covers this. Fix: define the experts' workflow on main only, keep the key in a protected environment, amend 06-05. GitHub behaviour: not verified.

**MAJOR** — 08-02:305, 373 — "nowhere else" — Verified: the doc warns that allowing `github.com` "can create paths for data exfiltration", and local MCP servers "run with your full access". Playwright (08-01:249) is a browser outside the allow list, neither "our code" (line 175) nor "knowledge, not power" (line 244).

**MAJOR** — 08-03:821-838, 781 — "the pull requests of the milestone" — Experts have reading tools and no shell (lines 421, 854), so several checks cannot be followed:
- VER-PLT-014 cannot read pull requests or pipeline reports.
- VER-PLT-001 check 6 lacks the author's report.
- VER-PLT-005 checks 4 and 7 need history and a registry.
- The snapshot's content, format and identity are specified nowhere.
- VER-PLT-013 check 5 contradicts 07-03:277,303, which leave a dead letter and an open review in `test`.

**MAJOR** — 08-03:93, 852 — "generated from the catalog" — The catalog has no scope column, and the example (lines 365-396) holds reads and conditions absent from its row (line 235). TC-PLT-001 to 004 and 006 are attached to M0, before any service exists. Six tracks all edit `acceptance/`, against "One scope".

**MINOR** — 08-02 settings:
- Line 129: `git commit -m x --no-verify` is not matched and passes line 117 (verified: argument patterns are "fragile").
- Line 126: `Read(./.env)` covers the current directory only (verified).
- Line 157 "two disabled modes": the excerpt has one (`disableAutoMode` exists, verified).
- Line 381: turn and spending limits are print-mode only (verified), so they do not cover workstation sessions.
- Line 98: a plan by the agent contradicts 06-04:160 "Readable by the pipeline only".
- The deny excerpt omits `billing projects unlink`, `subscriptions seek` and `kubectl cp/port-forward` (06-06:261-262).

**MINOR** — 00-02:94 — "after five more" — 03-03:106 says five minutes after placement, not seven. The failure table (lines 127-139) omits the identity-provider outage (05-02:240).

**MINOR** — 08-04:94-98, 117 — The two commands create no sub-issue, milestone or label (not verified), and nothing closes a story. "The script" moving Backlog contradicts line 87. Missing risks: quota or change of the agent product, model cost.

### Clean

- Counts: 43 = 9+18+1+9+6, 41 before the demonstration, 14 experts, 26 rules, 19 scenarios, P01–P23, C01–C06, 96 acceptance scenarios, 29 codes, 39 stories, 13 epics.
- 00-02: delays, objectives, costs, the other failure rows and the Kubernetes box match 01-06, 05-02, 05-03, 06-03, 06-05 and 06-06. Every point of the brief's "architecture globale" is answered.
- Verified in the Claude Code docs: deny/ask/allow order, rules "not a security boundary", the setting names, what the sandbox leaves out, 30-day plaintext transcripts, training and retention terms, telemetry off by default through cloud providers, `--max-turns`, `--max-budget-usd`.
- Not checked against the docs: the telemetry-export, checkpoint, marketplace and subagent-tool claims.
- Brief: Jira, the GKE and gcloud servers, and the six named managers are answered. ADR-PLT-032 to 034 agree with their documents.
