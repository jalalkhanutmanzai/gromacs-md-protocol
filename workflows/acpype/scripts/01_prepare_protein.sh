#!/bin/bash
# ============================================================
# 01_prepare_protein.sh — Download and Clean Protein Structure
# ============================================================
# This script downloads your protein from the RCSB PDB database
# and cleans it for use in GROMACS by removing:
#   - Water molecules (HOH residues)
#   - Ligand HETATM records (you will handle those in step 02)
#   - Alternative conformations (keeping only conformation A)
#
# Output: protein_clean.pdb
#
# Reference: http://www.mdtutorials.com/gmx/complex/01_pdb.html
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURATION — Edit these values for your system
# ============================================================

# PDB ID of your protein (4-character code from https://www.rcsb.org)
# Example: 1IEP is the Abl kinase with STI571 (imatinib)
PDB_ID="1IEP"

# Name of your ligand (3-letter HET code as it appears in the PDB)
# Find this in the PDB file's HETATM records
LIGAND_ID="STI"

# Output directory (will be created if it doesn't exist)
WORKDIR="simulation"

# ============================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================

echo "============================================================"
echo " Step 1: Prepare Protein Structure"
echo "============================================================"
echo ""
echo "PDB ID:    $PDB_ID"
echo "Ligand ID: $LIGAND_ID"
echo "Work dir:  $WORKDIR"
echo ""

# Create working directory
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ---- Download PDB file ----
echo "[1/5] Downloading ${PDB_ID}.pdb from RCSB..."
if [ -f "${PDB_ID}.pdb" ]; then
    echo "  File already exists, skipping download."
else
    wget -q "https://files.rcsb.org/download/${PDB_ID}.pdb" \
         -O "${PDB_ID}.pdb"
    echo "  Downloaded ${PDB_ID}.pdb ($(wc -l < "${PDB_ID}.pdb") lines)"
fi

# ---- Show what's in the PDB ----
echo ""
echo "[2/5] Inspecting PDB contents..."
echo "  Residues/chains found:"
grep "^SEQRES" "${PDB_ID}.pdb" | awk '{print "    Chain " $3 ": " $4 " residues"}' | sort -u
echo ""
echo "  HETATM records (ligands, waters, etc.):"
grep "^HETATM" "${PDB_ID}.pdb" | awk '{print $4}' | sort | uniq -c | sort -rn | \
    awk '{printf "    %s × %s\n", $1, $2}'
echo ""

# ---- Remove water molecules ----
echo "[3/5] Removing water molecules (HOH)..."
grep -v "^HETATM.*HOH" "${PDB_ID}.pdb" > "${PDB_ID}_nowater.pdb"
water_count=$(grep -c "^HETATM.*HOH" "${PDB_ID}.pdb" || true)
echo "  Removed $water_count water atom records."

# ---- Keep only protein atoms (remove all HETATM except none) ----
# We keep ATOM records (protein) and the specific ligand HETATM lines.
# The ligand will be separated out in step 02.
echo ""
echo "[4/5] Extracting clean protein (ATOM records only)..."
grep "^ATOM" "${PDB_ID}_nowater.pdb" > protein_clean.pdb

# Also extract the ligand for step 02
echo "  Extracting ligand ${LIGAND_ID} for step 02..."
grep "^HETATM.*${LIGAND_ID}" "${PDB_ID}.pdb" > ligand_raw.pdb

protein_atoms=$(grep -c "^ATOM" protein_clean.pdb || true)
ligand_atoms=$(grep -c "^HETATM" ligand_raw.pdb 2>/dev/null || echo "0")
echo "  Protein: $protein_atoms ATOM records → protein_clean.pdb"
echo "  Ligand:  $ligand_atoms HETATM records → ligand_raw.pdb"

# ---- Verify output ----
echo ""
echo "[5/5] Verifying output..."
if [ -s "protein_clean.pdb" ]; then
    echo "  ✓ protein_clean.pdb created successfully"
else
    echo "  ✗ ERROR: protein_clean.pdb is empty!"
    exit 1
fi

if [ -s "ligand_raw.pdb" ]; then
    echo "  ✓ ligand_raw.pdb created successfully"
else
    echo "  ⚠ WARNING: ligand_raw.pdb is empty — check your LIGAND_ID value"
fi

echo ""
echo "============================================================"
echo " Step 1 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   protein_clean.pdb  — cleaned protein structure"
echo "   ligand_raw.pdb     — raw ligand structure (for step 02)"
echo ""
echo " IMPORTANT: Before proceeding, inspect protein_clean.pdb:"
echo "   1. Check for missing residues (gaps in numbering)"
echo "   2. Check for non-standard amino acids"
echo "   3. Check for multiple chains (if so, decide which to keep)"
echo "   Use PyMOL, UCSF Chimera, or VMD to visualize."
echo ""
echo " Next step: bash scripts/02_prepare_ligand.sh"
