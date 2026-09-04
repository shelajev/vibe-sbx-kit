# Mistral Vibe Docker Sandboxes Kit

Docker Sandboxes kit that installs [Mistral Vibe](https://mistral.ai/products/vibe), Mistral's CLI coding agent, inside a sandbox. The host proxy injects your Mistral API key into outbound requests, so the real key never enters the sandbox.

Requires Docker Sandboxes 0.39.0 or newer. Kits are experimental and their schema may change.

## Quick start

1. **Get a Mistral API key** at <https://console.mistral.ai/>.

2. **Store it as a sandbox secret.** The key lands in your OS keychain; the real value never enters the sandbox.

   ```bash
   sbx secret set mistral
   # paste the key when prompted
   ```

3. **Allow this GitHub repository as a kit source.** The command preserves Docker Hub in the allowlist.

   ```bash
   sbx settings set kit.allowedSources '["docker.io/","github.com/shelajev/"]'
   ```

4. **Run a sandbox with the kit attached.** Replace `.` with the workspace path you want.

   ```bash
   sbx run vibe --kit git+https://github.com/shelajev/vibe-sbx-kit.git .
   ```

That's it. The sandbox boots into `vibe`'s interactive coding session, with full filesystem access to your mounted workspace and proxy-authenticated access to Mistral's API, account, and managed-config endpoints.

## Named sandbox

For a persistent sandbox you can re-attach to:

```bash
sbx create --name vibe-current \
  --kit git+https://github.com/shelajev/vibe-sbx-kit.git vibe .

sbx run --name vibe-current
```

The kit is applied when Docker Sandboxes creates the sandbox. Reattaching does not need the kit reference again.

## Non-interactive run

Pass vibe flags after `--`. In programmatic mode (`-p` / `--prompt`), vibe expects stdin to be closed — otherwise it sits waiting for input even though it has a prompt:

```bash
sbx exec vibe-current -- bash -c \
  'vibe -p "summarize the public API of this repo" --output text --max-turns 1 </dev/null'
```

## Smoke test

After creating the sandbox:

```bash
sbx exec vibe-current -- bash -c \
  'vibe -p "Reply with exactly: sbx-ok" --output text --max-turns 1 --max-price 0.05 </dev/null'
```

Expected output: `sbx-ok`.

## How it works

The kit declares a `mistral` service in `spec.yaml`. The Docker Sandboxes proxy reads your stored `mistral` secret on the host and substitutes `Authorization: Bearer <token>` into outbound requests to `api.mistral.ai`, `console.mistral.ai`, and `chat.mistral.ai`. Inside the sandbox, `MISTRAL_API_KEY` is set to a sentinel value (`proxy-managed`) so Vibe sees a non-empty env var without ever seeing the real key.

Install (runs once at sandbox creation, as the agent user):

- `curl -LsSf https://mistral.ai/vibe/install.sh | bash` — installs `uv` (Astral's Python package manager) then `uv tool install mistral-vibe`, placing `vibe` and `vibe-acp` in `~/.local/bin`

The kit prepends `/home/agent/.local/bin` to `PATH` so `vibe` resolves without manual sourcing.

## Network policy

The allowlist (verified by actually creating a sandbox and watching `sbx policy log`):

- `mistral.ai`, `*.mistral.ai` — install script, model API (`api.mistral.ai`), account lookup (`console.mistral.ai`), and managed config (`chat.mistral.ai`)
- `*.mistral.services` — Vibe's experiments / feature-flag service (`experiments.mistral.services`)
- `astral.sh`, `*.astral.sh` — `uv` installer download
- `pypi.org`, `*.pypi.org`, `files.pythonhosted.org` — Python package downloads for `mistral-vibe` and its deps (`files.pythonhosted.org` sees ~50 hits during install)
- `github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com` — uv's installer is served from `raw.githubusercontent.com`; some wheels resolve via `objects.githubusercontent.com`

If you want Vibe to reach additional services from inside the sandbox (for example, a private package index or third-party API), fork this kit and extend `permissions.network.allow` in `spec.yaml`. Use `sbx policy log <sandbox>` to discover what's being blocked.

## Local clone

If you clone this repo, `run.sh` creates and runs a named sandbox using the local kit path:

```bash
./run.sh vibe-current
```

Use any new sandbox name as the first argument; Vibe flags go after `--`. Reattach later with `sbx run --name <sandbox>`.

```bash
./run.sh my-sandbox -- --prompt "what tests are missing?"
```

## License

Apache 2.0. See [LICENSE](LICENSE).
