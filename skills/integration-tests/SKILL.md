# Integration Test Validation

Rules for reviewing integration tests in the hermeto repository. Apply these
when reviewing PRs that add or modify files under `tests/integration/`.

## Scenario directory structure

Every integration test scenario lives under
`tests/integration/<pkg_manager>/scenarios/<scenario_name>/`. Each scenario
must have:

```
<scenario_name>/
  in/                     # Required: input files (manifests, lockfiles)
    <package files>       # e.g. requirements.txt, package.json, Gemfile.lock
    Containerfile         # Required for e2e scenarios
    README.md             # Optional: describes what the scenario tests
  out/                    # Required when check_output=True
    .build-config.yaml    # Expected build configuration
    bom.json              # Expected SBOM
```

## Naming conventions

- Scenario directories: `<pkg_manager>_<description>` (e.g. `pip_e2e`,
  `npm_smoketest_lockfile3`, `bundler_checksum_mismatch`).
- E2e scenarios include `_e2e` in the name.
- Error/edge case scenarios describe the condition (e.g. `_missing_lockfile`,
  `_invalid_checksum`).
- Test functions: `test_<pkg>_packages` for fetch-only tests,
  `test_e2e_<pkg>` for end-to-end tests.

## Parameterization

Tests use `@pytest.mark.parametrize` with `pytest.param(..., id="<scenario>")`.
The `id` must match the scenario directory name exactly. Parameters use the
`TestParameters` dataclass from `tests/integration/utils.py`.

Key `TestParameters` fields to verify in review:
- `packages`: tuple of dicts with `path` and `type` (must match the package
  manager being tested).
- `check_output`: if `True`, the scenario must have `out/` with expected
  files.
- `expected_error`: defaults to `ERR_OK`. Set explicitly for negative test
  cases.
- `expected_output`: string to assert in command output (for error message
  verification).

## Preferred pattern

Self-contained scenarios (input files committed in `in/`) are the preferred
pattern. The older branch-based pattern (referencing external repos via
`branch` parameter) is legacy — new scenarios must use self-contained inputs.

## Review checklist

When reviewing integration test changes, verify:

1. **Structure**: scenario has `in/` directory. E2e scenarios have a
   `Containerfile` in `in/`. If `check_output=True`, `out/` has both
   `.build-config.yaml` and `bom.json`.
2. **Naming**: scenario directory and `pytest.param` id follow the naming
   conventions above.
3. **Determinism**: `create_synthetic_repo()` produces reproducible commits.
   Do not add non-deterministic data to `in/` files.
4. **Expected output**: when `check_output=True`, expected output should be
   generated via `HERMETO_TEST_GENERATE_DATA=1` or `nox -s generate-test-data`,
   not hand-written.
5. **New vs extended**: prefer adding a new scenario over modifying an
   existing one. Existing scenario changes risk breaking unrelated tests.
6. **No branch-based tests**: new tests must not use the `branch` parameter.
   Use self-contained `in/` directories instead.
7. **Markers**: tests requiring a local Nexus proxy must use the appropriate
   skip marker or `@pytest.mark.no_proxy_mode`.
