#!/bin/bash
# ============================================================
# 03_build_topology.sh — Build System Topology
# ============================================================
# This script:
#   1. Generates the protein topology with pdb2gmx
#      (assigns force field, adds hydrogens, creates .itp/.top)
#   2. Combines the protein and ligand .gro coordinate files
#   3. Edits topol.top to include the ligand topology
#
# Output:
#   complex.gro   — protein + ligand coordinates combined
#   topol.top     — complete topology file
#   posre.itp     — position restraints for protein heavy atoms
#
# Reference: http://www.mdtutorials.com/gmx/complex/02_topology.html
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURATION — Edit these values
# ============================================================

# Force field for the protein.
# Common choices:
#   charmm36-jul2022  — CHARMM36m (recommended for proteins, 2022 version)
#   amber99sb-ildn    — AMBER99SB-ILDN (also widely used)
#   gromos96 53a6     — GROMOS96 (choose "6" in the interactive prompt)
# The value here must match what pdb2gmx accepts interactively (or use -ff flag)
FORCE_FIELD="charmm36-jul2022"

# Water model (must be compatible with your force field):
#   tip3p   — compatible with CHARMM36 and AMBER
#   tip4p   — 4-point water, more accurate
#   spc/e   — compatible with GROMOS
WATER_MODEL="tip3p"

# Residue name of the ligand in the topology (from step 02)
LIGAND_RESNAME="LIG"

# Work directory (must match previous steps)
WORKDIR="simulation"

# ============================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================

echo "============================================================"
echo " Step 3: Build System Topology"
echo "============================================================"
echo ""
echo "Force field:  $FORCE_FIELD"
echo "Water model:  $WATER_MODEL"
echo "Ligand name:  $LIGAND_RESNAME"
echo "Work dir:     $WORKDIR"
echo ""

# Verify inputs from previous steps
for f in protein_clean.pdb ligand.gro ligand.itp; do
    if [ ! -f "$WORKDIR/$f" ]; then
        echo "ERROR: $WORKDIR/$f not found. Run step 01 and 02 first."
        exit 1
    fi
done

cd "$WORKDIR"

# ---- Step 1: Generate protein topology ----
echo "[1/4] Running pdb2gmx to generate protein topology..."
echo "  Force field: $FORCE_FIELD"
echo "  Water model: $WATER_MODEL"
echo ""
echo "  NOTE: pdb2gmx may ask interactive questions:"
echo "    - Which force field? → Choose $FORCE_FIELD"
echo "    - Missing atoms? → Usually press Enter to accept defaults"
echo "    - His protonation? → Usually press Enter (automatic)"
echo ""

gmx pdb2gmx \
    -f protein_clean.pdb \
    -o protein_processed.gro \
    -p topol.top \
    -i posre.itp \
    -ff "$FORCE_FIELD" \
    -water "$WATER_MODEL" \
    -ignh \
    -missing

# Flag explanations:
# -f protein_clean.pdb    Input protein structure
# -o protein_processed.gro  Output coordinates (GROMACS format)
# -p topol.top              Output topology file
# -i posre.itp              Output position restraints file
# -ff charmm36-jul2022      Force field to use
# -water tip3p              Water model
# -ignh                     Ignore all hydrogen atoms in the input
#                           (GROMACS adds them correctly for the force field)
# -missing                  Don't stop for missing atoms (use cautiously)

echo ""
echo "  ✓ Protein topology generated:"
echo "    protein_processed.gro  — protein coordinates with correct hydrogens"
echo "    topol.top              — protein topology"
echo "    posre.itp              — position restraints"

# ---- Step 2: Get atom count for combining gro files ----
echo ""
echo "[2/4] Combining protein and ligand coordinate files..."

# Get number of atoms in each file
protein_atoms=$(awk 'NR==2 {print $1}' protein_processed.gro)
ligand_atoms=$(awk 'NR==2 {print $1}' ligand.gro)
total_atoms=$((protein_atoms + ligand_atoms))

echo "  Protein atoms: $protein_atoms"
echo "  Ligand atoms:  $ligand_atoms"
echo "  Total atoms:   $total_atoms"

# Combine: take header from protein, all atom lines from both, box from protein
{
    head -2 protein_processed.gro
    # protein atom lines (skip first 2 lines header and last line box)
    tail -n +3 protein_processed.gro | head -n -1
    # ligand atom lines (skip first 2 lines header and last line box)
    tail -n +3 ligand.gro | head -n -1
    # box vectors from protein gro (last line)
    tail -1 protein_processed.gro
} > complex_tmp.gro

# Update the atom count (line 2) in the combined file
{
    head -1 complex_tmp.gro
    echo "  $total_atoms"
    tail -n +3 complex_tmp.gro
} > complex.gro

rm complex_tmp.gro

echo "  ✓ Combined coordinates → complex.gro ($total_atoms atoms)"

# ---- Step 3: Add ligand to topology ----
echo ""
echo "[3/4] Adding ligand topology to topol.top..."

# Add the ligand .itp include after the protein itp includes
# We insert before the system/molecules section
if grep -q "ligand.itp" topol.top; then
    echo "  ligand.itp already included in topol.top (skipping)"
else
    # Insert #include "ligand.itp" before the [ system ] section
    sed -i '/\[ system \]/i ; Include ligand topology\n#include "ligand.itp"\n' topol.top
    echo "  ✓ Added: #include \"ligand.itp\" to topol.top"
fi

# Add ligand molecule count to [ molecules ] section
if grep -q "$LIGAND_RESNAME" topol.top; then
    echo "  $LIGAND_RESNAME already listed in [ molecules ] (skipping)"
else
    # Append ligand to the molecules section
    echo "${LIGAND_RESNAME}               1" >> topol.top
    echo "  ✓ Added: ${LIGAND_RESNAME} 1 to [ molecules ] in topol.top"
fi

echo ""
echo "  topol.top now includes:"
grep "^#include\|^\[.*\]\|Protein\|${LIGAND_RESNAME}" topol.top | head -20

# ---- Step 4: Verify topology ----
echo ""
echo "[4/4] Verifying topology with grompp (dry run)..."
gmx grompp \
    -f ../mdp/em.mdp \
    -c complex.gro \
    -p topol.top \
    -o em_check.tpr \
    -maxwarn 5 \
    2>&1 | tail -20

if [ -f "em_check.tpr" ]; then
    echo "  ✓ Topology is valid! (em_check.tpr created)"
    rm em_check.tpr
else
    echo "  ✗ Topology check failed. Review the grompp output above."
    exit 1
fi

echo ""
echo "============================================================"
echo " Step 3 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   complex.gro             — protein + ligand coordinates"
echo "   topol.top               — complete system topology"
echo "   protein_processed.gro   — protein with correct hydrogens"
echo "   posre.itp               — protein position restraints"
echo ""
echo " Next step: bash scripts/04_solvation_ions.sh"
