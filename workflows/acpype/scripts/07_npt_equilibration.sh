#!/bin/bash
# ============================================================
# 07_npt_equilibration.sh — NPT Equilibration (100 ps)
# ============================================================
# Equilibrate the system at constant temperature AND pressure.
# This allows the box size (and hence density) to relax to the
# correct equilibrium value before production MD.
#
# NPT = constant Number of particles, Pressure, Temperature
# Duration: 100 ps (50,000 steps × 0.002 ps)
#
# Expected result:
#   - Pressure fluctuates around 1 bar (fluctuations of ±100 bar
#     are NORMAL — only the average matters)
#   - Density stabilizes around 1000 kg/m³ (water density)
#   - Temperature remains around 300 K
#
# Output:
#   npt.gro  — NPT equilibrated coordinates
#   npt.cpt  — checkpoint file (needed for production MD)
#
# Reference: http://www.mdtutorials.com/gmx/complex/06_npt.html
# ============================================================

set -euo pipefail

WORKDIR="simulation"

echo "============================================================"
echo " Step 7: NPT Equilibration (100 ps)"
echo "============================================================"
echo ""

if [ ! -f "$WORKDIR/nvt.gro" ] || [ ! -f "$WORKDIR/nvt.cpt" ]; then
    echo "ERROR: nvt.gro or nvt.cpt not found. Run step 06 first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Prepare NPT run ----
echo "[1/3] Preparing NPT equilibration run (grompp)..."
echo "  MDP: ../mdp/npt.mdp (100 ps, 300 K, 1 bar, Parrinello-Rahman)"
echo ""

gmx grompp \
    -f ../mdp/npt.mdp \
    -c nvt.gro \
    -r nvt.gro \
    -t nvt.cpt \
    -p topol.top \
    -o npt.tpr \
    -maxwarn 2

# Flag explanations:
# -f npt.mdp   NPT parameters (adds Parrinello-Rahman barostat)
# -c nvt.gro   Starting coordinates from NVT equilibration
# -r nvt.gro   Reference coordinates for position restraints
# -t nvt.cpt   Checkpoint from NVT (carries velocities forward)
# -p topol.top Topology
# -o npt.tpr   Output binary run file

echo "  ✓ npt.tpr created"

# ---- Step 2: Run NPT equilibration ----
echo ""
echo "[2/3] Running NPT equilibration..."
echo "  Duration: 100 ps — expect ~5-15 minutes on CPU, ~1-2 min on GPU"
echo ""

gmx mdrun \
    -v \
    -deffnm npt \
    -nt 0

echo ""
echo "  ✓ NPT equilibration complete"

# ---- Step 3: Check pressure and density ----
echo ""
echo "[3/3] Checking pressure and density..."

# Extract pressure (group 17 typically) and density (group 24 typically)
echo "17 0" | gmx energy \
    -f npt.edr \
    -o npt_pressure.xvg \
    2>&1 | grep -E "Pressure|Average|Std" || true

echo ""

echo "24 0" | gmx energy \
    -f npt.edr \
    -o npt_density.xvg \
    2>&1 | grep -E "Density|Average|Std" || true

echo ""
echo "  Expected:"
echo "    Pressure: average ~1 bar (fluctuations of ±50-100 bar are normal)"
echo "    Density:  average ~1000 kg/m³ (water density at 300K)"
echo ""
echo "  To plot:"
echo "    xmgrace $WORKDIR/npt_pressure.xvg"
echo "    xmgrace $WORKDIR/npt_density.xvg"

echo ""
echo "============================================================"
echo " Step 7 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   npt.gro           — NPT equilibrated coordinates"
echo "   npt.cpt           — CHECKPOINT (REQUIRED for step 08)"
echo "   npt.edr           — energy data"
echo "   npt_pressure.xvg  — pressure vs time"
echo "   npt_density.xvg   — density vs time"
echo ""
echo " If pressure/density look stable, you are ready for production MD."
echo ""
echo " Next step: bash scripts/08_production_md.sh"
