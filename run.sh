#!/usr/bin/env bash
set -euo pipefail

kit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sandbox="${1:-vibe-current}"

if [[ $# -gt 0 ]]; then
  shift
fi

exec sbx run vibe --name "$sandbox" --kit "$kit_dir" . "$@"
