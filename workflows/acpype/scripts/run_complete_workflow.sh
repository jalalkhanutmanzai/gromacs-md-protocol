#!/bin/bash
# ============================================================
# run_complete_workflow.sh — Master Workflow Script
# ============================================================
# Runs the complete GROMACS protein-ligand MD simulation
# workflow from start to finish, pausing for confirmation
# at each major step.
#
# Steps:
#   00 — System check
#   01 — Prepare protein
#   02 — Prepare ligand topology
#   03 — Build system topology
#   04 — Solvation and ions
#   05 — Energy minimization
#   06 — NVT equilibration
#   07 — NPT equilibration
#   08 — Production MD (100 ns)
#   09 — Analysis
#
# Usage:
#   bash scripts/run_complete_workflow.sh
#
# To skip the confirmation prompts:
#   SKIP_CONFIRM=yes bash scripts/run_complete_workflow.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_CONFIRM="${SKIP_CONFIRM:-no}"

# ============================================================
# CONFIGURATION — Edit these for your system
# ============================================================
export PDB_ID="1IEP"
export LIGAND_ID="STI"
export LIGAND_CHARGE="0"
export LIGAND_NAME="LIG"
export FORCE_FIELD="charmm36-jul2022"
export WATER_MODEL="tip3p"
export USE_GPU="yes"
export GPU_ID="0"
# ============================================================

STEPS=(
    "00:System check:00_system_check.sh"
    "01:Prepare protein:01_prepare_protein.sh"
    "02:Prepare ligand:02_prepare_ligand.sh"
    "03:Build topology:03_build_topology.sh"
    "04:Solvation and ions:04_solvation_ions.sh"
    "05:Energy minimization:05_energy_minimization.sh"
    "06:NVT equilibration:06_nvt_equilibration.sh"
    "07:NPT equilibration:07_npt_equilibration.sh"
    "08:Production MD (100 ns):08_production_md.sh"
    "09:Analysis:09_analysis.sh"
)

confirm() {
    local step_name="$1"
    if [ "$SKIP_CONFIRM" = "yes" ]; then
        return 0
    fi
    echo ""
    echo "─────────────────────────────────────────"
    read -r -p "  Proceed with: $step_name? [Y/n] " answer
    case "$answer" in
        [nN]|[nN][oO])
            echo "  Skipping $step_name."
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

echo "============================================================"
echo " GROMACS MD Protocol — Complete Workflow"
echo "============================================================"
echo ""
echo " Configuration:"
echo "   PDB ID:       $PDB_ID"
echo "   Ligand:       $LIGAND_ID (charge $LIGAND_CHARGE)"
echo "   Force field:  $FORCE_FIELD"
echo "   Water model:  $WATER_MODEL"
echo "   GPU:          $USE_GPU (ID: $GPU_ID)"
echo ""
echo " This script will run all 10 steps and pause for"
echo " confirmation before each one."
echo ""
echo " To run without confirmation:"
echo "   SKIP_CONFIRM=yes bash scripts/run_complete_workflow.sh"
echo ""
echo "─────────────────────────────────────────"
echo ""

START_TIME=$(date +%s)

for step in "${STEPS[@]}"; do
    IFS=':' read -r step_num step_name step_script <<< "$step"

    if confirm "Step $step_num: $step_name"; then
        echo ""
        echo "============================================================"
        echo " Running Step $step_num: $step_name"
        echo "============================================================"
        step_start=$(date +%s)

        bash "$SCRIPT_DIR/$step_script"

        step_end=$(date +%s)
        elapsed=$((step_end - step_start))
        hours=$((elapsed / 3600))
        minutes=$(( (elapsed % 3600) / 60 ))
        seconds=$((elapsed % 60))
        echo ""
        echo "  ✓ Step $step_num complete in $(printf '%02d:%02d:%02d' "$hours" "$minutes" "$seconds")"
    fi
done

END_TIME=$(date +%s)
TOTAL=$((END_TIME - START_TIME))
total_h=$((TOTAL / 3600))
total_m=$(( (TOTAL % 3600) / 60 ))
total_s=$((TOTAL % 60))

echo ""
echo "============================================================"
echo " ALL STEPS COMPLETE!"
echo " Total runtime: $(printf '%02d:%02d:%02d' "$total_h" "$total_m" "$total_s")"
echo "============================================================"
echo ""
echo " Your results are in: simulation/analysis/"
echo " See docs/09_analysis.md for interpretation guidance."
