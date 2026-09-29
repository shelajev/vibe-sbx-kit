#!/usr/bin/env bash
# Run a named sandbox from this local checkout of the kit. sbx builds the
# source-form v3 kit on demand, so no registry push is needed.
#   ./run.sh [sandbox-name] [workspace] [-- vibe args...]
set -euo pipefail

kit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sandbox="${1:-vibe-current}"
[[ $# -gt 0 ]] && shift

exec sbx run "$kit_dir" --name "$sandbox" "$@"
