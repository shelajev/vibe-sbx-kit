# Mistral Vibe Docker Sandboxes Kit

Docker Sandboxes kit that installs [Mistral Vibe](https://mistral.ai/products/vibe) — Mistral's CLI coding agent — inside a sandbox and runs it with your Mistral API key injected via the host proxy. The real key never enters the sandbox.

## Quick start

1. **Get a Mistral API key** at <https://console.mistral.ai/>.

2. **Store it as a sandbox secret.** The key lands in your OS keychain; the real value never enters the sandbox.

   ```bash
   sbx secret set -g mistral
   # paste the key when prompted
   ```

3. **Run a sandbox with the kit attached.** Replace `.` with the workspace path you want.

   ```bash
   sbx run --kit git+https://github.com/shelajev/vibe-sbx-kit.git vibe .
   ```

That's it. The sandbox boots into `vibe`'s interactive coding session, with full filesystem access to your mounted workspace and authenticated access to `api.mistral.ai`.

## Named sandbox

For a persistent sandbox you can re-attach to:

```bash
sbx create --name vibe-current \
  --kit git+https://github.com/shelajev/vibe-sbx-kit.git vibe .

sbx run --kit git+https://github.com/shelajev/vibe-sbx-kit.git vibe-current
```

For custom agent kits, pass `--kit` again when re-running an existing sandbox. `sbx` records the custom agent name on the sandbox, but `sbx run <sandbox>` may not resolve a Git or local kit-defined agent unless the kit is supplied again.

## Non-interactive run

Pass vibe flags after `--`. In programmatic mode (`-p` / `--prompt`), vibe expects stdin to be closed — otherwise it sits waiting for input even though it has a prompt:

```bash
sbx exec vibe-test -- bash -c \
  'vibe -p "summarize the public API of this repo" --output text --max-turns 1 </dev/null'
```

## Smoke test

After creating the sandbox:

```bash
sbx exec vibe-test -- bash -c \
  'vibe -p "Reply with exactly: sbx-ok" --output text --max-turns 1 --max-price 0.05 </dev/null'
```

Expected output: `sbx-ok`.

## How it works

The kit declares a `mistral` service in `spec.yaml`. The Docker Sandboxes proxy reads your stored `mistral` secret on the host and substitutes `Authorization: Bearer <token>` into outbound requests to `api.mistral.ai`. Inside the sandbox, `MISTRAL_API_KEY` is set to a sentinel value (`proxy-managed`) so Vibe sees a non-empty env var without ever seeing the real key.

Install (runs once at sandbox creation, as the agent user):

- `curl -LsSf https://mistral.ai/vibe/install.sh | bash` — installs `uv` (Astral's Python package manager) then `uv tool install mistral-vibe`, placing `vibe` and `vibe-acp` in `~/.local/bin`

The kit prepends `/home/agent/.local/bin` to `PATH` so `vibe` resolves without manual sourcing.

## Network policy

The allowlist (verified by actually creating a sandbox and watching `sbx policy log`):

- `mistral.ai`, `*.mistral.ai` — install script + API (`api.mistral.ai`) + browser-auth (`console.mistral.ai`)
- `*.mistral.services` — Vibe's experiments / feature-flag service (`experiments.mistral.services`)
- `astral.sh`, `*.astral.sh` — `uv` installer download
- `pypi.org`, `*.pypi.org`, `files.pythonhosted.org` — Python package downloads for `mistral-vibe` and its deps (`files.pythonhosted.org` sees ~50 hits during install)
- `github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com` — uv's installer is served from `raw.githubusercontent.com`; some wheels resolve via `objects.githubusercontent.com`

If you want Vibe to reach additional services from inside the sandbox (e.g. a private package index, a third-party API), fork this kit and extend `network.allowedDomains` in `spec.yaml`. Use `sbx policy log <sandbox>` to discover what's being blocked.

## Local clone

If you clone this repo, `run.sh` runs a named sandbox using the local kit path:

```bash
./run.sh vibe-current
```

Use any sandbox name as the first argument; vibe flags go after `--`:

```bash
./run.sh my-sandbox -- --prompt "what tests are missing?"
```

## License

Apache 2.0. See [LICENSE](LICENSE).
