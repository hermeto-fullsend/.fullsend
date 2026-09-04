# Issue Labels

Label taxonomy for the Hermeto project. Apply these labels when triaging
issues in the hermeto repository.

## Issue type

Apply exactly one:

- **bug** — Something isn't working. Confirmed broken behavior.
- **enhancement** — New feature or improvement to existing functionality.
- **question** — Further information is requested. The issue needs
  clarification before it can be triaged.
- **documentation** — Improvements or additions to documentation.
- **design document** — A new feature design (blueprint). The issue proposes
  a design rather than reporting a problem or requesting a feature.
- **refactor** — Marks features for tracking refactoring ideas. No
  user-visible behavior change.
- **tests** — Issue regarding a test suite problem.

## Package manager backend

Apply when the issue is specific to a backend. Apply multiple if the issue
spans backends:

- **pip** — Python pip backend
- **npm** — Node.js npm backend
- **yarn** — Yarn (Berry/v2+) backend
- **pnpm** — pnpm backend
- **gomod** — Go modules backend
- **cargo** — Rust Cargo backend
- **bundler** — Ruby Bundler backend
- **rpm** — RPM backend
- **vcpkg** — vcpkg (C/C++) backend

## Cross-cutting concerns

Apply when relevant, in addition to type and backend labels:

- **config** — Related to Hermeto's configuration system.
- **docker** — Container-related issues or changes.
- **sbom** — Software Bill of Materials related.
- **dependencies** — Related to project's own dependencies (not user
  dependencies that Hermeto processes).
- **website** — Related to the project website.

## Contributor experience

Apply when appropriate:

- **my first issue** — Good for newcomers. The issue is well-scoped, has
  clear acceptance criteria, and does not require deep project knowledge.
- **my-10th-issue** — NOT suitable for new contributors. Requires
  significant project context or touches complex subsystems.
- **nice to have** — A non-blocking improvement. Lower priority than bugs
  or core enhancements.

## Rules

1. Every issue must have exactly one type label.
2. Add backend labels only when the issue clearly relates to that backend.
   Do not guess — if the issue is about core infrastructure, skip backend
   labels.
3. Prefer specific labels over generic ones. An npm-specific bug gets both
   **bug** and **npm**.
4. Do not apply **my first issue** and **my-10th-issue** simultaneously.
5. When in doubt about contributor experience labels, omit them.
