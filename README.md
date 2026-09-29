# Mistral Vibe Docker Sandboxes Kit

A [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit (spec v3) that runs [Mistral Vibe](https://github.com/mistralai/mistral-vibe), Mistral's CLI coding agent, with your Mistral API key held by the host proxy. The real key never enters the sandbox.

## Quick start

1. Get a key at <https://console.mistral.ai/api-keys>.
2. Store it on the host under the `mistral` service:

   ```bash
   sbx secret set mistral        # paste the key when prompted
   ```

3. Run it on a workspace:

   ```bash
   sbx run docker.io/shelajev/sbx-kit-vibe:latest .
   # or straight from git (built on demand):
   sbx run git+https://github.com/shelajev/vibe-sbx-kit.git .
   ```

The sandbox boots into Vibe's interactive session in your workspace.

## Smoke test

```bash
sbx create --name vibe-test docker.io/shelajev/sbx-kit-vibe:latest .
sbx exec vibe-test -- bash -c \
  'vibe --trust -p "Reply with exactly: sbx-ok" --output text --max-turns 1 --max-price 0.05 </dev/null'
```

Expected output: `sbx-ok`. In `-p` mode Vibe waits on stdin, hence `</dev/null`. If you get a 401, check `sbx secret ls` for a `mistral` entry and look at `sbx policy log vibe-test` for the Mistral hosts.

## How it works

The kit is one OCI image. `vibe.yaml` is the descriptor and `vibe.dockerfile` is the content recipe: the `docker/sandbox-templates:shell-docker` base with `mistral-vibe` installed by `uv tool install` at a pinned release. It declares:

- **credential `mistral`**: `MISTRAL_API_KEY` inside the sandbox is a sentinel. The proxy substitutes `Authorization: Bearer <key>` on `api.mistral.ai` (inference), `chat.mistral.ai` (org-managed config) and `console.mistral.ai` (identity). Those are the three hosts Vibe sends the key to.
- **network policy**: the three hosts above, `*.mistral.ai`, and `experiments.mistral.services`. Inject domains are listed literally because v3 checks them against the allow list by exact match, and a wildcard doesn't count.
- **agent sessions**: `-p`, `--resume` and `--continue` for headless use.
- **agent context**: an `AGENTS.md` telling Vibe it is sandboxed.

Telemetry and self-update are off (`VIBE_ENABLE_TELEMETRY` / `VIBE_ENABLE_AUTO_UPDATE`). The Vibe version is whatever the image ships. The entrypoint is `vibe --trust`, since the workspace is your own mounted project.

Need more egress (a package index, GitHub)? Extend `network-policy@1` in `vibe.yaml`, or run `sbx policy allow network <host>` on the host.

## Local development

```bash
docker buildx build . -f vibe.yaml --output type=cacheonly   # validate + build
sbx run ./ .                                                 # run from this checkout
./run.sh my-sandbox                                          # same, named
```

## Publishing

- `.github/workflows/build.yml` builds for amd64 and arm64 and runs `kit-tck` on every push and PR. Nothing is pushed.
- `.github/workflows/publish.yml` pushes to Docker Hub when a `vX.Y.Z` tag is pushed. The tag is the mistral-vibe release to bake in:

  ```bash
  git tag v2.25.8 && git push origin v2.25.8
  ```

  It needs the repo secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Hub access token with Read & Write). You can also set the repo variable `DOCKERHUB_REPOSITORY`; it defaults to `<username>/sbx-kit-vibe`. It publishes `:X.Y.Z` and `:latest`.

## License

Apache 2.0. See [LICENSE](LICENSE).
