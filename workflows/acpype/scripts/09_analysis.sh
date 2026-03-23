#!/bin/bash
# ============================================================
# 09_analysis.sh — Trajectory Analysis
# ============================================================
# Perform standard analyses on the 100 ns MD trajectory:
#
#   1. Trajectory centering/wrapping (periodic boundary fix)
#   2. RMSD  — structural stability of protein backbone
#   3. RMSF  — per-residue flexibility
#   4. Radius of gyration (Rg) — compactness of protein
#   5. Hydrogen bonds  — protein-ligand H-bond count over time
#   6. SASA  — solvent accessible surface area
#   7. Ligand RMSD  — stability of ligand in binding site
#
# Output: analysis/ directory with .xvg files (plot with xmgrace)
#
# Reference: http://www.mdtutorials.com/gmx/complex/08_analysis.html
# ============================================================

set -euo pipefail

WORKDIR="simulation"
ANALYSIS_DIR="$WORKDIR/analysis"

# Ligand residue name (must match what's in your topology)
LIGAND_RESNAME="LIG"

echo "============================================================"
echo " Step 9: Trajectory Analysis"
echo "============================================================"
echo ""

# Verify production MD output exists
if [ ! -f "$WORKDIR/md_0_100.xtc" ] || [ ! -f "$WORKDIR/md_0_100.tpr" ]; then
    echo "ERROR: md_0_100.xtc or md_0_100.tpr not found."
    echo "  Please run scripts/08_production_md.sh first."
    exit 1
fi

mkdir -p "$ANALYSIS_DIR"
cd "$WORKDIR"

echo "Analysis output directory: $ANALYSIS_DIR"
echo ""

# ============================================================
# Create custom index file with Protein+Ligand group
# ============================================================
# GROMACS default index groups may not include a combined
# Protein+Ligand group. We create a custom index file so that
# all analysis commands can reliably find the ligand group.
echo "[0/7] Creating custom index file..."

# Build index: keep default groups, add Protein_LIG = Protein + ligand
{
    echo "q"
} | gmx make_ndx \
    -f md_0_100.tpr \
    -o analysis/index.ndx \
    2>&1 | tail -10

# Find the ligand group number so we can combine it with Protein
LIG_GROUP=$(echo "q" | gmx make_ndx -f md_0_100.tpr -o /dev/null 2>&1 \
    | grep -i " ${LIGAND_RESNAME}" | awk '{print $1}' | head -1)

if [ -n "$LIG_GROUP" ]; then
    echo "  Ligand group number: $LIG_GROUP"
    # Create combined Protein_LIG group
    printf "1 | %s\nname %s Protein_LIG\nq\n" "$LIG_GROUP" "$(($(echo "q" | gmx make_ndx -f md_0_100.tpr -o /dev/null 2>&1 | grep "^  [0-9]" | tail -1 | awk '{print $1}') + 1))" \
        | gmx make_ndx -f md_0_100.tpr -n analysis/index.ndx -o analysis/index.ndx 2>&1 | tail -5 || true
    echo "  ✓ Custom index file → analysis/index.ndx"
else
    echo "  ⚠ Could not find ligand group '$LIGAND_RESNAME' — using default index"
    echo "  Check group names with: echo q | gmx make_ndx -f $WORKDIR/md_0_100.tpr"
fi
echo ""

# ============================================================
# Step 1: Fix periodic boundary conditions
# ============================================================
# The trajectory may show molecules "jumping" across the box
# boundary due to PBC. This step centers the protein and
# makes the trajectory visually continuous.
echo "[1/7] Fixing periodic boundaries and centering trajectory..."

# Select: 1 = Protein (center), 0 = System (output)
echo "1 0" | gmx trjconv \
    -s md_0_100.tpr \
    -f md_0_100.xtc \
    -o analysis/md_center.xtc \
    -center \
    -pbc mol \
    -ur compact \
    2>&1 | tail -5

echo "  ✓ Centered trajectory → analysis/md_center.xtc"

# ============================================================
# Step 2: RMSD — Protein Backbone Stability
# ============================================================
# RMSD (Root Mean Square Deviation) measures how much the
# protein structure deviates from the starting structure.
# A stable simulation should plateau after ~10-20 ns.
# Values <3 Å = stable; >5 Å = large conformational change.
echo ""
echo "[2/7] Calculating protein backbone RMSD..."

# Select: 4 = Backbone (reference), 4 = Backbone (group to fit)
echo "4 4" | gmx rms \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsd_protein.xvg \
    -tu ns \
    2>&1 | tail -5

echo "  ✓ Protein RMSD → analysis/rmsd_protein.xvg"

# Ligand RMSD (fit to protein backbone, measure ligand displacement)
echo ""
echo "  Calculating ligand RMSD (relative to protein frame)..."
# Uses custom index file so GROMACS can find the ligand group
# If this fails, run: echo q | gmx make_ndx -f md_0_100.tpr
# and look for the ligand group number, then replace the echo below
echo "4 ${LIG_GROUP:-${LIGAND_RESNAME}}" | gmx rms \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsd_ligand.xvg \
    -n analysis/index.ndx \
    -tu ns \
    2>&1 | tail -5 || \
    echo "  ⚠ Ligand RMSD skipped — run: echo q | gmx make_ndx -f $WORKDIR/md_0_100.tpr to find ligand group number"

echo "  ✓ Ligand RMSD → analysis/rmsd_ligand.xvg"

# ============================================================
# Step 3: RMSF — Per-Residue Flexibility
# ============================================================
# RMSF (Root Mean Square Fluctuation) shows how much each
# residue moves during the simulation.
# High RMSF = flexible region (loops, termini)
# Low RMSF  = rigid region (secondary structure, active site)
echo ""
echo "[3/7] Calculating per-residue RMSF..."

# Select: 1 = Protein
echo "1" | gmx rmsf \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/rmsf.xvg \
    -res \
    2>&1 | tail -5

echo "  ✓ Per-residue RMSF → analysis/rmsf.xvg"

# ============================================================
# Step 4: Radius of Gyration
# ============================================================
# Rg measures the overall compactness of the protein.
# A stable, folded protein should have a relatively constant Rg.
# Increasing Rg = protein unfolding or expansion.
echo ""
echo "[4/7] Calculating radius of gyration..."

# Select: 1 = Protein
echo "1" | gmx gyrate \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/gyrate.xvg \
    2>&1 | tail -5

echo "  ✓ Radius of gyration → analysis/gyrate.xvg"

# ============================================================
# Step 5: Protein-Ligand Hydrogen Bonds
# ============================================================
# Count H-bonds between protein and ligand over the simulation.
# More H-bonds generally = stronger/more stable binding.
echo ""
echo "[5/7] Calculating protein-ligand hydrogen bonds..."

# Select: 1 = Protein, then ligand
echo "1 ${LIG_GROUP:-${LIGAND_RESNAME}}" | gmx hbond \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -n analysis/index.ndx \
    -num analysis/hbond.xvg \
    2>&1 | tail -5 || \
    echo "  ⚠ H-bond calculation skipped — check ligand group number in analysis/index.ndx"

echo "  ✓ H-bond count → analysis/hbond.xvg"

# ============================================================
# Step 6: SASA — Solvent Accessible Surface Area
# ============================================================
# SASA measures how much of the protein surface is exposed
# to solvent. Useful for monitoring protein folding/stability.
echo ""
echo "[6/7] Calculating solvent accessible surface area (SASA)..."

# Select: 1 = Protein
echo "1" | gmx sasa \
    -s md_0_100.tpr \
    -f analysis/md_center.xtc \
    -o analysis/sasa.xvg \
    2>&1 | tail -5

echo "  ✓ SASA → analysis/sasa.xvg"

# ============================================================
# Step 7: Summary and plotting instructions
# ============================================================
echo ""
echo "[7/7] Analysis summary..."
echo ""
echo "  Files created in $ANALYSIS_DIR:"
ls -lh analysis/*.xvg 2>/dev/null | awk '{print "  ", $9, $5}' || true

echo ""
echo "============================================================"
echo " Step 9 Complete — Analysis Finished!"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/analysis/:"
echo "   md_center.xtc      — PBC-corrected trajectory (use for visualization)"
echo "   rmsd_protein.xvg   — Protein backbone RMSD vs time"
echo "   rmsd_ligand.xvg    — Ligand RMSD vs time"
echo "   rmsf.xvg           — Per-residue flexibility"
echo "   gyrate.xvg         — Radius of gyration vs time"
echo "   hbond.xvg          — Protein-ligand H-bonds vs time"
echo "   sasa.xvg           — Solvent accessible surface area"
echo ""
echo " PLOTTING (with xmgrace):"
echo "   xmgrace $WORKDIR/analysis/rmsd_protein.xvg"
echo "   xmgrace $WORKDIR/analysis/rmsf.xvg"
echo "   xmgrace $WORKDIR/analysis/gyrate.xvg"
echo "   xmgrace $WORKDIR/analysis/hbond.xvg"
echo ""
echo " VISUALIZATION (in VMD or PyMOL):"
echo "   Load $WORKDIR/md_0_100.tpr as structure"
echo "   Load $WORKDIR/analysis/md_center.xtc as trajectory"
echo ""
echo " See docs/09_analysis.md for detailed interpretation guide."
