# Backend Scaffolding

How to add a new package manager backend to Hermeto. Follow this structure
when implementing a new backend or reviewing one for completeness.

## Source layout

Create the backend under `hermeto/core/package_managers/<backend>/`:

```
hermeto/core/package_managers/<backend>/
    __init__.py          # re-export fetch_<backend>_source
    main.py              # entry point: fetch_<backend>_source(request) -> RequestOutput
```

Add modules as needed (`models.py`, `parser.py`, `utils.py`). If the
ecosystem has multiple tools (e.g., JavaScript has npm/yarn/pnpm), group
them under an ecosystem directory with shared modules at the top level.

### `__init__.py` pattern

```python
# SPDX-License-Identifier: GPL-3.0-only
from hermeto.core.package_managers.<backend>.main import fetch_<backend>_source

__all__ = ["fetch_<backend>_source"]
```

### `main.py` entry point pattern

The fetch function must:
1. Iterate over `request.<backend>_packages`
2. Resolve dependencies and download content
3. Generate SBOM `Component` objects (using PURL format)
4. Call `create_backend_annotation(components, "<backend>")`
5. Return `RequestOutput.from_obj_list(components=..., environment_variables=..., project_files=..., annotations=...)`

Use shared HTTP utilities from `hermeto.core.package_managers.general`
for downloads and retry logic.

## Registration

Two files must be updated to register the backend:

### 1. `hermeto/core/models/input.py`

- Add the type string to the `PackageManagerType` literal union.
  Experimental backends use the `x-` prefix (e.g., `"x-maven"`).
- Create a `<Backend>PackageInput` class extending `_PackageInputBase`
  with `type: Literal["<backend>"]` and any backend-specific fields.
- Add the new input class to the `PackageInput` discriminated union.
- Add a `<backend>_packages` property to the `Request` class.

### 2. `hermeto/core/resolver.py`

- Import the backend's fetch function.
- Add an entry to the `_package_managers` dict mapping the type string
  to `fetch_<backend>_source`.

**Note:** There is no metaclass, decorator, or entry-point system.
Registration is purely via explicit imports and dict entries in the two
files above.

## Unit tests

Mirror the source layout under `tests/unit/package_managers/<backend>/`:

```
tests/unit/package_managers/<backend>/
    __init__.py
    test_main.py
    test_<module>.py     # one per additional source module
```

## Integration tests

Create scenario-based tests under `tests/integration/<backend>/`:

```
tests/integration/<backend>/
    __init__.py
    test_<backend>.py
    scenarios/
        <scenario_name>/
            in/          # input: lockfile, manifest, Containerfile, README.md
            out/         # expected: bom.json, .build-config.yaml
```

### Test file pattern

- Define `SCENARIOS_DIR = Path(__file__).parent / "scenarios"`
- Parametrize with `utils.TestParameters(packages=(...,))`
- Use test IDs matching scenario directory names
- Two test types: smoketests (`utils.fetch_deps_and_check_output()`)
  and e2e tests (`utils.build_image_and_check_cmd()`)

### Scenario `in/` directory

Include at minimum:
- The lockfile (e.g., `package-lock.json`, `Cargo.lock`)
- The manifest (e.g., `package.json`, `Cargo.toml`)
- A `README.md` explaining the scenario
- A `Containerfile` for e2e tests

### Scenario `out/` directory

- `bom.json` — expected SBOM output
- `.build-config.yaml` — expected build configuration

## Documentation

- Create `docs/<backend>.md` with user-facing documentation
- Create `docs/design/<backend>.md` following the design template at
  `docs/design/package-manager-template.md`
- Update `docs/index.md` to list the new backend

## Conventions

- License header: `# SPDX-License-Identifier: GPL-3.0-only`
- All code uses type annotations (enforced by mypy)
- Formatting: ruff
- Tests: nox
- Dependencies in `pyproject.toml`, pinned via `pip-compile`
