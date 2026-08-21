#!/usr/bin/env bash
# Run a small, isolated ZenChain preview for users.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$(mktemp -d "${TMPDIR:-/tmp}/zenchain-demo.XXXXXX")"
trap 'rm -rf "$DEMO_DIR"' EXIT

git -C "$DEMO_DIR" init -q .

printf 'ZenChain terminal preview\n'
printf 'Demo repo: %s\n\n' "$DEMO_DIR"

printf '$ ./zen help\n'
"$ROOT/zen" help

printf '\n$ ./zen init --yes --vendor-skills %s\n' "$DEMO_DIR"
"$ROOT/zen" init --yes --vendor-skills "$DEMO_DIR"

printf '\n$ ./zen doctor %s\n' "$DEMO_DIR"
"$ROOT/zen" doctor "$DEMO_DIR"

printf '\n$ git -C %s status --short\n' "$DEMO_DIR"
git -C "$DEMO_DIR" status --short

printf '\nPreview complete. The temporary demo repo was removed.\n'
