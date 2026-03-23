# GROMACS Protein–Ligand MD Protocol

> **Reproducible, beginner-friendly, GPU-ready GROMACS 2024.x workflow for
> protein–ligand molecular dynamics simulations.**  
> Clone on an empty GPU node → configure → run end-to-end.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## What this repository does

This repository provides a **complete, step-by-step MD simulation protocol**
for protein–ligand complexes using GROMACS.  
It follows the [MDTutorials protein–ligand complex workflow](http://www.mdtutorials.com/gmx/complex/)
and extends it with:

- Runnable bash scripts for every stage (topology → solvation → EM → NVT →
  NPT → production MD → analysis)
- Fully commented, realistic MDP parameter files
- SLURM GPU job templates for university HPC clusters
- A shared config file so you never have to edit scripts directly
- Beginner-friendly documentation (docs/01–09)
- A strict `.gitignore` that prevents accidental upload of trajectories,
  energies, and other unpublished simulation results

**No simulation results are included.** The repository contains only
templates and instructions.

---

## Quick-start (local GPU node)

```bash
# 1. Clone the repository
git clone https://github.com/jalalkhanutmanzai/gromacs-md-protocol.git
cd gromacs-md-protocol

# 2. Copy and edit the configuration file
cp config/config.env.example config/config.env
$EDITOR config/config.env          # set paths, thread counts, etc.

# 3. Check your environment
bash scripts/00_system_check.sh

# 4. Place your input files (see "Required inputs" below)

# 5. Run each stage
bash scripts/01_prepare_topology.sh
bash scripts/02_solvate_ions.sh
bash scripts/03_em.sh
bash scripts/04_nvt.sh
bash scripts/05_npt.sh
bash scripts/06_md.sh
bash scripts/07_analysis.sh

# Or run everything in one command
bash scripts/run_complete_workflow.sh
```

See [QUICKSTART.md](QUICKSTART.md) for more detail.

---

## Required inputs (user-supplied)

Before running, place the following files in the `input/` directory
(create it with `mkdir -p input`).  
**These files are NOT included** because they are system-specific.

| File | How to obtain |
|---|---|
| `input/protein_clean.pdb` | Download from RCSB PDB; clean with PyMOL / pdbfixer |
| `input/ligand.mol2` (or `.sdf`) | Draw/export from ChemDraw, download from PubChem |
| `input/charmm_ligand/` | Export folder from CHARMM-GUI (contains `.itp`, `.prm`, `.str`) |

See [docs/01_PREREQUISITES.md](docs/01_PREREQUISITES.md) and
[docs/02_TOPOLOGY.md](docs/02_TOPOLOGY.md) for step-by-step instructions.

---

## Directory structure

```
gromacs-md-protocol/
├── config/
│   └── config.env.example      # copy to config/config.env and edit
├── docs/
│   ├── 00_OVERVIEW.md
│   ├── 01_PREREQUISITES.md
│   ├── 02_TOPOLOGY.md
│   ├── 03_SOLVATE_IONS.md
│   ├── 04_EM.md
│   ├── 05_NVT.md
│   ├── 06_NPT.md
│   ├── 07_PRODUCTION_MD.md
│   ├── 08_ANALYSIS.md
│   └── 09_TROUBLESHOOTING.md
├── mdp/
│   ├── em.mdp                  # energy minimisation
│   ├── nvt.mdp                 # NVT equilibration
│   ├── npt.mdp                 # NPT equilibration
│   └── md_100ns.mdp            # production MD (100 ns)
├── scripts/
│   ├── 00_system_check.sh
│   ├── 01_prepare_topology.sh
│   ├── 02_solvate_ions.sh
│   ├── 03_em.sh
│   ├── 04_nvt.sh
│   ├── 05_npt.sh
│   ├── 06_md.sh
│   ├── 07_analysis.sh
│   └── run_complete_workflow.sh
├── templates/
│   └── slurm/
│       └── gmx_gpu.slurm       # SLURM GPU job template
├── work/                       # created at runtime; gitignored
├── results/                    # created at runtime; gitignored
├── INSTALLATION.md
├── QUICKSTART.md
└── README.md                   (this file)
```

---

## Running on an HPC cluster (SLURM)

```bash
# Edit the SLURM template
cp templates/slurm/gmx_gpu.slurm my_job.slurm
$EDITOR my_job.slurm            # set --partition, --account, --gres, etc.

# Submit
sbatch my_job.slurm
```

See [docs/07_PRODUCTION_MD.md](docs/07_PRODUCTION_MD.md) for details on
mapping SLURM resources to `gmx mdrun` flags.

---

## Reproducibility notes

| Item | Value |
|---|---|
| GROMACS version | 2024.3 (tested) |
| Force field | CHARMM36m (protein) + CGenFF (ligand) |
| Water model | TIP3P |
| Random seed | set in `config/config.env` (`GEN_SEED`) |
| MDP files | version-controlled in `mdp/` |

To reproduce a run exactly, record the `config/config.env` you used and the
GROMACS version (`gmx --version`).

---

## What NOT to commit

See `.gitignore` for the full list.  
**Never commit:**
- `*.xtc`, `*.trr`, `*.edr`, `*.cpt`, `*.log`, `*.tpr` — simulation output
- `work/`, `results/` — runtime directories
- `config/config.env` — may contain local paths
- Any system-specific PDB, mol2, or coordinate file that relates to
  unpublished research

---

## Team

- **Jalal Khan Utman** — MS Biotechnology, PAF-IAST
- **Dr. Muhammad Imran Khan** — Assistant Professor, PAF-IAST
- **Miss Tayyaba Ayaz** — AI Developer, Lecturer, PAF-IAST

---

## License

[MIT](LICENSE)

