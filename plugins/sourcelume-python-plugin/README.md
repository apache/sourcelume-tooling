# Apache Sourcelume Python Plugin (`sourcelume-python-plugin`)

The `sourcelume-python-plugin` extracts metadata directly from a Python project's `pyproject.toml` (coordinates, organization, developers, license), generates canonical [Sourcelume 0.0.1 Provenance Records](https://sourcelume.apache.org/schema/0.0.1/sourcelume.schema.json), validates them against the registry schema, and publishes them to the registry.

## Goals

| Goal | Description |
|---|---|
| `sourcelume generate` | Generates a `provenance-record.json` spec file from project metadata. |
| `sourcelume validate` | Validates the spec against the registry's `/records/validate` endpoint. |
| `sourcelume publish` | Submits the generated spec to the registry (`POST /records`). |

---

## Quickstart & Usage

### 1. Installation

Install the plugin locally using `uv`:

```bash
cd plugins/sourcelume-python-plugin
uv sync
```

### 2. Command-Line Execution

Run commands using `uv run` to ensure they are executed within the managed virtual environment:

```bash
# Generate the record
uv run sourcelume generate .

# Validate the record
uv run sourcelume validate . --registry-url http://localhost:8082

# Publish the record
uv run sourcelume publish . --registry-url http://localhost:8082 --token "$REGISTRY_TOKEN"
```

---

## Configuration

The following configuration options are supported via CLI flags:

| Parameter | CLI Flag | Description |
|---|---|---|
| `registry_url` | `--registry-url` | URL of the Sourcelume Registry. Default: `http://localhost:8082`. |
| `token` | `--token` | Bearer token for authentication. |
| `username` | `--username` | Registry username for HTTP Basic Auth. |
| `password` | `--password` | Registry password for HTTP Basic Auth. |
| `allow_conflict`| `--allow-conflict`| If true, treats HTTP 409 (Conflict) as success. |

---

## Building and Testing

### Development

```bash
cd plugins/sourcelume-python-plugin

# Run tests
uv run pytest
```

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
