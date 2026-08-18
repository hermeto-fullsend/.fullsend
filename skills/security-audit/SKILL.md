# Security Audit

Supply chain attack patterns and security considerations specific to
Hermeto. Use this as a checklist when auditing the codebase.

## Hermeto architecture context

Hermeto fetches dependencies for multiple package managers (pip, npm, yarn,
pnpm, gomod, cargo, bundler, rpm, vcpkg) and produces SBOMs and build
configurations. It runs in build pipelines where it:

1. Reads user-provided manifest/lockfiles (untrusted input)
2. Resolves dependencies against package registries (network input)
3. Downloads artifacts and verifies integrity (network input)
4. Generates output files consumed by build systems (trusted output)

## Supply chain attack vectors to check

### Dependency confusion
- Does the resolver check private registries before public ones?
- Can a public package name shadow a private one?
- Are registry URLs validated and pinned?

### Lockfile injection
- Can crafted entries in lockfiles inject arbitrary URLs?
- Are package names sanitized before use in file paths or URLs?
- Are lockfile parsers resilient to malformed input?

### Path traversal
- Do archive extraction routines check for `../` in entry paths?
- Are symlinks followed during extraction?
- Are temp directories created securely (`mkdtemp`, not predictable names)?

### Checksum verification
- Are checksums compared using constant-time comparison?
- Can checksum verification be bypassed (missing hash = skip)?
- Are weak hash algorithms accepted (MD5, SHA1)?

### Command injection
- Are package names or versions interpolated into shell commands?
- Are subprocess calls using `shell=True` with untrusted input?
- Are environment variables from untrusted sources passed to subprocesses?

### Network security
- Is TLS certificate verification enforced for all registry connections?
- Are redirects followed safely (no redirect to file://, no infinite loops)?
- Are response sizes bounded to prevent resource exhaustion?

### TOCTOU (Time-of-check-time-of-use)
- Is there a gap between checksum verification and file use?
- Can a file be replaced between download and installation?

## Cross-backend consistency checks

Security measures should be consistent across all backends. Flag when:
- One backend validates checksums but another skips them
- One backend sanitizes package names but another uses them raw
- One backend pins TLS settings but another uses defaults
- Error handling reveals internal paths or credentials in one backend
  but not others
