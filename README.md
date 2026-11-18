# alten-commerce-platform

Plateforme de **commerce et d'e-paiement** en microservices — projet de **spécification** : aucun code à ce stade, uniquement l'architecture, les décisions et leurs justifications.

## Sommaire

- [Objectif](#objectif)
- [Périmètre](#périmètre)
- [Parti pris](#parti-pris)
- [Phases](#phases)
- [Organisation prévue du dépôt](#organisation-prévue-du-dépôt)
- [Statut](#statut)

## Objectif

Produire un dossier de spécification complet et défendable pour une plateforme de commerce avec paiement en ligne, en montrant la démarche d'un architecte senior : chaque choix est consigné avec ses alternatives écartées et son coût.

## Périmètre

- **Commerce** : catalogue, panier, commande, stock, notification (découpage en services à arbitrer en phase d'architecture).
- **E-paiement** : cycle de vie du paiement, idempotence, cohérence entre services, réconciliation, conformité (SCA/PSD2, PCI-DSS, RGPD).
- **Transverse** : sécurité, observabilité, déploiement et exploitation, un cas d'usage d'intelligence artificielle.

## Parti pris

- **Spécification d'abord** : pas de code avant que les décisions structurantes soient posées.
- **Architecture hexagonale** (ports et adapters) au sein de chaque service.
- **Microservices**, avec back-end **Java / Spring Boot** et front-end **Angular**.
- Tout autre choix technique (messagerie, bases de données, cloud, IA) est tranché par un **ADR** (Architecture Decision Record) et non posé par défaut.

## Phases

| Phase | Contenu | Livrables |
|---|---|---|
| 0 — Cadrage | Acteurs, cas d'usage, exigences non fonctionnelles chiffrées, contraintes réglementaires | Vision, glossaire, exigences |
| 1 — Architecture | Découpage en contextes, services, cohérence distribuée, choix synchrone / asynchrone | Carte des contextes, ADR |
| 2 — Spécifications détaillées | Contrats d'API, modèle de données, états du paiement, sécurité, structure du front | Contrats, modèles, scénarios |
| 3 — Plateforme et exploitation | Déploiement, CI/CD, observabilité, objectifs de fiabilité (SLO), runbooks, cas d'usage IA | Dossier d'exploitation |
| 4 — Revue | Revue adversariale de cohérence et de défendabilité | Rapport de revue, corrections |

## Organisation prévue du dépôt

```
docs/
  00-cadrage/
  01-architecture/      # dont adr/
  02-specifications/
  03-exploitation/
  04-revue/
```

## Statut

Cadrage en cours — aucun choix technique n'est encore figé.
