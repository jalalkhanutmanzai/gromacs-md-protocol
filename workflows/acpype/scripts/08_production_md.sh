#!/bin/bash
# ============================================================
# 08_production_md.sh — Production MD Simulation (100 ns)
# ============================================================
# Run the actual 100 ns molecular dynamics simulation.
# The system is now fully equilibrated (temperature, pressure,
# density). No position restraints are applied.
#
# This is the most computationally intensive step.
# Expected runtime:
#   CPU only (16 cores):  ~48-72 hours
#   GPU (NVIDIA):         ~3-8 hours (depending on GPU model)
#
# Output:
#   md_0_100.xtc  — compressed trajectory (10,000 frames)
#   md_0_100.edr  — energy data
#   md_0_100.cpt  — checkpoint (for resuming if interrupted)
#
# RESUMING: If the simulation is interrupted, resume with:
#   gmx mdrun -v -deffnm md_0_100 -cpi md_0_100.cpt -append
#
# Reference: http://www.mdtutorials.com/gmx/complex/07_md.html
# ============================================================

set -euo pipefail

WORKDIR="simulation"

# ============================================================
# CONFIGURATION — GPU settings
# ============================================================

# Set to "yes" to use GPU acceleration (recommended)
USE_GPU="yes"

# GPU device ID (usually 0 for single GPU, check with nvidia-smi)
GPU_ID="0"

# Number of CPU threads for non-GPU tasks
# Set to 0 for auto-detection
CPU_THREADS="0"

# ============================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================

echo "============================================================"
echo " Step 8: Production MD (100 ns)"
echo "============================================================"
echo ""
echo "Use GPU:      $USE_GPU"
[ "$USE_GPU" = "yes" ] && echo "GPU ID:       $GPU_ID"
echo "CPU threads:  $CPU_THREADS (0 = auto)"
echo "Work dir:     $WORKDIR"
echo ""

if [ ! -f "$WORKDIR/npt.gro" ] || [ ! -f "$WORKDIR/npt.cpt" ]; then
    echo "ERROR: npt.gro or npt.cpt not found. Run step 07 first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Prepare production MD run ----
echo "[1/3] Preparing production MD run (grompp)..."
echo "  MDP: ../mdp/md_100ns.mdp (100 ns, no position restraints)"
echo ""

gmx grompp \
    -f ../mdp/md_100ns.mdp \
    -c npt.gro \
    -t npt.cpt \
    -p topol.top \
    -o md_0_100.tpr \
    -maxwarn 2

# Flag explanations:
# -f md_100ns.mdp  Production parameters (100 ns, no POSRES)
# -c npt.gro       Starting coordinates from NPT equilibration
# -t npt.cpt       Checkpoint carries velocities from NPT
# -p topol.top     Topology
# -o md_0_100.tpr  Output binary run file

echo "  ✓ md_0_100.tpr created"
echo "  TPR info:"
gmx dump -s md_0_100.tpr 2>/dev/null | grep -E "nsteps|dt" | head -5 || true

# ---- Step 2: Run production MD ----
echo ""
echo "[2/3] Starting production MD simulation..."
echo ""
echo "  Duration:  100 ns (50,000,000 steps)"
echo "  Frames:    10,000 (saved every 10 ps)"
echo ""
echo "  ⚠ This will take hours. See README for how to run in background:"
echo "     nohup bash scripts/08_production_md.sh > md.log 2>&1 &"
echo "     or submit as a cluster job."
echo ""

# Build the mdrun command depending on GPU availability
if [ "$USE_GPU" = "yes" ] && command -v nvidia-smi &>/dev/null; then
    echo "  GPU acceleration: ENABLED (GPU $GPU_ID)"
    gmx mdrun \
        -v \
        -deffnm md_0_100 \
        -gpu_id "$GPU_ID" \
        -nt "$CPU_THREADS" \
        -ntmpi 1
else
    echo "  GPU acceleration: DISABLED (CPU only)"
    gmx mdrun \
        -v \
        -deffnm md_0_100 \
        -nt "$CPU_THREADS"
fi

echo ""
echo "  ✓ Production MD complete!"

# ---- Step 3: Quick sanity check ----
echo ""
echo "[3/3] Checking trajectory..."

if [ -f "md_0_100.xtc" ]; then
    frames=$(gmx check -f md_0_100.xtc 2>&1 | grep "Coords" | awk '{print $2}' || echo "unknown")
    echo "  ✓ md_0_100.xtc: $frames frames"
else
    echo "  ✗ md_0_100.xtc not found — simulation may have failed"
    exit 1
fi

echo ""
echo "============================================================"
echo " Step 8 Complete — 100 ns MD Simulation Finished!"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   md_0_100.xtc    — compressed trajectory (10,000 frames)"
echo "   md_0_100.edr    — energy data (temperature, pressure, etc.)"
echo "   md_0_100.log    — simulation log"
echo "   md_0_100.cpt    — final checkpoint"
echo "   md_0_100.tpr    — run input file (keep for analysis)"
echo ""
echo " HOW TO RESUME if interrupted:"
echo "   gmx mdrun -v -deffnm md_0_100 -cpi md_0_100.cpt -append"
echo ""
echo " Next step: bash scripts/09_analysis.sh"
