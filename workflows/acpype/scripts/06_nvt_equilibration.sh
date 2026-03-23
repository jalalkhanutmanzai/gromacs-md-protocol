#!/bin/bash
# ============================================================
# 06_nvt_equilibration.sh — NVT Equilibration (100 ps)
# ============================================================
# Equilibrate the system at constant temperature (300 K) with
# fixed volume. This stabilizes temperature before we adjust
# pressure in the NPT step.
#
# NVT = constant Number of particles, Volume, Temperature
# Duration: 100 ps (50,000 steps × 0.002 ps)
#
# Position restraints are applied to protein heavy atoms so
# the water and ions can relax around the protein structure.
#
# Expected result:
#   - Temperature stabilizes around 300 K
#   - No energy drift
#
# Output:
#   nvt.gro  — equilibrated coordinates
#   nvt.cpt  — checkpoint file (needed for NPT)
#
# Reference: http://www.mdtutorials.com/gmx/complex/05_nvt.html
# ============================================================

set -euo pipefail

WORKDIR="simulation"

echo "============================================================"
echo " Step 6: NVT Equilibration (100 ps)"
echo "============================================================"
echo ""

if [ ! -f "$WORKDIR/em.gro" ]; then
    echo "ERROR: em.gro not found. Run step 05 first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Prepare NVT run ----
echo "[1/3] Preparing NVT equilibration run (grompp)..."
echo "  MDP: ../mdp/nvt.mdp (100 ps, 300 K, V-rescale thermostat)"
echo ""

gmx grompp \
    -f ../mdp/nvt.mdp \
    -c em.gro \
    -r em.gro \
    -p topol.top \
    -o nvt.tpr \
    -maxwarn 2

# Flag explanations:
# -f nvt.mdp   NVT parameters
# -c em.gro    Starting coordinates (from energy minimization)
# -r em.gro    Reference coordinates for position restraints
#              (POSRES in the mdp uses this to restrain heavy atoms)
# -p topol.top Topology
# -o nvt.tpr   Output binary run file

echo "  ✓ nvt.tpr created"

# ---- Step 2: Run NVT equilibration ----
echo ""
echo "[2/3] Running NVT equilibration..."
echo "  Duration: 100 ps — expect ~5-15 minutes on CPU, ~1-2 min on GPU"
echo ""

gmx mdrun \
    -v \
    -deffnm nvt \
    -nt 0

echo ""
echo "  ✓ NVT equilibration complete"

# ---- Step 3: Check temperature ----
echo ""
echo "[3/3] Checking temperature equilibration..."

# Group 16 is typically Temperature
echo "16 0" | gmx energy \
    -f nvt.edr \
    -o nvt_temperature.xvg \
    2>&1 | grep -E "Temperature|Average|Std" || true

echo ""
echo "  Expected: temperature average ~300 K with small fluctuations (<5 K)"
echo ""
echo "  To plot:"
echo "    xmgrace $WORKDIR/nvt_temperature.xvg"
echo ""
echo "  Detailed check:"
echo "    echo '16 0' | gmx energy -f $WORKDIR/nvt.edr -o /tmp/temp.xvg"

echo ""
echo "============================================================"
echo " Step 6 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   nvt.gro             — NVT equilibrated coordinates"
echo "   nvt.cpt             — CHECKPOINT file (REQUIRED for step 07)"
echo "   nvt.edr             — energy data"
echo "   nvt_temperature.xvg — temperature vs time"
echo ""
echo " Next step: bash scripts/07_npt_equilibration.sh"
