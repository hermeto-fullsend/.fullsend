# Cross-Repo References

This is a downstream fork of an upstream project. Never create backlink notifications in the upstream repository.

## Rules

1. Never use bare cross-repo references like `org/repo#123`.
2. Never link to `https://github.com/org/repo/issues/N` directly.

Always use `redirect.github.com`:

```
[org/repo#123](https://redirect.github.com/org/repo/issues/123)
```

This applies to commit messages, PR descriptions, comments, and code.

## Why

Both bare `org/repo#123` references and direct `github.com` issue/PR URLs create backlink notifications in the upstream repository. The `redirect.github.com` domain renders an identical clickable link without triggering a notification.
