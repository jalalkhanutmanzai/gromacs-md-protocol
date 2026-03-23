# ─────────────────────────────────────────────────────────────────────────────
# Makefile — Convenience targets for the GROMACS MD Protocol
#
# Usage:
#   make help        Show all available targets
#   make all         Run the full pipeline (steps 01–07)
#   make check       Run system check only
#   make clean       Remove work/ and results/ directories
# ─────────────────────────────────────────────────────────────────────────────

SHELL := /bin/bash
SCRIPTS := scripts

.PHONY: help all check topology solvate em nvt npt md analysis clean config

# ── Default target ────────────────────────────────────────────────────────────
help:
@echo ""
@echo "  GROMACS Protein–Ligand MD Protocol — Make Targets"
@echo "  ══════════════════════════════════════════════════"
@echo ""
@echo "  Setup"
@echo "    make config     Copy config.env.example → config/config.env"
@echo "    make check      Run system check (GROMACS + GPU)"
@echo ""
@echo "  Pipeline stages"
@echo "    make topology   Step 01 — Prepare protein-ligand topology"
@echo "    make solvate    Step 02 — Solvate + add ions"
@echo "    make em         Step 03 — Energy minimisation"
@echo "    make nvt        Step 04 — NVT equilibration"
@echo "    make npt        Step 05 — NPT equilibration"
@echo "    make md         Step 06 — Production MD (100 ns)"
@echo "    make analysis   Step 07 — Analysis (RMSD, RMSF, Rg…)"
@echo ""
@echo "  Full run"
@echo "    make all        Run full pipeline (steps 01–07)"
@echo ""
@echo "  Utilities"
@echo "    make clean      Remove work/ and results/ directories"
@echo "    make env        Create conda environment from environment.yml"
@echo ""

# ── Setup ─────────────────────────────────────────────────────────────────────
config:
@if [ -f config/config.env ]; then \
echo "[INFO] config/config.env already exists. Edit it directly."; \
else \
cp config/config.env.example config/config.env; \
echo "[OK] config/config.env created. Edit it before running simulations."; \
fi

env:
conda env create -f environment.yml
@echo "[OK] Run: conda activate gmx2024"

# ── Pipeline stages ───────────────────────────────────────────────────────────
check:
bash $(SCRIPTS)/00_system_check.sh

topology:
bash $(SCRIPTS)/01_prepare_topology.sh

solvate:
bash $(SCRIPTS)/02_solvate_ions.sh

em:
bash $(SCRIPTS)/03_em.sh

nvt:
bash $(SCRIPTS)/04_nvt.sh

npt:
bash $(SCRIPTS)/05_npt.sh

md:
bash $(SCRIPTS)/06_md.sh

analysis:
bash $(SCRIPTS)/07_analysis.sh

# ── Full pipeline ─────────────────────────────────────────────────────────────
all:
bash $(SCRIPTS)/run_complete_workflow.sh

# ── Utilities ─────────────────────────────────────────────────────────────────
clean:
@echo "[WARN] This will delete work/ and results/ directories."
@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
rm -rf work/ results/
@echo "[OK] Cleaned."
