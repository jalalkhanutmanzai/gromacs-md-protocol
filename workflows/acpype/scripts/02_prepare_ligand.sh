#!/bin/bash
# ============================================================
# 02_prepare_ligand.sh — Generate Ligand GROMACS Topology
# ============================================================
# Small molecule ligands are not parameterized by GROMOS or
# CHARMM force fields. We use ACPYPE (which wraps antechamber)
# to generate GAFF2 parameters and GROMACS-format topology.
#
# What this script does:
#   1. Checks for the ligand PDB from step 01
#   2. Converts PDB → MOL2 using antechamber (assigns charges)
#   3. Runs ACPYPE to generate GROMACS topology (.itp + .gro)
#
# Output files (in simulation/LIG_GMX.acpype/):
#   LIG_GMX.itp   — ligand topology (force field parameters)
#   LIG_GMX.gro   — ligand coordinates in GROMACS format
#   LIG_GMX.top   — standalone topology (for checking only)
#
# Reference: http://www.mdtutorials.com/gmx/complex/02_topology.html
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURATION — Edit these values
# ============================================================

# Net charge of the ligand (integer, e.g. 0, -1, -2, +1)
# Find this from the literature or compute with:
#   antechamber -i ligand_raw.pdb -fi pdb -o tmp.mol2 -fo mol2 -c bcc -nc 0
# Common examples:
#   Imatinib (STI571): 0
#   ATP:               -4
#   GTP:               -4
LIGAND_CHARGE=0

# Name prefix for the ligand (3 letters, uppercase)
# Used internally by GROMACS — keep it short
LIGAND_NAME="LIG"

# Work directory (must match step 01)
WORKDIR="simulation"

# ============================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================

echo "============================================================"
echo " Step 2: Prepare Ligand Topology"
echo "============================================================"
echo ""
echo "Ligand charge: $LIGAND_CHARGE"
echo "Ligand name:   $LIGAND_NAME"
echo "Work dir:      $WORKDIR"
echo ""

# Verify step 01 was completed
if [ ! -f "$WORKDIR/ligand_raw.pdb" ]; then
    echo "ERROR: $WORKDIR/ligand_raw.pdb not found."
    echo "  Please run scripts/01_prepare_protein.sh first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Add hydrogens and assign partial charges with antechamber ----
echo "[1/3] Running antechamber to assign GAFF2 atom types and AM1-BCC charges..."
echo "  This may take 1-5 minutes depending on ligand size..."
echo ""

antechamber \
    -i ligand_raw.pdb \
    -fi pdb \
    -o "${LIGAND_NAME}.mol2" \
    -fo mol2 \
    -c bcc \
    -s 2 \
    -nc "$LIGAND_CHARGE" \
    -at gaff2

# Explanation of flags:
# -i  ligand_raw.pdb    Input file
# -fi pdb               Input format: PDB
# -o  LIG.mol2          Output file
# -fo mol2              Output format: MOL2
# -c  bcc               Charge method: AM1-BCC (standard for small molecules)
# -s  2                 Verbosity: show warnings
# -nc 0                 Net charge of the molecule
# -at gaff2             Atom type: GAFF2 (General AMBER Force Field v2)

echo ""
echo "  ✓ antechamber complete → ${LIGAND_NAME}.mol2"

# ---- Step 2: Check for missing parameters with parmchk2 ----
echo ""
echo "[2/3] Running parmchk2 to check for missing force field parameters..."
parmchk2 \
    -i "${LIGAND_NAME}.mol2" \
    -f mol2 \
    -o "${LIGAND_NAME}.frcmod"

echo "  ✓ parmchk2 complete → ${LIGAND_NAME}.frcmod"
echo "  (If the .frcmod file has entries, some parameters were estimated)"

# ---- Step 3: Run ACPYPE to generate GROMACS topology ----
echo ""
echo "[3/3] Running ACPYPE to generate GROMACS topology files..."
echo "  This will create a folder: ${LIGAND_NAME}_GMX.acpype/"
echo ""

acpype \
    -i "${LIGAND_NAME}.mol2" \
    -b "${LIGAND_NAME}_GMX" \
    -c bcc \
    -n "$LIGAND_CHARGE" \
    -a gaff2

# Output files from ACPYPE:
# LIG_GMX.acpype/
#   LIG_GMX_GMX.gro    — ligand coordinates (GROMACS format)
#   LIG_GMX_GMX.itp    — ligand topology (parameters)
#   LIG_GMX_GMX.top    — standalone topology (for testing)

# Rename output files to simpler names for later steps
ACPYPE_DIR="${LIGAND_NAME}_GMX.acpype"

if [ -d "$ACPYPE_DIR" ]; then
    # Find the generated files (ACPYPE may vary the naming)
    GRO_FILE=$(find "$ACPYPE_DIR" -name "*.gro" | head -1)
    ITP_FILE=$(find "$ACPYPE_DIR" -name "*GMX.itp" | head -1)

    cp "$GRO_FILE" ligand.gro
    cp "$ITP_FILE" ligand.itp

    echo "  ✓ ACPYPE complete"
    echo "  ✓ Copied to: ligand.gro and ligand.itp"
else
    echo "  ✗ ERROR: ACPYPE output directory not found: $ACPYPE_DIR"
    exit 1
fi

echo ""
echo "============================================================"
echo " Step 2 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   ligand.gro    — ligand coordinates (GROMACS format)"
echo "   ligand.itp    — ligand topology (include in topol.top)"
echo "   ${LIGAND_NAME}_GMX.acpype/  — full ACPYPE output"
echo ""
echo " Next step: bash scripts/03_build_topology.sh"
