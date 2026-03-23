#!/usr/bin/env bash
# scripts/04_nvt.sh
# ─────────────────────────────────────────────────────────────────────────────
# NVT equilibration (100 ps, 300 K, constant volume).
#
# Inputs:  work/03_em/em.gro  |  work/01_topology/topol.top
# Outputs: work/04_nvt/nvt.gro | nvt.cpt
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
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/04_nvt"
STEP03="${REPO_ROOT}/${WORK_DIR:-work}/03_em"
TOPOLOGY="${REPO_ROOT}/${WORK_DIR:-work}/01_topology/topol.top"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_NVT:-nvt.mdp}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 04: NVT Equilibration ==="

for f in "${STEP03}/em.gro" "$TOPOLOGY" "$MDP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

# Patch the gen_seed in the MDP if GEN_SEED is set in config
MDP_RUNTIME="${STEP_DIR}/nvt_runtime.mdp"
if [ "${GEN_SEED:-(-1)}" != "-1" ]; then
    sed "s/^gen_seed.*=.*/gen_seed                 = ${GEN_SEED}/" "$MDP" > "$MDP_RUNTIME"
    log "Using fixed gen_seed = ${GEN_SEED} for reproducibility."
else
    cp "$MDP" "$MDP_RUNTIME"
fi

# ── Pre-process ───────────────────────────────────────────────────────────────
log "Running grompp for NVT..."
"$GMX" grompp \
    -f "$MDP_RUNTIME" \
    -c "${STEP03}/em.gro" \
    -r "${STEP03}/em.gro" \
    -p "$TOPOLOGY" \
    -o nvt.tpr \
    -maxwarn 2 \
    2>&1 | tee grompp_nvt.log

# ── Run NVT ───────────────────────────────────────────────────────────────────
log "Running mdrun (NVT)..."
"$GMX" mdrun \
    -v \
    -deffnm nvt \
    -gpu_id "${GPU_ID:-0}" \
    -ntmpi "${NTMPI:-1}" \
    -ntomp "${NTOMP:-4}" \
    -pin on \
    2>&1 | tee mdrun_nvt.log

log "=== Step 04 complete. Outputs in: ${STEP_DIR} ==="
log "    nvt.gro | nvt.cpt | nvt.edr | nvt.log"
