#!/usr/bin/env bash
# scripts/00_system_check.sh
# ─────────────────────────────────────────────────────────────────────────────
# Verify that GROMACS and GPU are available and that the config file exists.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${REPO_ROOT}/config/config.env"

echo "=== GROMACS MD Protocol — System Check ==="
echo

# ── 1. Config file ──────────────────────────────────────────────────────────
if [ -f "$CONFIG" ]; then
    echo "[OK] config/config.env found"
    # shellcheck source=/dev/null
    source "$CONFIG"
else
    echo "[WARN] config/config.env not found."
    echo "       Copy config/config.env.example → config/config.env and edit it."
    GMX_BIN="${GMX_BIN:-gmx}"
fi

# ── 2. GROMACS ──────────────────────────────────────────────────────────────
if command -v "${GMX_BIN:-gmx}" &>/dev/null; then
    echo "[OK] GROMACS binary: $(command -v "${GMX_BIN:-gmx}")"
    "${GMX_BIN:-gmx}" --version 2>&1 | grep -E "^(GROMACS version|CUDA support|Hardware)"
else
    echo "[FAIL] GROMACS not found. Install it or update GMX_BIN in config/config.env."
    exit 1
fi

echo

# ── 3. GPU ───────────────────────────────────────────────────────────────────
if command -v nvidia-smi &>/dev/null; then
    echo "[OK] nvidia-smi found. GPU(s):"
    nvidia-smi --query-gpu=name,driver_version,memory.total \
               --format=csv,noheader | sed 's/^/       /'
else
    echo "[WARN] nvidia-smi not found. GPU acceleration may not be available."
fi

echo

# ── 4. Required input directories ────────────────────────────────────────────
INPUT_DIR="${INPUT_DIR:-input}"
WORK_DIR="${WORK_DIR:-work}"
RESULTS_DIR="${RESULTS_DIR:-results}"

for d in "$INPUT_DIR" "$WORK_DIR" "$RESULTS_DIR"; do
    if [ -d "${REPO_ROOT}/$d" ]; then
        echo "[OK] Directory exists: $d/"
    else
        echo "[INFO] Directory missing (will be created at runtime): $d/"
    fi
done

echo
echo "=== System check complete ==="

