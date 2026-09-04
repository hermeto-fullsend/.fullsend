# Design Document Review

Review criteria for Hermeto design documents. Apply these when reviewing
PRs that add or modify files under `docs/design/`.

## Required sections

Every design document must include the following. Flag missing sections
as `missing-section` findings with severity `high`.

### Overview

- Brief description of the package manager and its use cases.
- **Developer Workflow**: prerequisites, adding dependencies, dependency
  management, build process.
- **How the Package Manager Works**: registry model, package identity,
  dependency resolution, configuration options.

### Design

- **Scope**: what is in scope, what is out of scope, edge cases.
- **Dependency List Generation**: how Hermeto produces a machine-readable
  dependency list. May include toolchain details, list format, and
  checksum generation.
- **Fetching Content**: how Hermeto fetches dependencies for the
  `fetch-deps` implementation. Consider native vs Hermeto fetch, project
  structure, file formats, and network requirements.
- **Build Environment Config**: how to configure builds to use pre-fetched
  dependencies (`generate-env` / `inject-files`). Include environment
  variables (table format), configuration files (tree diagrams), and
  build process integration.

### Implementation Notes

- **Current Limitations**: missing features, edge cases, performance
  considerations, ecosystem gaps.
- Note whether the package manager uses the experimental `x-` prefix.

### References (optional but encouraged)

- Links to package manager docs, RFCs, or prior art.

## Quality checks

Flag these as findings when present:

- **No alternative approaches** (`missing-alternatives`, severity `medium`):
  Design documents should present at least two approaches with pros/cons
  before stating a decision.
- **Missing examples** (`missing-examples`, severity `medium`): Key sections
  should include code snippets, config examples, or directory tree diagrams.
- **Scope gaps** (`scope-gap`, severity `medium`): The scope section should
  explicitly address common edge cases: workspaces/monorepos, platform-
  specific dependencies, vendoring, and lockfile formats.
- **Inconsistency with existing backends** (`consistency`, severity `low`):
  The approach should align with patterns used by existing Hermeto backends
  unless a deviation is justified.
- **Feasibility concerns** (`feasibility-concern`, severity `high`): Flag
  approaches that require unsupported tooling, introduce security risks,
  or cannot work within Hermeto's hermetic build model.
- **Missing hermetic build path** (`incomplete-analysis`, severity `critical`):
  The document must describe how builds work with pre-fetched dependencies
  and no network access. This is Hermeto's core value proposition.
