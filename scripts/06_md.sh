#!/usr/bin/env bash
# scripts/06_md.sh
# ─────────────────────────────────────────────────────────────────────────────
# Production MD run (100 ns NPT).
#
# Inputs:  work/05_npt/npt.gro | npt.cpt  |  work/01_topology/topol.top
# Outputs: work/06_md/md.xtc | md.edr | md.cpt | md.log
#
# To restart a crashed run, re-run this script — it detects an existing
# checkpoint (md.cpt) and continues automatically.
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
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/06_md"
STEP05="${REPO_ROOT}/${WORK_DIR:-work}/05_npt"
TOPOLOGY="${REPO_ROOT}/${WORK_DIR:-work}/01_topology/topol.top"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_MD:-md_100ns.mdp}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 06: Production MD ==="

for f in "${STEP05}/npt.gro" "${STEP05}/npt.cpt" "$TOPOLOGY" "$MDP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

# ── Pre-process (only if TPR does not already exist) ─────────────────────────
if [ ! -f md.tpr ]; then
    log "Running grompp for production MD..."
    "$GMX" grompp \
        -f "$MDP" \
        -c "${STEP05}/npt.gro" \
        -t "${STEP05}/npt.cpt" \
        -p "$TOPOLOGY" \
        -o md.tpr \
        -maxwarn 2 \
        2>&1 | tee grompp_md.log
else
    log "md.tpr already exists — skipping grompp (using existing TPR)."
fi

# ── Run or restart production MD ─────────────────────────────────────────────
RESTART_FLAG=""
if [ -f md.cpt ]; then
    log "Checkpoint found (md.cpt) — restarting from checkpoint."
    RESTART_FLAG="-cpi md.cpt"
else
    log "No checkpoint found — starting fresh production run."
fi

log "Running mdrun (100 ns production MD)..."
# shellcheck disable=SC2086
"$GMX" mdrun \
    -v \
    -deffnm md \
    ${RESTART_FLAG} \
    -gpu_id "${GPU_ID:-0}" \
    -ntmpi "${NTMPI:-1}" \
    -ntomp "${NTOMP:-4}" \
    -pin on \
    2>&1 | tee mdrun_md.log

log "=== Step 06 complete. Outputs in: ${STEP_DIR} ==="
log "    md.xtc | md.edr | md.cpt | md.log"
log "    (All gitignored — do not commit these files)"
