#!/bin/bash
# ============================================================
# 05_energy_minimization.sh — Energy Minimization
# ============================================================
# Remove steric clashes and bad geometry from the solvated
# system before any dynamics. This step does NOT move atoms
# over time — it just finds the nearest energy minimum.
#
# Expected result:
#   - Maximum force (Fmax) drops below 1000 kJ/mol/nm
#   - Potential energy becomes large negative number
#   - Converges in 100–5000 steps typically
#
# Output:
#   em.gro   — minimized coordinates
#   em.edr   — energy data (plot with gmx energy)
#
# Reference: http://www.mdtutorials.com/gmx/complex/04_em.html
# ============================================================

set -euo pipefail

WORKDIR="simulation"

echo "============================================================"
echo " Step 5: Energy Minimization"
echo "============================================================"
echo ""

if [ ! -f "$WORKDIR/complex_solv_ions.gro" ]; then
    echo "ERROR: complex_solv_ions.gro not found. Run step 04 first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Prepare the run (grompp) ----
echo "[1/3] Preparing energy minimization run (grompp)..."
echo "  MDP: ../mdp/em.mdp"
echo ""

gmx grompp \
    -f ../mdp/em.mdp \
    -c complex_solv_ions.gro \
    -p topol.top \
    -o em.tpr \
    -maxwarn 2

# Flag explanations:
# -f em.mdp               Parameters (steepest descent, max 50000 steps)
# -c complex_solv_ions.gro  Input coordinates
# -p topol.top            Topology
# -o em.tpr               Output binary run file

echo "  ✓ em.tpr created"

# ---- Step 2: Run energy minimization ----
echo ""
echo "[2/3] Running energy minimization..."
echo "  This usually takes 1-5 minutes."
echo "  Watch for 'Stepsize too small' or converged Fmax < 1000"
echo ""

# -nt 0 = auto-detect number of CPU threads
gmx mdrun \
    -v \
    -deffnm em \
    -nt 0

# Flag explanations:
# -v          Verbose: print progress to screen
# -deffnm em  Use 'em' as basename for all output files:
#               em.gro  — final coordinates
#               em.edr  — energy file
#               em.log  — detailed log
#               em.trr  — trajectory (not needed for EM, usually empty)

echo ""
echo "  ✓ Energy minimization complete → em.gro"

# ---- Step 3: Check results ----
echo ""
echo "[3/3] Checking minimization results..."
echo "  Extracting potential energy and maximum force..."
echo ""

# Extract potential energy (group 10 is typically Potential)
echo "10 0" | gmx energy \
    -f em.edr \
    -o em_potential.xvg \
    2>&1 | grep -E "Minimum|Maximum|Average|Potential" || true

echo ""
echo "  IMPORTANT — Check the following in em.log:"
echo "  1. Does Fmax drop below 1000 kJ/mol/nm?"
echo "     grep 'Fmax' em.log | tail -5"
echo "  2. Is potential energy negative and reasonable?"
echo "     (typically -10^6 to -10^7 kJ/mol for ~10,000 atoms)"
echo ""
echo "  Run this command to see the final result:"
echo "    grep 'Fmax' $WORKDIR/em.log | tail -3"
echo ""

# Quick check
fmax_line=$(grep "Fmax" em.log | tail -1 || echo "No Fmax found in log")
echo "  Last Fmax line: $fmax_line"

echo ""
echo "============================================================"
echo " Step 5 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   em.gro          — minimized coordinates (input for step 06)"
echo "   em.edr          — energy data"
echo "   em.log          — detailed minimization log"
echo "   em_potential.xvg — potential energy vs step (plot with xmgrace)"
echo ""
echo " To plot potential energy:"
echo "   xmgrace $WORKDIR/em_potential.xvg"
echo ""
echo " Next step: bash scripts/06_nvt_equilibration.sh"
