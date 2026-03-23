#!/bin/bash
# ============================================================
# 04_solvation_ions.sh — Define Box, Solvate, and Add Ions
# ============================================================
# This script:
#   1. Defines a simulation box around the complex
#   2. Fills the box with explicit water molecules (TIP3P)
#   3. Adds Na+ and Cl- ions to neutralize the system charge
#      and reach physiological salt concentration (0.15 M NaCl)
#
# Output:
#   complex_solv_ions.gro  — solvated, neutralized system
#   topol.top              — updated with water/ion counts
#
# Reference: http://www.mdtutorials.com/gmx/complex/03_solvation.html
# ============================================================

set -euo pipefail

# ============================================================
# CONFIGURATION — Edit these values
# ============================================================

# Box type:
#   dodecahedron  — rhombic dodecahedron (most efficient, ~71% less volume)
#   cubic         — simple cube (simpler, but uses more water)
BOX_TYPE="dodecahedron"

# Minimum distance from the protein to the box edge (nm)
# 1.0 nm = standard; use 1.2 nm for flexible/large proteins
BOX_DISTANCE="1.0"

# Salt concentration in mol/L (0.15 M = physiological NaCl)
SALT_CONC="0.15"

# Positive ion name (Na for Na+, K for K+)
POS_ION="NA"

# Negative ion name (Cl for Cl-)
NEG_ION="CL"

# Work directory
WORKDIR="simulation"

# ============================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================

echo "============================================================"
echo " Step 4: Solvation and Ion Addition"
echo "============================================================"
echo ""
echo "Box type:      $BOX_TYPE"
echo "Box distance:  $BOX_DISTANCE nm"
echo "Salt conc:     $SALT_CONC mol/L"
echo "Ions:          $POS_ION+ / $NEG_ION-"
echo "Work dir:      $WORKDIR"
echo ""

# Verify input from step 03
if [ ! -f "$WORKDIR/complex.gro" ] || [ ! -f "$WORKDIR/topol.top" ]; then
    echo "ERROR: complex.gro or topol.top not found."
    echo "  Please run scripts/03_build_topology.sh first."
    exit 1
fi

cd "$WORKDIR"

# ---- Step 1: Define the simulation box ----
echo "[1/4] Defining simulation box..."
echo "  Box type: $BOX_TYPE"
echo "  Minimum protein-to-edge distance: $BOX_DISTANCE nm"
echo ""

gmx editconf \
    -f complex.gro \
    -o complex_box.gro \
    -c \
    -d "$BOX_DISTANCE" \
    -bt "$BOX_TYPE"

# Flag explanations:
# -f complex.gro       Input coordinates
# -o complex_box.gro   Output with box defined
# -c                   Center the molecule in the box
# -d 1.0               Minimum distance from molecule to box wall (nm)
# -bt dodecahedron     Box type (dodecahedron is most water-efficient)

echo "  ✓ Box defined → complex_box.gro"

# ---- Step 2: Solvate the system ----
echo ""
echo "[2/4] Solvating the system with TIP3P water..."

gmx solvate \
    -cp complex_box.gro \
    -cs spc216.gro \
    -p topol.top \
    -o complex_solv.gro

# Flag explanations:
# -cp complex_box.gro   Solute (protein+ligand) coordinates
# -cs spc216.gro        Water box template (spc216 is TIP3P-compatible)
# -p topol.top          Topology — gmx will add the SOL count automatically!
# -o complex_solv.gro   Output: solvated system

water_count=$(grep "^SOL" topol.top | awk '{print $2}')
echo "  ✓ Solvation complete → complex_solv.gro"
echo "  Water molecules added: $water_count"

# ---- Step 3: Add ions ----
echo ""
echo "[3/4] Adding ions (neutralize + $SALT_CONC mol/L NaCl)..."
echo "  This requires a .tpr file (grompp input) as intermediary."
echo ""

# First, generate a .tpr file for genion (energy minimization mdp is fine here)
gmx grompp \
    -f ../mdp/em.mdp \
    -c complex_solv.gro \
    -p topol.top \
    -o ions.tpr \
    -maxwarn 2

# Now add ions — genion replaces water molecules with ions
# The 'echo SOL' auto-selects the solvent group when prompted
echo "SOL" | gmx genion \
    -s ions.tpr \
    -o complex_solv_ions.gro \
    -p topol.top \
    -pname "$POS_ION" \
    -nname "$NEG_ION" \
    -neutral \
    -conc "$SALT_CONC"

# Flag explanations:
# -s ions.tpr            Input run file
# -o complex_solv_ions.gro  Output: system with ions
# -p topol.top           Updated topology (ion counts added automatically)
# -pname NA              Positive ion name
# -nname CL              Negative ion name
# -neutral               Add enough ions to neutralize net charge
# -conc 0.15             Add extra ions to reach 0.15 mol/L salt concentration

echo "  ✓ Ions added → complex_solv_ions.gro"

# ---- Step 4: Report system composition ----
echo ""
echo "[4/4] Final system summary:"
echo "  Atom counts in topol.top [molecules] section:"
grep -A 20 "\[ molecules \]" topol.top | grep -v "^;" | grep -v "^\[" | grep -v "^$"

# Count ions added
na_count=$(grep " ${POS_ION} " topol.top | awk '{print $2}' || echo "0")
cl_count=$(grep " ${NEG_ION} " topol.top | awk '{print $2}' || echo "0")
echo ""
echo "  Na+ ions: $na_count"
echo "  Cl- ions: $cl_count"

# Clean up intermediate files
rm -f ions.tpr

echo ""
echo "============================================================"
echo " Step 4 Complete"
echo "============================================================"
echo ""
echo " Output files in $WORKDIR/:"
echo "   complex_solv_ions.gro  — FINAL input for simulations"
echo "   topol.top              — updated topology (check ion/water counts)"
echo ""
echo " VISUALIZE: Load complex_solv_ions.gro in VMD or PyMOL"
echo "   to verify the system looks correct before running MD."
echo ""
echo " Next step: bash scripts/05_energy_minimization.sh"
