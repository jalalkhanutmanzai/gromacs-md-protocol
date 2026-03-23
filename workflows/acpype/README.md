# ACPYPE / GAFF2 Workflow

**Alternative workflow using ACPYPE + GAFF2 parameters for the ligand.**

This workflow automatically downloads the protein from RCSB PDB and uses
[ACPYPE](https://github.com/alanwilter/acpype) (wrapping AmberTools `antechamber`)
to generate GAFF2 ligand parameters — no CHARMM-GUI account needed.

> 🔑 **Choose your workflow:**
> - **This workflow (ACPYPE/GAFF2):** ligand parameterised with GAFF2 force field; auto-downloads protein
> - **Primary workflow (CHARMM-GUI/CGenFF):** in `scripts/` + `docs/` at the repo root; ligand from CHARMM-GUI

---

## Prerequisites

```bash
# Install ACPYPE and AmberTools via conda
mamba install -c conda-forge acpype ambertools -y

# Or pip
pip install acpype
```

---

## Quick Start

```bash
# From the repo root:

# 1. Edit the PDB ID and ligand settings in each script header
nano workflows/acpype/scripts/01_prepare_protein.sh   # set PDB_ID, LIGAND_ID
nano workflows/acpype/scripts/02_prepare_ligand.sh    # set LIGAND_CHARGE

# 2. Run each step in order
bash workflows/acpype/scripts/01_prepare_protein.sh
bash workflows/acpype/scripts/02_prepare_ligand.sh
bash workflows/acpype/scripts/03_build_topology.sh
bash workflows/acpype/scripts/04_solvation_ions.sh
bash workflows/acpype/scripts/05_energy_minimization.sh
bash workflows/acpype/scripts/06_nvt_equilibration.sh
bash workflows/acpype/scripts/07_npt_equilibration.sh
bash workflows/acpype/scripts/08_production_md.sh
bash workflows/acpype/scripts/09_analysis.sh

# Or run everything at once
bash workflows/acpype/scripts/run_complete_workflow.sh
```

---

## Step-by-Step Documentation

| Step | Script | Documentation |
|---|---|---|
| 1. Download & clean protein | `scripts/01_prepare_protein.sh` | [docs/01_prepare_protein.md](docs/01_prepare_protein.md) |
| 2. Parameterise ligand | `scripts/02_prepare_ligand.sh` | [docs/02_prepare_ligand.md](docs/02_prepare_ligand.md) |
| 3. Build topology | `scripts/03_build_topology.sh` | [docs/03_build_topology.md](docs/03_build_topology.md) |
| 4. Solvate & add ions | `scripts/04_solvation_ions.sh` | [docs/04_solvation_ions.md](docs/04_solvation_ions.md) |
| 5. Energy minimisation | `scripts/05_energy_minimization.sh` | [docs/05_energy_minimization.md](docs/05_energy_minimization.md) |
| 6. NVT equilibration | `scripts/06_nvt_equilibration.sh` | [docs/06_nvt_equilibration.md](docs/06_nvt_equilibration.md) |
| 7. NPT equilibration | `scripts/07_npt_equilibration.sh` | [docs/07_npt_equilibration.md](docs/07_npt_equilibration.md) |
| 8. Production MD | `scripts/08_production_md.sh` | [docs/08_production_md.md](docs/08_production_md.md) |
| 9. Analysis | `scripts/09_analysis.sh` | [docs/09_analysis.md](docs/09_analysis.md) |
| Troubleshooting | — | [docs/10_troubleshooting.md](docs/10_troubleshooting.md) |

---

## Key Differences from the Primary Workflow

| Feature | Primary (CHARMM-GUI) | This (ACPYPE) |
|---|---|---|
| Ligand force field | CGenFF (CHARMM) | GAFF2 (AMBER) |
| Ligand parameterisation | Manual via CHARMM-GUI website | Automated via `antechamber` |
| Protein source | You supply the PDB | Auto-downloaded from RCSB |
| Configuration | `config/config.env` | Variables at top of each script |
| Suitable for | Any system; publication quality | Quick prototyping; GAFF2-compatible |

---

## Output Directory

Simulation files are written to `simulation/` (gitignored).

---

## Troubleshooting

See [docs/10_troubleshooting.md](docs/10_troubleshooting.md) for common issues.
