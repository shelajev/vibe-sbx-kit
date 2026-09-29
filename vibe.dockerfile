# Content recipe for the vibe kit (companion to vibe.yaml, found by stem).
#
# v1 installed Vibe at sandbox create with `curl mistral.ai/vibe/install.sh |
# bash`. In v3 a workload carries its own root filesystem, so the install moves
# here: no per-create latency, content that is scannable and digest-pinned, a
# broken install fails at publish instead of in someone's sandbox, and the
# install-phase egress (astral.sh, PyPI, GitHub) disappears from the kit.
FROM docker/sandbox-templates:shell-docker

# PyPI release of mistral-vibe. Supplied by the kit's `version` arg
# (buildArg VIBE_VERSION), which also stamps the published `provides`.
ARG VIBE_VERSION

# As agent, not root: `uv tool install` puts the executables in
# ~/.local/bin, owned by the user who runs Vibe. uv ships with the template.
USER agent
RUN set -eux; \
    uv tool install "mistral-vibe==${VIBE_VERSION}"; \
    uv cache clean; \
    # The provide is a claim about content: judge it the way the entrypoint
    # will, through PATH, and fail the build on a mismatch.
    test "$(command -v vibe)" = /home/agent/.local/bin/vibe; \
    vibe --version | grep -q "${VIBE_VERSION}"

ENV PATH=/home/agent/.local/bin:${PATH} \
    # Vibe maps VIBE_<FIELD> onto ~/.vibe/config.toml. No telemetry, and no
    # silent self-update: the version is whatever this image ships.
    VIBE_ENABLE_TELEMETRY=false \
    VIBE_ENABLE_AUTO_UPDATE=false \
    # Never block on a git credential prompt in a non-interactive session.
    GIT_TERMINAL_PROMPT=0

WORKDIR /home/agent/workspace

# --trust: the workspace is the user's own project, mounted by sbx. Without it
# Vibe stops on its workspace-trust prompt, which a headless run (`sbx exec`,
# agent-sessions prompt) has no TTY to answer.
ENTRYPOINT ["vibe", "--trust"]
