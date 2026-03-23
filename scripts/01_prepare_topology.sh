#!/usr/bin/env bash
# scripts/01_prepare_topology.sh
# ─────────────────────────────────────────────────────────────────────────────
# Build the protein–ligand complex topology.
#
# Inputs  (from config/config.env):
#   input/protein_clean.pdb
#   input/charmm_ligand/lig_ini.pdb
#   input/charmm_ligand/lig.itp
#
# Outputs (work/01_topology/):
#   complex.gro   — protein + ligand coordinates
#   topol.top     — complete system topology
#   posre.itp     — position restraints for protein heavy atoms
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${REPO_ROOT}/config/config.env"

# ── Load config ──────────────────────────────────────────────────────────────
if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] config/config.env not found. Copy config.env.example and edit it."
    exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

GMX="${GMX_BIN:-gmx}"
STEP_DIR="${REPO_ROOT}/${WORK_DIR:-work}/01_topology"
INPUT="${REPO_ROOT}/${INPUT_DIR:-input}"
LIG_DIR="${INPUT}/${LIGAND_DIR:-charmm_ligand}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 01: Prepare topology ==="

# ── Validate inputs ───────────────────────────────────────────────────────────
PROTEIN_FILE="${INPUT}/${PROTEIN_PDB:-protein_clean.pdb}"
LIG_PDB="${LIG_DIR}/${LIGAND_PDB:-lig_ini.pdb}"
LIG_ITP="${LIG_DIR}/${LIGAND_ITP:-lig.itp}"

for f in "$PROTEIN_FILE" "$LIG_PDB" "$LIG_ITP"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        echo "        See docs/01_PREREQUISITES.md for how to obtain input files."
        exit 1
    fi
done

mkdir -p "$STEP_DIR"
cd "$STEP_DIR"

# ── 1. pdb2gmx — generate protein topology ───────────────────────────────────
log "Running pdb2gmx on protein..."

# Use printf to feed the water model selection non-interactively.
# The '1' selects the first option when pdb2gmx asks about histidine protonation.
# Adjust if your protein has histidines that need specific protonation states.
printf "1\n" | "$GMX" pdb2gmx \
    -f "$PROTEIN_FILE" \
    -o protein_processed.gro \
    -p topol.top \
    -i posre.itp \
    -ff "${FF_NAME:-charmm36-jul2022}" \
    -water "${WATER_MODEL:-tip3p}" \
    -ignh \
    2>&1 | tee pdb2gmx.log

log "pdb2gmx complete."

# ── 2. Convert ligand coordinates to .gro ────────────────────────────────────
log "Converting ligand coordinates..."
"$GMX" editconf \
    -f "$LIG_PDB" \
    -o lig.gro \
    2>&1 | tee editconf_lig.log

# ── 3. Merge protein + ligand coordinates ────────────────────────────────────
log "Merging protein and ligand coordinates..."

N_PROT=$(awk 'NR==2 {print $1}' protein_processed.gro)
N_LIG=$(awk 'NR==2 {print $1}' lig.gro)
N_TOTAL=$((N_PROT + N_LIG))

{
    head -1 protein_processed.gro
    echo " $N_TOTAL"
    # protein atom lines (skip header line 1 and atom-count line 2; skip box at end)
    awk "NR>2 && NR<=$(N_PROT+2)" protein_processed.gro
    # ligand atom lines
    awk "NR>2 && NR<=$(N_LIG+2)" lig.gro
    # box vector from protein file
    tail -1 protein_processed.gro
} > complex.gro

log "complex.gro written (${N_TOTAL} atoms: ${N_PROT} protein + ${N_LIG} ligand)."

# ── 4. Update topology to include ligand parameters ───────────────────────────
log "Updating topology to include ligand ITP..."

MOLNAME="${LIGAND_MOLNAME:-LIG}"

# Insert ligand ITP include after the force-field include line
# (CHARMM-GUI ITP may already include its own parameters; we add the include)
FF_INCLUDE_LINE=$(grep -n '#include.*forcefield.itp' topol.top | head -1 | cut -d: -f1)

if [ -z "$FF_INCLUDE_LINE" ]; then
    echo "[WARN] Could not find force-field include in topol.top."
    echo "       Appending ligand ITP include at top of topology."
    # Prepend
    TMP=$(mktemp)
    {
        echo "; Ligand parameters (CHARMM-GUI/CGenFF)"
        echo "#include \"${LIG_ITP}\""
        echo ""
        cat topol.top
    } > "$TMP"
    mv "$TMP" topol.top
else
    # Insert after the force-field include line
    TMP=$(mktemp)
    awk -v line="$FF_INCLUDE_LINE" \
        -v lig_itp="$LIG_ITP" \
        'NR==line {print; print ""; print "; Ligand parameters (CHARMM-GUI/CGenFF)"; print "#include \"" lig_itp "\""; next} {print}' \
        topol.top > "$TMP"
    mv "$TMP" topol.top
fi

# Add ligand molecule count to [ molecules ] section
if grep -q "^${MOLNAME}" topol.top; then
    log "Ligand molecule '${MOLNAME}' already present in [ molecules ] section."
else
    echo "${MOLNAME}              1" >> topol.top
    log "Added '${MOLNAME}   1' to [ molecules ] section."
fi

log "=== Step 01 complete. Outputs in: ${STEP_DIR} ==="
log "    complex.gro | topol.top | posre.itp"
