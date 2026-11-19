# alten-commerce-platform

An e-commerce order platform: six Spring Boot services, an Angular storefront behind a
web gateway, Google Pub/Sub, PostgreSQL, on GKE Autopilot.

[Specification](#the-specification-decides) · [Layout](#layout) · [Commands](#commands) ·
[Code](#code) · [Tests](#tests) · [Work](#work) · [Never](#never)

## The specification decides

- `doc/2-spec/` is the source of truth. Read the documents your task names before you write.
  New here? Start with `doc/2-spec/00-overview/00-02-architecture-big-picture.adoc`.
- Never change the specification to fit the code. Where it is ambiguous, incomplete or seems
  wrong: take the most conservative reading and report the point with its identifier.
- Build nothing the specification does not ask for.
- Everything has an identifier (`UC-ORD-001`, `FR-INV-003`, `TU-ORD-005`, `ERR-ORD-002`).
  Keep it in the code: tag each test with its identifier, name an architecture test after
  its `AR` rule, return the `ERR` code of the catalog.

## Layout

| Path | Content |
|---|---|
| `contracts/` | OpenAPI, AsyncAPI, Protobuf. Written first, by hand. |
| `platform-starter/` | Shared technical library. No business type. |
| `services/<name>/` | catalog, inventory, cart, order, payment, notification |
| `web/` | `storefront` (Angular) and `web-gateway` |
| `acceptance/` | Acceptance scenarios, bound to the application code of all services |
| `deploy/` | `terraform/` and `helm/` |
| `doc/` | The specification |

## Commands

| Need | Command |
|---|---|
| Install the toolchain | `mise install` |
| Build and check everything | `./mvnw verify` |
| One service and what it needs | `./mvnw -pl services/order-service -am verify` |
| Format (never by hand) | `./mvnw spotless:apply` |
| Storefront tests | `pnpm --dir web/storefront test` |
| Local platform | `podman compose up -d` |
| Check the specification | `doc/2-spec/build.sh --check` |

## Code

- Three rings in a service: `domain` depends on nothing, `application` on `domain`,
  `adapter` on both. No framework, no persistence or JSON annotation in `domain`.
- A business refusal is a result of the domain, not an exception.
- A change of state and the messages it causes are saved in one unit of work.
  Never publish to Pub/Sub directly: write to the outbox.
- Every message handler is idempotent: the same message twice has its effect once.
- Time and identifiers are given to the domain, never read by it.
- Value objects are records, valid by construction. `Money`, never a bare number.
- No Lombok in `domain` or `application`.
- English everywhere: code, comments, logs, commit messages.

## Tests

- Tests first, from the specification: one test per rule, per cell of a grid.
- `domain` is covered at 100 % of lines and branches. No mocking library in its tests.
- Never make a test pass by weakening it, deleting it or lowering a threshold.
- No `sleep`, no real clock, no data shared between tests.

## Work

- One increment at a time: a creation prompt (`CRE-…`, document `08-03`), on its own
  branch, as one pull request.
- Stay in the scope the prompt gives. Do not touch `contracts/`, `platform-starter/`,
  pipeline definitions or quality thresholds unless the increment is about them.
- No dependency outside document `04-01`, unless you report it with its reason.
- End with the report the prompt asks for: what was built, each test identifier and its
  state, what was not done, every assumption.

## Never

- Deploy, apply infrastructure, or change anything in a cluster or in Google Cloud.
  The pipeline does that.
- Push to `main`, force a push, skip the checks of a commit.
- Read credentials, or put a secret or a real person's data anywhere.
- Work around a refused command. The refusals are those of documents `06-06` and `08-02`.
