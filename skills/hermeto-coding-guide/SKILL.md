# Hermeto Coding Guide

Coding conventions for the Hermeto Python codebase. Apply these when writing
or reviewing Python code in the hermeto repository.

## Document decisions

- Comments explain **why**, not how. Never restate what the code does.
- Add doctests when they clarify intent.
- Link prior art: if code is based on external work, add a comment with a URL.
- Comment regular expressions: use inline comments (`re.VERBOSE`) or named
  groups.

## Write easy to follow code

- Keep lines under 120 characters. Avoid narrow 20+ line columns of arguments.
- Use meaningful variable names that reflect intent and type. Vowels are
  allowed — the vowel shortage is over.
- Keep names under ~30 characters. Single-letter names are fine in narrow
  scopes (short loops, list comprehensions).
- Use plural names for homogeneous containers: `names` for `list[Name]`.
- Respect naming continuity: if a parameter is `foo`, the caller's variable
  should also be `foo`.
- Split functions longer than ~30 lines or with deep nesting into helpers.
  A good function is a boring sequence of statements with little to no
  branching.
- Avoid multi-line list comprehensions. Fall back to a for loop or add
  intermediate abstractions.
- Use aliases and type aliases (`type RawBarJSON = dict[str, Any]`) to simplify
  signatures and serve as documentation.
- Strive for declarative code: express what, not how.
- Use stdlib before reinventing: check `collections`, `itertools`, `functools`.
- Implement dunder methods when practical.
- Prefer `@abc.abstractmethod` over raising `NotImplementedError` for base
  classes.

## Favor immutable styles

- Use `frozenset` for constant sets, tuples for static data.
- Return new objects rather than mutating arguments. Functions that return new
  values are easier to reason about than functions that modify arguments.
- Follow PEP 8 and PEP 20.

## Write clear tests

- Duplication in tests is acceptable. Avoid over-abstraction that hides what
  is being tested.
- Use long, descriptive test names:
  `test_foo_can_be_created_from_any_standard_source` not `test_foo`.
- Follow the Arrange-Act-Assert pattern.
- Keep assertions simple: do not embed constructors in assert statements.
  Use aliases.
- Add meaningful messages to assert statements.
- Add new test cases instead of extending existing ones. Copying an existing
  test, renaming, and modifying is encouraged.
- Adding new parameter groups to existing `@pytest.mark.parametrize` is
  encouraged if the test function stays unchanged.
- Add high-level comments to complex tests to explain the scenario.
