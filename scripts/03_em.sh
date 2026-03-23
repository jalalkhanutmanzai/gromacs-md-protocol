#!/usr/bin/env bash
# scripts/03_em.sh
# ─────────────────────────────────────────────────────────────────────────────
# Energy minimisation.
#
# Inputs:  work/02_solvate/ions.gro  |  work/01_topology/topol.top
# Outputs: work/03_em/em.gro (minimised coordinates)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${REPO_ROOT}/config/config.env"

if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] config/config.env not found."
    exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

GMX="${GMX_BIN:-gmx}"
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/03_em"
STEP02="${REPO_ROOT}/${WORK_DIR:-work}/02_solvate"
TOPOLOGY="${REPO_ROOT}/${WORK_DIR:-work}/01_topology/topol.top"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_EM:-em.mdp}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 03: Energy Minimisation ==="

for f in "${STEP02}/ions.gro" "$TOPOLOGY" "$MDP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

# ── Pre-process ───────────────────────────────────────────────────────────────
log "Running grompp for energy minimisation..."
"$GMX" grompp \
    -f "$MDP" \
    -c "${STEP02}/ions.gro" \
    -p "$TOPOLOGY" \
    -o em.tpr \
    -maxwarn 2 \
    2>&1 | tee grompp_em.log

# ── Run EM ────────────────────────────────────────────────────────────────────
log "Running mdrun (energy minimisation)..."
"$GMX" mdrun \
    -v \
    -deffnm em \
    -gpu_id "${GPU_ID:-0}" \
    -ntmpi "${NTMPI:-1}" \
    -ntomp "${NTOMP:-4}" \
    2>&1 | tee mdrun_em.log

# ── Check convergence ─────────────────────────────────────────────────────────
if grep -q "Potential Energy" mdrun_em.log 2>/dev/null || grep -q "Maximum force" em.log 2>/dev/null; then
    log "EM log output (last 5 lines):"
    tail -5 em.log 2>/dev/null || true
fi

log "=== Step 03 complete. Outputs in: ${STEP_DIR} ==="
log "    em.gro | em.edr | em.log"
