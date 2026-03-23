#!/usr/bin/env bash
# scripts/07_analysis.sh
# ─────────────────────────────────────────────────────────────────────────────
# Basic trajectory analysis: RMSD, RMSF, Rg, H-bonds, SASA.
#
# Inputs:  work/06_md/md.xtc | md.tpr
# Outputs: results/*.xvg
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${REPO_ROOT}/config/config.env"

if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] config/config.env not found."
    exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

GMX="${GMX_BIN:-gmx}"
MD_DIR="${REPO_ROOT}/${WORK_DIR:-work}/06_md"
RES_DIR="${REPO_ROOT}/${RESULTS_DIR:-results}"
MOLNAME="${LIGAND_MOLNAME:-LIG}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Step 07: Analysis ==="

for f in "${MD_DIR}/md.xtc" "${MD_DIR}/md.tpr"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Required file not found: $f"
        echo "        Run scripts/06_md.sh first."
        exit 1
    fi
done

mkdir -p "$RES_DIR"
cd "$MD_DIR"

# ── 1. Fix PBC ────────────────────────────────────────────────────────────────
log "Removing PBC artefacts and centring protein..."
if [ ! -f md_noPBC.xtc ]; then
    printf "Protein\nSystem\n" | "$GMX" trjconv \
        -s md.tpr \
        -f md.xtc \
        -o md_noPBC.xtc \
        -pbc mol \
        -center \
        2>&1 | tee "${RES_DIR}/trjconv_noPBC.log"
else
    log "md_noPBC.xtc already exists — skipping."
fi

# ── 2. Fit trajectory (remove rotation/translation) ───────────────────────────
log "Fitting trajectory to first frame..."
if [ ! -f md_fit.xtc ]; then
    printf "Backbone\nSystem\n" | "$GMX" trjconv \
        -s md.tpr \
        -f md_noPBC.xtc \
        -o md_fit.xtc \
        -fit rot+trans \
        2>&1 | tee "${RES_DIR}/trjconv_fit.log"
else
    log "md_fit.xtc already exists — skipping."
fi

# ── 3. RMSD — protein backbone ────────────────────────────────────────────────
log "Computing protein backbone RMSD..."
printf "Backbone\nBackbone\n" | "$GMX" rms \
    -s md.tpr \
    -f md_fit.xtc \
    -o "${RES_DIR}/rmsd_protein.xvg" \
    -tu ns \
    2>&1 | tee "${RES_DIR}/rmsd_protein.log"

# ── 4. RMSD — ligand ─────────────────────────────────────────────────────────
log "Computing ligand RMSD (group: ${MOLNAME})..."
# Use Backbone for reference alignment, then measure ligand RMSD
printf "Backbone\n${MOLNAME}\n" | "$GMX" rms \
    -s md.tpr \
    -f md_fit.xtc \
    -o "${RES_DIR}/rmsd_ligand.xvg" \
    -tu ns \
    2>&1 | tee "${RES_DIR}/rmsd_ligand.log" || \
    log "[WARN] Ligand RMSD failed — check that group '${MOLNAME}' exists in the index."

# ── 5. RMSF — backbone ───────────────────────────────────────────────────────
log "Computing backbone RMSF per residue..."
printf "Backbone\n" | "$GMX" rmsf \
    -s md.tpr \
    -f md_fit.xtc \
    -o "${RES_DIR}/rmsf_backbone.xvg" \
    -res \
    2>&1 | tee "${RES_DIR}/rmsf_backbone.log"

# ── 6. Radius of gyration ────────────────────────────────────────────────────
log "Computing radius of gyration..."
printf "Protein\n" | "$GMX" gyrate \
    -s md.tpr \
    -f md_fit.xtc \
    -o "${RES_DIR}/rg.xvg" \
    2>&1 | tee "${RES_DIR}/rg.log"

# ── 7. Hydrogen bonds (protein–ligand) ───────────────────────────────────────
log "Computing protein–ligand hydrogen bonds..."
printf "Protein\n${MOLNAME}\n" | "$GMX" hbond \
    -s md.tpr \
    -f md_fit.xtc \
    -num "${RES_DIR}/hbond_prot_lig.xvg" \
    2>&1 | tee "${RES_DIR}/hbond.log" || \
    log "[WARN] H-bond analysis failed — check group '${MOLNAME}'."

# ── 8. SASA ───────────────────────────────────────────────────────────────────
log "Computing protein SASA..."
printf "Protein\n" | "$GMX" sasa \
    -s md.tpr \
    -f md_fit.xtc \
    -o "${RES_DIR}/sasa.xvg" \
    2>&1 | tee "${RES_DIR}/sasa.log"

log "=== Step 07 complete. Results in: ${RES_DIR} ==="
log "    rmsd_protein.xvg | rmsd_ligand.xvg | rmsf_backbone.xvg"
log "    rg.xvg | hbond_prot_lig.xvg | sasa.xvg"
log "    (All gitignored — do not commit results)"
