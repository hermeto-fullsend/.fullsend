# Cross-Repo References

This is a downstream fork of an upstream project. Never create backlink notifications in the upstream repository.

## Rule

Never use bare GitHub cross-repo issue references like `org/repo#123`. Always use markdown links with `redirect.github.com`:

```
[org/repo#123](https://redirect.github.com/org/repo/issues/123)
```

This applies to commit messages, PR descriptions, comments, and code.

## Why

Bare `org/repo#123` references create backlink mentions in the upstream repository's issue tracker. The redirect.github.com URL renders as a clickable link without triggering a notification.
