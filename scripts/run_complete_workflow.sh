#!/usr/bin/env bash
# scripts/run_complete_workflow.sh
# ─────────────────────────────────────────────────────────────────────────────
# Run the entire GROMACS protein–ligand MD protocol end-to-end.
#
# Usage:
#   bash scripts/run_complete_workflow.sh
#
# Prerequisites:
#   1. config/config.env exists and is configured
#   2. input/ directory contains protein PDB and CHARMM-GUI ligand files
#
# Log file: work/workflow.log
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${REPO_ROOT}/config/config.env"

if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] config/config.env not found."
    echo "        Copy config/config.env.example to config/config.env and edit it."
    exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

WORK_DIR="${REPO_ROOT}/${WORK_DIR:-work}"
mkdir -p "$WORK_DIR"
LOG="${WORK_DIR}/workflow.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

SCRIPTS="${REPO_ROOT}/scripts"

log "=== GROMACS MD Protocol — Full Workflow Start ==="
log "Log file: ${LOG}"

run_step() {
    local script="$1"
    local name="$2"
    log "--- ${name} ---"
    bash "${SCRIPTS}/${script}" 2>&1 | tee -a "$LOG"
    log "--- ${name} DONE ---"
}

run_step 00_system_check.sh       "00 System Check"
run_step 01_prepare_topology.sh   "01 Prepare Topology"
run_step 02_solvate_ions.sh       "02 Solvate + Ions"
run_step 03_em.sh                 "03 Energy Minimisation"
run_step 04_nvt.sh                "04 NVT Equilibration"
run_step 05_npt.sh                "05 NPT Equilibration"
run_step 06_md.sh                 "06 Production MD"
run_step 07_analysis.sh           "07 Analysis"

log "=== Full Workflow Complete ==="
log "Results: ${REPO_ROOT}/${RESULTS_DIR:-results}/"

