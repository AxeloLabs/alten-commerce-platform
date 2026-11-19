# alten-commerce-platform

An e-commerce order-management platform, specified before it is built: six Spring Boot
services, an Angular storefront behind a web gateway, Google Pub/Sub and PostgreSQL, on GKE
Autopilot. Hexagonal architecture, an orchestrated order saga, a transactional outbox.

**Status: the specification is complete; the code has not started.**

## Contents

- [Read the specification](#read-the-specification)
- [Rebuild the PDFs](#rebuild-the-pdfs)
- [How the repository is organized](#how-the-repository-is-organized)

## Read the specification

The deliverable is 47 numbered PDF documents, from the business need to the prompts that
build the software. They are attached to the latest
[release](https://github.com/AxeloLabs/alten-commerce-platform/releases) as one archive.
Start with `00-overview/00-02-architecture-big-picture.pdf`.

The sources are in [`doc/2-spec/`](doc/2-spec/), written in AsciiDoc and PlantUML. GitHub
shows their text, but not their diagrams: read the PDFs.

## Rebuild the PDFs

```
doc/2-spec/build.sh            # builds the 47 PDFs into doc/9-generated/pdf
doc/2-spec/build.sh --check    # identifiers and traceability only
```

Prerequisites: Podman, Python 3, and for the BPMN diagrams Node with pnpm and Chrome or
Chromium. Everything else runs in a pinned container image. `mise install` installs the
project toolchain.

## How the repository is organized

| Path | Content |
|---|---|
| `doc/2-spec/` | The specification: sources, shared theme, build and identifier checks |
| `doc/3-reviews/` | Independent reviews of each part, kept as written |
| `CLAUDE.md` | Instructions for the AI coding agents that will build the code |
| `mise.toml` | The pinned toolchain |

The specification was written with an AI assistant, and each part was reviewed by an
independent agent that did not see the author's reasoning. The code will follow it one
creation prompt at a time (document `08-03`).
