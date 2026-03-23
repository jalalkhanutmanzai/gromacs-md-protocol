#!/usr/bin/env bash
# scripts/02_solvate_ions.sh
# ─────────────────────────────────────────────────────────────────────────────
# Define simulation box, solvate with water, add counter-ions.
#
# Inputs  (from step 01):
#   work/01_topology/complex.gro
#   work/01_topology/topol.top
#
# Outputs (work/02_solvate/):
#   newbox.gro    — complex in simulation box
#   solvated.gro  — solvated system
#   ions.gro      — final system with ions (input for EM)
#   (topol.top updated in-place)
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
STEP01="${REPO_ROOT}/${WORK_DIR:-work}/01_topology"
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/02_solvate"
MDP="${REPO_ROOT}/${MDP_DIR:-mdp}/${MDP_EM:-em.mdp}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 02: Solvate and add ions ==="

# ── Validate inputs ───────────────────────────────────────────────────────────
for f in "${STEP01}/complex.gro" "${STEP01}/topol.top" "$MDP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        echo "        Run scripts/01_prepare_topology.sh first."
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

TOPOLOGY="${STEP01}/topol.top"

# ── 1. Define simulation box ─────────────────────────────────────────────────
log "Defining simulation box (${BOX_TYPE:-dodecahedron}, d=${BOX_DISTANCE:-1.0} nm)..."
"$GMX" editconf \
    -f "${STEP01}/complex.gro" \
    -o newbox.gro \
    -c \
    -d "${BOX_DISTANCE:-1.0}" \
    -bt "${BOX_TYPE:-dodecahedron}" \
    2>&1 | tee editconf.log

# ── 2. Solvate ────────────────────────────────────────────────────────────────
log "Solvating with TIP3P water..."
"$GMX" solvate \
    -cp newbox.gro \
    -cs spc216.gro \
    -o solvated.gro \
    -p "$TOPOLOGY" \
    2>&1 | tee solvate.log

# ── 3. Pre-process for genion ─────────────────────────────────────────────────
log "Pre-processing for ion addition..."
"$GMX" grompp \
    -f "$MDP" \
    -c solvated.gro \
    -p "$TOPOLOGY" \
    -o ions.tpr \
    -maxwarn 2 \
    2>&1 | tee grompp_ions.log

# ── 4. Add ions ───────────────────────────────────────────────────────────────
log "Adding ions (${ION_POS:-NA}/${ION_NEG:-CL}, ${SALT_CONC:-0.15} M, neutral)..."
printf "SOL\n" | "$GMX" genion \
    -s ions.tpr \
    -o ions.gro \
    -p "$TOPOLOGY" \
    -pname "${ION_POS:-NA}" \
    -nname "${ION_NEG:-CL}" \
    -neutral \
    -conc "${SALT_CONC:-0.15}" \
    2>&1 | tee genion.log

log "=== Step 02 complete. Outputs in: ${STEP_DIR} ==="
log "    ions.gro (final solvated+neutralised system ready for EM)"
