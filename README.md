# pk-ci-workflows

[![self-test](https://github.com/L1k4Root/pk-ci-workflows/actions/workflows/self-test.yml/badge.svg)](https://github.com/L1k4Root/pk-ci-workflows/actions/workflows/self-test.yml)

Reusable GitHub Actions workflows for polyglot services: **Node/TypeScript, Go, Rust, Python, C and Docker**.
One line in any repository gives it a complete, opinionated CI pipeline.

> **Resumen (ES):** Workflows reutilizables de GitHub Actions para proyectos en varios lenguajes.
> Cada repositorio los invoca con una línea (`uses: L1k4Root/pk-ci-workflows/...@v1`) y obtiene
> lint, tests, build y verificación de imágenes Docker mediante su `HEALTHCHECK`.
> Forma parte de [platform-kit](#part-of-platform-kit).

---

## Why

Copy-pasting CI YAML between repositories means ten slightly different pipelines that drift apart.
Reusable workflows (`on: workflow_call`) fix that: the pipeline is defined **once**, versioned with a tag,
and every repository consumes it like a dependency.

## Workflows

| Workflow | What it runs | Key inputs |
|---|---|---|
| [`node-ci.yml`](.github/workflows/node-ci.yml) | `pnpm install --frozen-lockfile` → `lint` → `typecheck` → `test` → `build` (each only if the script exists) | `node-version`, `working-directory` |
| [`go-ci.yml`](.github/workflows/go-ci.yml) | `gofmt` check → `go vet` → `go test -race -cover` | `working-directory`, `test-flags` |
| [`rust-ci.yml`](.github/workflows/rust-ci.yml) | `cargo fmt --check` → `clippy -D warnings` → `cargo test` | `toolchain`, `working-directory` |
| [`python-ci.yml`](.github/workflows/python-ci.yml) | `uv sync --locked` → `ruff check` → `ruff format --check` → `pytest` | `python-version`, `working-directory` |
| [`c-ci.yml`](.github/workflows/c-ci.yml) | `make all && make test`, twice: release flags **and** ASan + UBSan | `working-directory` |
| [`docker-ci.yml`](.github/workflows/docker-ci.yml) | build → run → **wait for `HEALTHCHECK` = healthy** → push to GHCR (optional) | `image-name`, `run-args`, `push` |

Plus one composite action:

| Action | What it does |
|---|---|
| [`actions/wait-healthy`](actions/wait-healthy/action.yml) | Polls `docker inspect` until a container is `healthy`; fails fast on `unhealthy`/exit and prints the container logs. |

## Usage

Create `.github/workflows/ci.yml` in your repository:

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    uses: L1k4Root/pk-ci-workflows/.github/workflows/node-ci.yml@v1
    with:
      node-version: "24"

  image:
    needs: test
    uses: L1k4Root/pk-ci-workflows/.github/workflows/docker-ci.yml@v1
    permissions:
      contents: read
      packages: write
    with:
      image-name: orders
      run-args: "-e DATABASE_URL=memory://"
      push: ${{ github.ref == 'refs/heads/main' }}
```

A polyglot repository simply calls several workflows with different `working-directory` values.

### Using `wait-healthy` on its own

```yaml
- run: docker compose up -d
- uses: L1k4Root/pk-ci-workflows/actions/wait-healthy@v1
  with:
    container: myproject-api-1
    timeout-seconds: 90
```

## Conventions the workflows expect

| Language | Contract |
|---|---|
| Node | `pnpm-lock.yaml` committed; `packageManager` field in `package.json`; optional `lint`, `typecheck`, `test`, `build` scripts. |
| Go | `go.mod` (the Go version is read from it); code is `gofmt`-formatted. |
| Rust | `Cargo.lock` committed for binaries; no clippy warnings. |
| Python | `uv.lock` committed; `ruff` and `pytest` in the dev dependency group. |
| C | `Makefile` with `all` and `test` targets that honour `EXTRA_CFLAGS` / `EXTRA_LDFLAGS`. |
| Docker | The image defines a `HEALTHCHECK`. Images without one fail the smoke test on purpose. |

## Design decisions

- **The health check is the release gate.** An image that builds but never becomes healthy is broken, so
  `docker-ci.yml` never pushes it. This is also why the workflow refuses images without a `HEALTHCHECK`.
- **Sanitizers are free insurance for C.** Running the test suite once more under AddressSanitizer and
  UndefinedBehaviorSanitizer catches out-of-bounds reads and signed overflows that would otherwise pass.
- **Least privilege.** Every workflow declares `permissions: contents: read`; only the Docker job asks for
  `packages: write`, and the caller must grant it explicitly.
- **Scripts are optional, not guessed.** `pnpm run --if-present` lets small libraries skip steps they don't
  need without separate workflow variants.

## Versioning

Consumers pin a major tag (`@v1`). Non-breaking changes move the `v1` tag forward; breaking changes
(renamed inputs, new required conventions) are released as `v2`.

```bash
git tag -a v1.2.0 -m "..." && git tag -f v1 && git push origin v1.2.0 && git push -f origin v1
```

## Testing this repository

[`self-test.yml`](.github/workflows/self-test.yml) lints every workflow with
[actionlint](https://github.com/rhysd/actionlint) and runs each reusable workflow against the matching
minimal project in [`examples/`](examples). Locally:

```bash
docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:1.7.12
docker build -t example-docker:ci examples/docker
docker run -d --name smoke example-docker:ci
CONTAINER=smoke ./actions/wait-healthy/wait-healthy.sh
```

## Part of platform-kit

This repository is one of ten building blocks combined in
**[pk-checkout-platform](https://github.com/L1k4Root/pk-checkout-platform)**, a polyglot checkout
system whose design came from what building these ten taught
([learnings](https://github.com/L1k4Root/pk-checkout-platform/blob/main/docs/LEARNINGS.md)):

| Repo | Topic |
|---|---|
| **pk-ci-workflows** | GitHub Actions |
| [pk-testing-kit](https://github.com/L1k4Root/pk-testing-kit) | Tests |
| [pk-healthcheck](https://github.com/L1k4Root/pk-healthcheck) | Docker healthchecks (C) |
| [pk-structured-logging](https://github.com/L1k4Root/pk-structured-logging) | Structured logging |
| [pk-correlation-id](https://github.com/L1k4Root/pk-correlation-id) | Correlation IDs |
| [pk-problem-details](https://github.com/L1k4Root/pk-problem-details) | Consistent error handling |
| [pk-otel](https://github.com/L1k4Root/pk-otel) | OpenTelemetry |
| [pk-idempotency](https://github.com/L1k4Root/pk-idempotency) | Idempotent payments (Go) |
| [pk-auth](https://github.com/L1k4Root/pk-auth) | Real authentication (Rust) |
| [pk-architecture](https://github.com/L1k4Root/pk-architecture) | Documented architecture |
| **[pk-checkout-platform](https://github.com/L1k4Root/pk-checkout-platform)** | **The integration project: all of the above, composed** |

## License

[MIT](LICENSE) © Andres (L1k4Root)
