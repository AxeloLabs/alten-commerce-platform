# Relecture indépendante du LOT 6 — plateforme et exploitation

## Sommaire

1. [Ce que c'est](#1-ce-que-cest)
2. [État des corrections](#2-état-des-corrections)
3. [Rapport du relecteur](#3-rapport-du-relecteur)

## 1. Ce que c'est

Rapport rendu le 2026-11-19 par un relecteur indépendant, qui a lu les sept documents du LOT 6 (`06-01` à `06-07`) au commit `1ab45d4`, le brief et les lots précédents, sans connaître le raisonnement de l'auteur. Verdict : la disposition, les plages d'adresses et la liste des portes sont saines, mais le lot n'est pas bon pour construire ; 2 remarques bloquantes, 13 majeures, 2 mineures.

## 2. État des corrections

EN COURS. Plan de correction arrêté le 2026-11-19, à dérouler document par document ; une ligne passe à « fait » quand son commit existe.

| Remarque | Correction retenue | Documents | État |
|---|---|---|---|
| Livraison impossible telle qu'écrite (Cloud Deploy exige Skaffold, canari par route) | Cloud Deploy abandonné : GitHub Actions construit ET livre, Helm applique ; migrations par un hook Helm avant mise à jour ; pas de partage de trafic, mise à jour pod par pod avec retour arrière automatique ; approbation par l'environnement protégé `prod` de GitHub ; nouvel ADR-PLT-031 qui remplace ADR-PLT-027 | `06-05`, `06-03`, `06-02`, `06-04`, `04-07`, `04-01` | à faire |
| Exercices de bascule et de restauration sur l'instance partagée | Bascule : fenêtre annoncée, jamais nocturne automatique. Restauration : clone temporaire que seul le job d'exercice atteint, vérifié puis supprimé | `06-05`, `06-07`, `05-02` | à faire |
| Restauration « au plus 5 minutes perdues » | Procédure écrite : clone à l'instant voulu, extraction de la seule base abîmée, rechargement dans l'instance vivante, job de rapprochement avec les voisins ; perte jusqu'à un jour en cas de perte de région | `06-07` | à faire |
| DNS local au nœud (169.254.20.10) et serveur de métadonnées (169.254.169.254) absents | Ajoutés au plan d'adressage et aux flux autorisés | `06-02`, `05-04` | à faire |
| Automatisme à 90 % du budget sans consommateur | Profil POC : destruction programmée par un workflow planifié, le budget n'est qu'une alerte. Profil complet : une fonction abonnée aux messages de budget pose un verrou de dépense que tout pipeline lit avant de réveiller un environnement | `06-06`, `06-04` | à faire |
| « Fermer la boutique : rien de perdu » | Fermer l'entrée, laisser les sagas se vider, puis mettre à zéro ; rouvrir sous 7 jours | `06-07`, `06-06` | à faire |
| Détruire et recréer l'intégration contredit les interdictions | Deux jobs de destruction explicites et revus : destruction complète du profil POC, reconstruction de l'intégration ; protections réservées à la production | `06-04`, `06-06`, `06-07` | à faire |
| Budget « appliqué par le propriétaire » contre « rien hors pipeline » | Une racine Terraform `owner`, seule exception documentée, appliquée par le propriétaire | `06-04`, `06-06`, `06-07` | à faire |
| Réplicas 2 à 4 contre 2 à 6 exigé ; budget de connexions sans le pod de remplacement | 2 à 6 ; pools de 5 (services d'une saga) et 3 (les autres) ; pod de remplacement compté ; 382 connexions sur 500 | `06-03`, `04-04` | à faire |
| Jobs d'exploitation : numéros faux, actions manquantes, pas d'identité, pas de véhicule | Numéros corrigés ; jobs ajoutés (fin de sessions, redémarrage, mise en quarantaine, rapprochement) ; lancés par des workflows manuels protégés ; identités d'exploitation et de migration | `06-07`, `06-02`, `06-04` | à faire |
| Chiffres de coût incohérents et non vérifiés | Section refaite avec les tarifs vérifiés le 2026-11-19, par profil ; coûts hors Google cités | `06-06` | à faire |
| Perte de région : images et état dans la région | Registre et bucket d'état multi-régions ; perte de données jusqu'à un jour dite | `06-02`, `06-04`, `06-07` | à faire |
| Admission des images : mécanisme non nommé | Autorisation binaire en mode bloquant avec un attestateur ; attestation créée par le pipeline ; images tierces recopiées dans notre registre | `06-02`, `06-05`, `06-04` | à faire |
| La vérification nocturne ne voit pas ce qui est fait à la main | Rôles sensibles gérés de façon exclusive ; inventaire nocturne des ressources sans l'étiquette `managed-by` | `06-04`, `06-06` | à faire |
| Accès à Grafana et à la console Keycloak, canal d'astreinte, sonde externe, hébergement de l'analyse de code | Accès par le proxy d'identité de Google ; canal de notification par e-mail ; sonde déclarée dans Terraform ; analyse de code sur l'édition hébergée, absente du profil POC | `06-02`, `06-05`, `05-03` | à faire |
| Alertes sans runbook et runbooks sans alerte | Runbooks R21 et R22 ajoutés ; alerte de bascule de la base ; trois runbooks déclenchés par une personne | `06-07`, `05-03` | à faire |
| Routes et certificat décrits dans deux outils ; identifiant du fournisseur d'e-mail ; YAML | Routes dans les charts, certificat dans Terraform ; aucun secret pour le fournisseur simulé ; YAML rappelé | `06-04`, `06-03`, `05-04`, `06-07` | à faire |

Profil POC décidé par ax (ADR-PLT-030) à écrire dans les mêmes documents : un environnement réveillé, un réplica, requêtes réduites, petite base sans redondance, ni pare-feu managé, ni adresse de sortie, ni domaine acheté, ni Grafana ; destruction programmée ; budget de 10 €.

## 3. Rapport du relecteur

Texte du relecteur, conservé tel quel (anglais). Les chemins sont relatifs à `doc/2-spec/` ; « 06-0x » désigne `06-platform-operations/06-0x-*.adoc` au commit `1ab45d4`. « Verified » : vérifié par le relecteur sur les pages de docs.cloud.google.com (Cloud Deploy, Cloud SQL, GKE, Binary Authorization, Billing).

### Verdict

Not fit to build from. The layout, address ranges and gate list are sound, but the delivery mechanism cannot work as described, and several procedures contradict the shared-instance decision or the lot's own prohibitions.

### Findings

**BLOCKER** — 06-05:104, 06-07:210-211 — "the failover drill run on integration every night" — One instance exists (06-02:28): this fails over production nightly (a minute of refusals, 05-02:155). The restore drill is a point-in-time recovery, which always creates a new instance (verified): a copy of production data, against 06-01:149, unmanaged and billed. Fix: drills on a disposable instance, or an accepted production window.

**BLOCKER** — 06-05:100 — "The release serves a quarter of the traffic" — Cloud Deploy's Gateway canary needs an HTTPRoute per workload (verified); only two workloads have one, the six services are reached by cluster name or Pub/Sub. Cloud Deploy requires a Skaffold configuration and applies rendered manifests (verified), yet 04-01:422 rejects Skaffold; "migration job first" (06-03:169) then has no mechanism. Fix: state the strategy per workload type, the render path, migrations as a pre-deploy step.

**MAJOR** — 06-07:141 — "at most 5 minutes of data are lost" — The restore is instance-wide: every service and environment returns to the instant before the damage. No steps for the switch, nor for Terraform adopting the new instance (06-06:203 forbids state edits); command topics retain nothing (03-05:52). Fix: write the procedure; extract the one database from the clone.

**MAJOR** — 06-02:82 — "10.30.0.10 ... The name service" — Autopilot pods resolve through 169.254.20.10, and Workload Identity needs 169.254.169.254 ports 80/8080 (both verified). Neither is in the plan nor in 05-04:223-226: default-deny cuts DNS and credentials. Fix: add both.

**MAJOR** — 06-06:139 — "Automatic at 90 %" — Nothing consumes the budget messages (none in 06-02/06-04); every merge wakes test (06-01:24) and nightly tests wake integration, undoing level 1. Fix: name the subscriber and a latch that pipelines honor.

**MAJOR** — 06-07:183 — "Lost: nothing" — Subscriptions keep messages 7 days (03-05:92): a longer closure drops pending cancellations and refunds; scaling everything at once strands charged orders. Fix: state the limit; close the entry, drain, then scale.

**MAJOR** — 06-07:212 — "Destroy and recreate integration" — Contradicts 06-04:125-126 and 06-06:168,203: destroy is forbidden, not a pipeline job, databases and secrets are protected. 06-04:125 protects "the state buckets" that 06-04:165 creates by hand. Fix: a reviewed integration-only job, or drop it.

**MAJOR** — 06-06:102-103 — "applied by the owner" — Versus the `shared` root applied by the pipeline (06-04:78), "by hand" (06-04:167, 06-07:231), and "terraform apply outside the pipeline" forbidden (06-06:203). The brief asks for automation. Fix: one separate root, one documented exception.

**MAJOR** — 06-03:112-115 — "2 to 4" — NFR-SCAL-001 says 2 to 6 (01-07:176); payment is "capped at three" (06-03:145). 200+110+60=370 is right but omits the surge pod (06-03:170) and canary pods: 430, 86 % of 500, above the 80 % of 04-04:145. 500 overrides a default of 400 at 8 GB (verified). Fix: amend one; budget the surge.

**MAJOR** — 06-07:57-60 — "Replay dead letters ... R03", "Send an e-mail again ... R08" — Should be R02 and R07. R17, R18, R19 (end sessions, restart, scale one workload) need actions forbidden by 06-06:187,201; no job exists. 06-02:234-243 gives no identity to operations jobs, migrations (04-04:143; 06-04:92 counts 8), collector, Grafana; no vehicle, since Actions never reaches production (06-05:154).

**MAJOR** — 06-06:59,79 — "Around a hundred euros"; "divides the bill by about three" — By 06-06:72-75 pods are two fifths, so asleep is 60 % of awake: the figures cannot all hold. Prices not verified. Code-analysis server, image scans, CI minutes omitted.

**MAJOR** — 06-07:149 — "deploy the last release" — Images are in "One repository in the region" (06-02:206); state bucket location unstated (06-04:82); the data lost with daily backups is unsaid (up to a day, not verified).

**MAJOR** — 06-02:157 — "Only images signed by the pipeline" — Mechanism unnamed, absent from 06-04:33. Binary Authorization's Sigstore check is monitoring-only, public-key, preview (verified). Keycloak, collector, Grafana images unaddressed.

**MAJOR** — 06-06:177 — "a grant made by hand shows in the nightly check" — A plan sees managed resources only; hand-made resources and additive grants are invisible. Fix: authoritative bindings; an inventory check on `managed-by`.

**MAJOR** — gaps — No access path to Grafana (06-02:176) or the Keycloak console (06-07:237; port-forward forbidden), no paging channel, no resource for the outside probe. SonarQube hosting, deferred here by 04-01:288, is undecided; its token is main-only (06-05:157) while its stage runs on pull requests (06-05:64).

**MINOR** — 06-07:16 — "Every alert ... names a runbook" — "Unexpected errors", "Invalid requests" (05-03:228-229) and drift have none; R14-R16, R19 have no alert.

**MINOR** — 06-04:96 puts routes in Terraform, 06-04:34 in Helm; certificate in both (06-03:193, 06-04:59); e-mail provider "Simulated" (06-01:106) versus its credential (06-07:236); cluster deletion protection (06-06:164) not verified; YAML preference not restated.

### Clean

Ranges do not overlap; Google's fixed ranges are right and no proxy-only subnet is needed (from memory). Pub/Sub counts match 03-05; probes and the 60 s shutdown fit 05-02. "A budget does not stop anything" holds: spend caps exclude these services (verified). Request ratios are valid on Autopilot (verified). The gcloud commands exist (from memory). Load balancer versus gateway, Jenkins, MCP, CLI are answered (ADR-018/019/027, 04-01:427, 08-01).
