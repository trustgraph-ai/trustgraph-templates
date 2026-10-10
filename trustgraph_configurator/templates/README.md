# Template metadata

This directory contains metadata files used by the config service API.

## index.json

Defines available templates, platforms, and statuses.

### templates

Each entry in the `templates` array describes a template line:

| Field          | Type   | Required | Description                                      |
|----------------|--------|----------|--------------------------------------------------|
| `name`         | string | yes      | Template line identifier, e.g. `"2.9"`           |
| `description`  | string | yes      | Short description of this template line           |
| `version`      | string | yes      | Current version, e.g. `"2.9.11"`                 |
| `status`       | string | yes      | One of the status names defined below             |
| `announcement` | string | no       | URL to the release announcement page              |

### platforms

Each entry in the `platforms` array describes a deployment target:

| Field         | Type   | Required | Description                          |
|---------------|--------|----------|--------------------------------------|
| `name`        | string | yes      | Platform identifier, e.g. `"docker-compose"` |
| `description` | string | yes      | Human-readable description           |

### statuses

Each entry in the `statuses` array defines a lifecycle stage:

| Field         | Type   | Required | Description                          |
|---------------|--------|----------|--------------------------------------|
| `name`        | string | yes      | Status identifier, e.g. `"stable"`   |
| `description` | string | yes      | Human-readable label                 |

## advisories.json

Security and bug advisories that the config service uses to warn users
running affected versions.

### Top-level structure

```json
{
    "advisories": [ ... ]
}
```

### Advisory fields

Each entry in the `advisories` array:

| Field         | Type   | Required | Description                                    |
|---------------|--------|----------|-------------------------------------------------|
| `id`          | string | yes      | Unique advisory identifier, e.g. `"TG-2026-001"` |
| `severity`    | string | yes      | One of `critical`, `high`, `medium`, `low`      |
| `summary`     | string | yes      | One-line summary                                |
| `description` | string | yes      | Longer description of the issue                 |
| `url`         | string | yes      | Link to the full advisory page                  |
| `affects`     | array  | yes      | List of affected version ranges (see below)     |

### Affected-range fields

Each entry in the `affects` array identifies a template line and the
versions within it that are affected:

| Field      | Type   | Required | Description                                         |
|------------|--------|----------|-----------------------------------------------------|
| `template` | string | yes      | Template line, e.g. `"2.8"`                         |
| `versions` | string | yes      | Version comparator, e.g. `"<2.8.15"` or `">=2.7.0"` |
| `fixed_in` | string | no       | Version that fixes the issue. Omit if no fix exists. |

Supported comparators for `versions`: `<`, `<=`, `>`, `>=`.

An advisory can list multiple `affects` entries when an issue spans
several template lines, each with its own fix version (or no fix).
