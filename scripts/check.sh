#!/usr/bin/env bash
# The single gate: format, lint, generated config up to date, specs, the Rojo build, the Studio manifest. Run before
# every commit and judge it by its exit code or the last line, CHECK OK (CLAUDE.md, "Une porte se juge à son code de
# sortie").
cd "$(dirname "$0")/.." || exit 1

PY=py
command -v py >/dev/null 2>&1 || PY=python

step() {
	echo "== $1"
	shift
	if ! "$@"; then
		echo
		echo "CHECK FAILED at: $*"
		exit 1
	fi
}

step "stylua" stylua --check src tests tools/sim
step "selene" selene src tests tools/sim
step "config" "$PY" scripts/make_config.py --check
step "specs" lune run tests/run
mkdir -p build
step "rojo build" rojo build build.project.json -o build/BlindSpot.rbxl
step "manifest" "$PY" scripts/manifest.py

echo
echo "CHECK OK"
