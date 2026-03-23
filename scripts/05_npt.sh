#!/usr/bin/env bash
# scripts/05_npt.sh
# ─────────────────────────────────────────────────────────────────────────────
# NPT equilibration (100 ps, 300 K, 1 bar).
#
# Inputs:  work/04_nvt/nvt.gro | nvt.cpt  |  work/01_topology/topol.top
# Outputs: work/05_npt/npt.gro | npt.cpt
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
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/05_npt"
STEP04="${REPO_ROOT}/${WORK_DIR:-work}/04_nvt"
TOPOLOGY="${REPO_ROOT}/${WORK_DIR:-work}/01_topology/topol.top"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_NPT:-npt.mdp}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 05: NPT Equilibration ==="

for f in "${STEP04}/nvt.gro" "${STEP04}/nvt.cpt" "$TOPOLOGY" "$MDP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

# ── Pre-process ───────────────────────────────────────────────────────────────
log "Running grompp for NPT..."
"$GMX" grompp \
    -f "$MDP" \
    -c "${STEP04}/nvt.gro" \
    -r "${STEP04}/nvt.gro" \
    -t "${STEP04}/nvt.cpt" \
    -p "$TOPOLOGY" \
    -o npt.tpr \
    -maxwarn 2 \
    2>&1 | tee grompp_npt.log

# ── Run NPT ───────────────────────────────────────────────────────────────────
log "Running mdrun (NPT)..."
"$GMX" mdrun \
    -v \
    -deffnm npt \
    -gpu_id "${GPU_ID:-0}" \
    -ntmpi "${NTMPI:-1}" \
    -ntomp "${NTOMP:-4}" \
    -pin on \
    2>&1 | tee mdrun_npt.log

log "=== Step 05 complete. Outputs in: ${STEP_DIR} ==="
log "    npt.gro | npt.cpt | npt.edr | npt.log"
