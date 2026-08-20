# Product Security Skills

Security guidance for agents working on the hermeto codebase. Curated from
[prodsec-skills](https://redirect.github.com/RedHatProductSecurity/prodsec-skills)
(pinned to `b55c6b9c3392645f62da59a447c29473c413e371`).

Hermeto is a dependency management and fetching tool. Its code handles
untrusted network responses, user-supplied manifests and lockfiles, archive
extraction, subprocess invocation, and checksum verification. Apply the
guidance below when writing or reviewing code in these areas.

## Supply chain security

Hermeto fetches and resolves dependencies across multiple package managers.
Every fetcher, resolver, and parser is part of the supply chain attack
surface.

- **Dependency confusion.** Verify that resolution order prefers private
  registries over public ones. A public package with the same name as an
  internal one must never win resolution.
- **Integrity verification.** Every downloaded artifact must be verified
  against a known-good checksum before use. Use strong hash algorithms
  (SHA-256 or better). Compare checksums in constant time.
- **Lockfile trust boundary.** Lockfiles are untrusted input. Package
  names, version strings, and URLs in lockfiles can contain injection
  payloads. Validate and sanitize before use.
- **Registry URL handling.** Validate and canonicalize registry URLs.
  Prevent SSRF via crafted registry URLs that redirect to internal
  services. Reject non-HTTPS URLs unless explicitly configured.

## Input validation

All external input is untrusted: network responses, lockfiles, manifests,
environment variables, and configuration files.

- **Path traversal.** Canonicalize file paths and validate against allowed
  directories before any file operation. Reject paths containing `..`
  components or symlinks that escape the working directory.
- **Command injection.** Never pass unsanitized package names, versions,
  or URLs to shell commands. Use list-form subprocess invocation (not
  shell=True). Validate that arguments do not contain shell metacharacters.
- **Archive extraction.** Validate archive entries before extraction:
  reject entries with absolute paths, path traversal components, or
  symlinks pointing outside the extraction directory (zip slip).
- **Size limits.** Enforce size limits on downloaded artifacts and parsed
  files to prevent resource exhaustion.

## Secure defaults

- **TLS verification.** Never disable TLS certificate verification. If a
  test requires a self-signed certificate, configure it explicitly rather
  than disabling verification globally.
- **Fail closed.** Security checks (checksum verification, signature
  validation) must fail closed. A missing or invalid check is a hard
  error, not a warning.
- **No credential leakage.** Never log, print, or include credentials
  (tokens, passwords, API keys) in error messages, tracebacks, or debug
  output. Redact sensitive values before logging.

## File operations

- **Temporary files.** Use `tempfile` with restrictive permissions. Clean
  up temporary files in a finally block or context manager. Avoid
  predictable temporary file names.
- **Symlink handling.** When traversing directories or extracting archives,
  check for symlinks that could escape the intended directory. Use
  `os.path.realpath()` and validate the resolved path.
- **Permissions.** Set restrictive file permissions on created files and
  directories. Do not create world-writable files.

## Subprocess invocation

- **Argument lists.** Always use list-form arguments with `subprocess.run`
  or equivalent. Never construct command strings via concatenation or
  f-strings.
- **Environment isolation.** When invoking package manager CLIs, pass an
  explicit environment dict rather than inheriting the full process
  environment. This prevents environment variable injection.
- **Timeout enforcement.** Set timeouts on subprocess calls to prevent
  hangs from blocking the pipeline.

## Further reading

The full prodsec-skills collection is at
`https://redirect.github.com/RedHatProductSecurity/prodsec-skills`.
Key skills for hermeto's domain:

| Skill | When to use |
|-------|-------------|
| `supply-chain-risk-auditor` | Auditing dependency health and takeover risk |
| `differential-review` | Security-focused review of code changes |
| `insecure-defaults` | Detecting fail-open defaults and weak auth |
| `sharp-edges` | Finding error-prone APIs and footgun designs |
| `file-handling-uploads` | Reviewing code that processes user-supplied files |
| `defense-in-depth` | Evaluating layered security controls |
| `vulnerability-management` | Planning vulnerability response processes |
| `semgrep` | Running static analysis scans |
