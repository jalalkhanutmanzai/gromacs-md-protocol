<div align="center">

# 🧬 GROMACS Protein–Ligand MD Protocol

**Reproducible · Beginner-Friendly · GPU-Ready · HPC-Optimised**

A complete, step-by-step GROMACS 2024.x workflow for protein–ligand molecular dynamics simulations.  
Clone → Configure → Run. Zero guesswork.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GROMACS](https://img.shields.io/badge/GROMACS-2024.3-orange.svg)](https://www.gromacs.org/)
[![Force Field](https://img.shields.io/badge/Force%20Field-CHARMM36m-green.svg)](http://mackerell.umaryland.edu/charmm_ff.shtml)
[![Water Model](https://img.shields.io/badge/Water-TIP3P-blue.svg)](https://www.gromacs.org/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20HPC-lightgrey.svg)](INSTALLATION.md)
[![GPU](https://img.shields.io/badge/GPU-CUDA%20Accelerated-76b900.svg)](INSTALLATION.md)
[![Cite](https://img.shields.io/badge/Citation-Required-red.svg)](#-citation-mandatory)

</div>

---

## 📋 Table of Contents

1. [What This Repository Does](#-what-this-repository-does)
2. [Workflow at a Glance](#-workflow-at-a-glance)
3. [Quick Start](#-quick-start)
4. [Required Inputs](#-required-inputs)
5. [Directory Structure](#-directory-structure)
6. [Running on HPC (SLURM)](#-running-on-hpc-slurm)
7. [Reproducibility](#-reproducibility)
8. [What NOT to Commit](#-what-not-to-commit)
9. [Citation (Mandatory)](#-citation-mandatory)
10. [Contributing](#-contributing)
11. [Team](#-team)
12. [License](#-license)

---

## 🔬 What This Repository Does

This repository provides a **complete, production-ready MD simulation protocol** for protein–ligand complexes using GROMACS, following the [MDTutorials protein–ligand workflow](http://www.mdtutorials.com/gmx/complex/) and extending it with:

| Feature | Details |
|---|---|
| 🖥️ **Runnable bash scripts** | One script per stage — no manual commands needed |
| ⚙️ **Realistic MDP files** | Fully commented parameter files for EM, NVT, NPT, production |
| 🏫 **HPC templates** | SLURM job scripts for university GPU clusters |
| 📁 **Shared config** | One `config.env` file — edit once, all scripts inherit |
| 📚 **Step-by-step docs** | Ten numbered guides covering every stage |
| 🔒 **Smart `.gitignore`** | Prevents accidental upload of trajectories and results |
| 📦 **Conda environment** | `environment.yml` for exact reproducibility |
| 🔀 **Two complete workflows** | CHARMM-GUI/CGenFF (primary) + ACPYPE/GAFF2 (alternative) |

### Choose Your Workflow

| Workflow | Ligand Parameters | Best For |
|---|---|---|
| **Primary — CHARMM-GUI/CGenFF** | CGenFF (high accuracy, manually via website) | Publications, research-grade simulations |
| **Alternative — ACPYPE/GAFF2** | GAFF2 (automated via `antechamber`) | Quick prototyping, learning, scripted pipelines |

See [`workflows/acpype/README.md`](workflows/acpype/README.md) for the ACPYPE workflow.

> **No simulation results are included.**  
> This repository contains only templates, scripts, and documentation.

---

## 🔄 Workflow at a Glance

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │            GROMACS Protein–Ligand MD Protocol — Full Pipeline           │
 └─────────────────────────────────────────────────────────────────────────┘

   INPUT FILES                         PROCESSING STAGES
   ───────────                         ──────────────────

   protein_clean.pdb  ──────────────► [01] Prepare Topology
   charmm_ligand/ ──────────────────►       pdb2gmx + merge ligand ITP
                                              │
                                              ▼
                                     [02] Solvate & Add Ions
                                           editconf + solvate + genion
                                              │
                                              ▼
                                     [03] Energy Minimisation
                                           grompp + mdrun (EM)
                                              │
                                              ▼
                                     [04] NVT Equilibration  (100 ps)
                                           grompp + mdrun (NVT)
                                              │
                                              ▼
                                     [05] NPT Equilibration  (100 ps)
                                           grompp + mdrun (NPT)
                                              │
                                              ▼
                                     [06] Production MD      (100 ns)
                                           grompp + mdrun
                                              │
                                              ▼
   results/ ◄──────────────────────  [07] Analysis
                                           RMSD · RMSF · Rg · H-bonds · SASA
```

---

## 🚀 Quick Start

### Step 0 — Install GROMACS

See **[INSTALLATION.md](INSTALLATION.md)** for three installation methods:
- `apt` (Ubuntu/Debian)
- Conda / Mamba *(recommended)*
- Apptainer / Singularity *(best for HPC)*

> **TL;DR (conda):**
> ```bash
> mamba create -n gmx2024 -c conda-forge gromacs=2024.3 cudatoolkit=12.2 -y
> conda activate gmx2024
> ```

---

### Step 1 — Clone and Configure

```bash
# Clone the repository
git clone https://github.com/jalalkhanutmanzai/gromacs-md-protocol.git
cd gromacs-md-protocol

# Copy and edit the config file (set paths, thread counts, GPU IDs)
cp config/config.env.example config/config.env
nano config/config.env
```

> **Key settings in `config.env`:**
>
> | Variable | What it sets |
> |---|---|
> | `GMX_BIN` | Path to `gmx` executable |
> | `NTOMP` | CPU threads per GPU |
> | `GPU_ID` | GPU device ID (usually `0`) |
> | `FF_NAME` | Force field (`charmm36-jul2022`) |
> | `GEN_SEED` | Random seed for reproducibility |

---

### Step 2 — Check Your Environment

```bash
bash scripts/00_system_check.sh
```

This verifies that GROMACS is installed, a GPU is visible, and your config
is loaded correctly.

---

### Step 3 — Add Your Input Files

```bash
mkdir -p input
# Place these files (see input/README.md for details):
#   input/protein_clean.pdb       — cleaned protein structure
#   input/charmm_ligand/          — CHARMM-GUI/CGenFF export folder
```

See **[input/README.md](input/README.md)** and **[docs/01_PREREQUISITES.md](docs/01_PREREQUISITES.md)**.

---

### Step 4 — Run the Pipeline

**Option A — Run each stage individually:**

```bash
bash scripts/01_prepare_topology.sh   # Build protein-ligand topology
bash scripts/02_solvate_ions.sh       # Add water box + ions
bash scripts/03_em.sh                 # Energy minimisation
bash scripts/04_nvt.sh                # NVT equilibration (100 ps)
bash scripts/05_npt.sh                # NPT equilibration (100 ps)
bash scripts/06_md.sh                 # Production MD (100 ns)
bash scripts/07_analysis.sh           # RMSD, RMSF, Rg, H-bonds, SASA
```

**Option B — Run everything at once:**

```bash
bash scripts/run_complete_workflow.sh
# Logs everything to work/workflow.log
```

**Option C — Use `make` shortcuts:**

```bash
make check      # system check
make topology   # step 01
make solvate    # step 02
make em         # step 03
make nvt        # step 04
make npt        # step 05
make md         # step 06
make analysis   # step 07
make all        # full pipeline (01–07)
make help       # show all commands
```

See **[QUICKSTART.md](QUICKSTART.md)** for the full walkthrough.

---

## 📂 Required Inputs

Before running, place the following files in the `input/` directory.  
**These are NOT included** — they are system-specific.

| File | Format | How to Obtain |
|---|---|---|
| `input/protein_clean.pdb` | PDB | [RCSB PDB](https://www.rcsb.org/); clean with [PyMOL](https://pymol.org/) or [pdbfixer](https://github.com/openmm/pdbfixer) |
| `input/charmm_ligand/lig_ini.pdb` | PDB | [CHARMM-GUI](https://charmm-gui.org/) → Ligand Reader |
| `input/charmm_ligand/lig.itp` | ITP | From CHARMM-GUI CGenFF output folder |
| `input/charmm_ligand/lig.prm` | PRM | From CHARMM-GUI CGenFF output folder |

> 📖 Full instructions in **[docs/01_PREREQUISITES.md](docs/01_PREREQUISITES.md)** and **[docs/02_TOPOLOGY.md](docs/02_TOPOLOGY.md)**.

---

## 📁 Directory Structure

```
gromacs-md-protocol/
│
├── 📄 README.md                   ← You are here
├── 📄 QUICKSTART.md               ← Minimal quick-start guide
├── 📄 INSTALLATION.md             ← GROMACS install (apt / conda / container)
├── 📄 CONTRIBUTING.md             ← How to contribute
├── 📄 CHANGELOG.md                ← Version history
├── 📄 CITATION.cff                ← Machine-readable citation (GitHub auto-detect)
├── 📄 LICENSE                     ← MIT License
├── 📄 Makefile                    ← Convenience targets (make all, make check…)
├── 📄 environment.yml             ← Conda environment for exact reproducibility
│
├── 📁 config/
│   └── config.env.example         ← Copy → config/config.env and edit
│
├── 📁 docs/
│   ├── 00_OVERVIEW.md             ← Protocol overview and philosophy
│   ├── 01_PREREQUISITES.md        ← Software and input file requirements
│   ├── 02_TOPOLOGY.md             ← Building the protein–ligand topology
│   ├── 03_SOLVATE_IONS.md         ← Solvation and ion placement
│   ├── 04_EM.md                   ← Energy minimisation
│   ├── 05_NVT.md                  ← NVT equilibration
│   ├── 06_NPT.md                  ← NPT equilibration
│   ├── 07_PRODUCTION_MD.md        ← Production MD run + HPC tips
│   ├── 08_ANALYSIS.md             ← Post-simulation analysis
│   ├── 09_TROUBLESHOOTING.md      ← Common errors and fixes
│   └── 10_FAQ.md                  ← Frequently asked questions
│
├── 📁 input/                      ← User-supplied files (gitignored)
│   └── README.md                  ← What to place here and how to obtain it
│
├── 📁 mdp/
│   ├── em.mdp                     ← Energy minimisation parameters
│   ├── nvt.mdp                    ← NVT equilibration parameters
│   ├── npt.mdp                    ← NPT equilibration parameters
│   └── md_100ns.mdp               ← Production MD parameters (100 ns)
│
├── 📁 scripts/
│   ├── 00_system_check.sh         ← Verify GROMACS + GPU
│   ├── 01_prepare_topology.sh     ← pdb2gmx + ligand merge
│   ├── 02_solvate_ions.sh         ← Solvate + add ions
│   ├── 03_em.sh                   ← Energy minimisation
│   ├── 04_nvt.sh                  ← NVT equilibration
│   ├── 05_npt.sh                  ← NPT equilibration
│   ├── 06_md.sh                   ← Production MD
│   ├── 07_analysis.sh             ← RMSD, RMSF, Rg, H-bonds, SASA
│   └── run_complete_workflow.sh   ← Run all steps end-to-end
│
├── 📁 templates/
│   └── slurm/
│       └── gmx_gpu.slurm          ← SLURM GPU job template for HPC
│
├── 📁 workflows/
│   └── acpype/                    ← Alternative workflow: ACPYPE + GAFF2 ligand params
│       ├── README.md              ← ACPYPE workflow overview and quick start
│       ├── scripts/               ← Scripts 01–09 + run_complete_workflow.sh
│       └── docs/                  ← Step-by-step docs for each ACPYPE stage
│
├── 📁 work/                       ← Created at runtime; gitignored
└── 📁 results/                    ← Created at runtime; gitignored
```

---

## 🏫 Running on HPC (SLURM)

```bash
# 1. Copy and edit the job template
cp templates/slurm/gmx_gpu.slurm my_job.slurm
nano my_job.slurm    # set --partition, --account, --time, --gres

# 2. Submit the job
sbatch my_job.slurm

# 3. Monitor
squeue -u $USER
tail -f work/workflow.log
```

See **[docs/07_PRODUCTION_MD.md](docs/07_PRODUCTION_MD.md)** for details on
mapping SLURM resources to `gmx mdrun` flags (`-ntomp`, `-ntmpi`, `-gpu_id`).

---

## 🔁 Reproducibility

| Parameter | Value |
|---|---|
| GROMACS version | 2024.3 |
| Force field | CHARMM36m (protein) + CGenFF (ligand) |
| Water model | TIP3P |
| Box type | Dodecahedron, 1.0 nm from solute |
| Salt concentration | 0.15 M NaCl |
| Random seed | Set via `GEN_SEED` in `config.env` |
| MDP files | Version-controlled in `mdp/` |
| Conda environment | Pinned in `environment.yml` |

To reproduce a run exactly:
1. Record `config/config.env`
2. Record `gmx --version` output
3. Use `environment.yml` to rebuild the exact conda environment

```bash
# Rebuild environment from lock file
conda env create -f environment.yml
conda activate gmx2024
```

---

## 🚫 What NOT to Commit

See `.gitignore` for the full list. **Never commit:**

| Type | Examples |
|---|---|
| Simulation output | `*.xtc`, `*.trr`, `*.edr`, `*.cpt`, `*.tpr` |
| Runtime directories | `work/`, `results/` |
| Local config | `config/config.env` (may contain local paths) |
| Unpublished structures | System-specific PDB, mol2, sdf files |
| Analysis plots | `*.xvg`, `*.png`, `*.pdf` from results |

---

## 📜 Citation (Mandatory)

> ⚠️ **If you use this repository — in whole or in part — for any purpose
> (research, teaching, derivative software, publications, presentations, or any
> other work), you MUST cite it.**  
> Citation is a **condition of use** under the repository license.

### How to Cite

**APA (7th edition)**

> Khan Utman, J., Khan, M. I., & Riyaz, T. (2026).
> *GROMACS protein–ligand MD protocol* [Software].
> GitHub. https://github.com/jalalkhanutmanzai/gromacs-md-protocol

**BibTeX**

```bibtex
@software{khan_utman_gromacs_md_protocol,
  author       = {Khan Utman, Jalal and Khan, Muhammad Imran and Riyaz, Tayyaba},
  title        = {{GROMACS Protein--Ligand MD Protocol}},
  year         = {2026},
  publisher    = {GitHub},
  url          = {https://github.com/jalalkhanutmanzai/gromacs-md-protocol},
  note         = {Accessed: \today}
}
```

**IEEE**

> J. Khan Utman, M. I. Khan, and T. Riyaz, "GROMACS Protein–Ligand MD
> Protocol," GitHub, 2026. [Online]. Available:
> https://github.com/jalalkhanutmanzai/gromacs-md-protocol

> 💡 A machine-readable `CITATION.cff` file is included.  
> GitHub shows a **"Cite this repository"** button at the top of the page
> that generates formatted citations automatically — no manual typing needed.

---

## 🤝 Contributing

Contributions are welcome! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:
- How to report bugs
- How to suggest improvements
- Code style and PR guidelines
- What kinds of contributions are most useful

---

## 👥 Team

| Name | Role | Affiliation | Contribution |
|---|---|---|---|
| **Jalal Khan Utman** | MS Biotechnology Student | PAF-IAST, Pakistan | Lead developer — designed the full protocol, wrote all scripts and MDP files, authored all documentation, built and maintains the repository |
| **Dr. Muhammad Imran Khan** | Assistant Professor | PAF-IAST, Pakistan | Academic supervisor — provided scientific direction, validated methodology, oversaw the project |
| **Tayyaba Riyaz** | AI Developer, Lecturer | PAF-IAST, Pakistan | Contributed AI-assisted documentation, troubleshooting guides, and workflow testing |

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

> Note: The MIT License permits reuse, but **citation is additionally required**
> as a condition of use. See the [Citation](#-citation-mandatory) section above.

---

<div align="center">

Made with ❤️ at **PAF-IAST, Pakistan**

(Pak-Austria Fachhochschule: Institute of Applied Sciences and Technology is a public science and technology university located in Mang, Haripur, Khyber Pakhtunkhwa.)

</div>
