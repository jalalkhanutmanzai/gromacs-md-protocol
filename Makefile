# Makefile - Convenience targets for the GROMACS MD Protocol
#
# Usage:
#   make help        Show all available targets
#   make all         Run the primary pipeline (steps 01-07, CHARMM-GUI workflow)
#   make acpype-all  Run the ACPYPE/GAFF2 pipeline (steps 01-09)
#   make check       Run system check only
#   make clean       Remove work/, results/, simulation/ directories

SHELL  := /bin/bash
SCRIPT := scripts
ACPYPE := workflows/acpype/scripts

.PHONY: help all check topology solvate em nvt npt md analysis clean config env \
        acpype-all acpype-protein acpype-ligand acpype-topology acpype-solvate \
        acpype-em acpype-nvt acpype-npt acpype-md acpype-analysis

# Default target: help
help:
	@echo ""
	@echo "  GROMACS Protein-Ligand MD Protocol -- Make Targets"
	@echo "  ==================================================="
	@echo ""
	@echo "  Setup:"
	@echo "    make config     Create config/config.env from example"
	@echo "    make check      System check (GROMACS + GPU)"
	@echo "    make env        Create conda environment (gmx2024)"
	@echo ""
	@echo "  Primary workflow (CHARMM-GUI / CGenFF):"
	@echo "    make topology   Step 01 -- Prepare protein-ligand topology"
	@echo "    make solvate    Step 02 -- Solvate + add ions"
	@echo "    make em         Step 03 -- Energy minimisation"
	@echo "    make nvt        Step 04 -- NVT equilibration"
	@echo "    make npt        Step 05 -- NPT equilibration"
	@echo "    make md         Step 06 -- Production MD (100 ns)"
	@echo "    make analysis   Step 07 -- Analysis (RMSD, RMSF, Rg, SASA)"
	@echo "    make all        Run full primary pipeline (steps 01-07)"
	@echo ""
	@echo "  Alternative workflow (ACPYPE / GAFF2):"
	@echo "    make acpype-protein    Step 01 -- Download & clean protein"
	@echo "    make acpype-ligand     Step 02 -- Parameterise ligand"
	@echo "    make acpype-topology   Step 03 -- Build system topology"
	@echo "    make acpype-solvate    Step 04 -- Solvate + add ions"
	@echo "    make acpype-em         Step 05 -- Energy minimisation"
	@echo "    make acpype-nvt        Step 06 -- NVT equilibration"
	@echo "    make acpype-npt        Step 07 -- NPT equilibration"
	@echo "    make acpype-md         Step 08 -- Production MD"
	@echo "    make acpype-analysis   Step 09 -- Analysis"
	@echo "    make acpype-all        Run full ACPYPE pipeline (steps 01-09)"
	@echo ""
	@echo "  Utilities:"
	@echo "    make clean      Remove work/, results/, simulation/"
	@echo ""

# Setup
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

# System check
check:
	bash $(SCRIPT)/00_system_check.sh

# Primary pipeline (CHARMM-GUI / CGenFF)
topology:
	bash $(SCRIPT)/01_prepare_topology.sh

solvate:
	bash $(SCRIPT)/02_solvate_ions.sh

em:
	bash $(SCRIPT)/03_em.sh

nvt:
	bash $(SCRIPT)/04_nvt.sh

npt:
	bash $(SCRIPT)/05_npt.sh

md:
	bash $(SCRIPT)/06_md.sh

analysis:
	bash $(SCRIPT)/07_analysis.sh

all:
	bash $(SCRIPT)/run_complete_workflow.sh

# ACPYPE / GAFF2 alternative workflow
acpype-protein:
	bash $(ACPYPE)/01_prepare_protein.sh

acpype-ligand:
	bash $(ACPYPE)/02_prepare_ligand.sh

acpype-topology:
	bash $(ACPYPE)/03_build_topology.sh

acpype-solvate:
	bash $(ACPYPE)/04_solvation_ions.sh

acpype-em:
	bash $(ACPYPE)/05_energy_minimization.sh

acpype-nvt:
	bash $(ACPYPE)/06_nvt_equilibration.sh

acpype-npt:
	bash $(ACPYPE)/07_npt_equilibration.sh

acpype-md:
	bash $(ACPYPE)/08_production_md.sh

acpype-analysis:
	bash $(ACPYPE)/09_analysis.sh

acpype-all:
	bash $(ACPYPE)/run_complete_workflow.sh

# Clean
clean:
	@echo "[WARN] This will delete work/, results/, and simulation/ directories."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	rm -rf work/ results/ simulation/
	@echo "[OK] Cleaned."
