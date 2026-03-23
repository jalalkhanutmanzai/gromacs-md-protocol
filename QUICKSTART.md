# Quick Start Guide

Minimum steps to go from a fresh GPU node to a running simulation.  
For full explanations of every step, follow the numbered docs in `docs/`.

---

## Prerequisites

Before starting, ensure you have:
- [ ] GROMACS 2024.x installed (see [INSTALLATION.md](INSTALLATION.md))
- [ ] NVIDIA GPU with CUDA drivers
- [ ] A cleaned protein PDB file
- [ ] Ligand topology from CHARMM-GUI / CGenFF (see [input/README.md](input/README.md))

---

## 0. Clone and Configure

```bash
git clone https://github.com/jalalkhanutmanzai/gromacs-md-protocol.git
cd gromacs-md-protocol

# Copy the example config and edit it
cp config/config.env.example config/config.env
nano config/config.env        # set GMX_BIN, NTOMP, GPU_ID, etc.
```

Or use the Makefile shortcut:

```bash
make config   # creates config/config.env from the example
nano config/config.env
```

---

## 1. Check Your Environment

```bash
bash scripts/00_system_check.sh
# or:
make check
```

This verifies GROMACS is installed and a GPU is visible.  
Fix any `[FAIL]` or `[WARN]` messages before proceeding.

---

## 2. Place Your Input Files

```bash
mkdir -p input
# See input/README.md for exactly what goes here:
#   input/protein_clean.pdb       — cleaned protein structure
#   input/charmm_ligand/          — CHARMM-GUI/CGenFF export folder
```

See [input/README.md](input/README.md) and [docs/01_PREREQUISITES.md](docs/01_PREREQUISITES.md).

---

## 3. Run Each Stage

### Individual steps:

```bash
bash scripts/01_prepare_topology.sh   # Build topology
bash scripts/02_solvate_ions.sh       # Add water + ions
bash scripts/03_em.sh                 # Energy minimisation (~2–5 min)
bash scripts/04_nvt.sh                # NVT equilibration (~5–10 min)
bash scripts/05_npt.sh                # NPT equilibration (~5–10 min)
bash scripts/06_md.sh                 # Production MD 100 ns (~4–10 hrs)
bash scripts/07_analysis.sh           # RMSD, RMSF, Rg, H-bonds, SASA
```

### Or use make:

```bash
make topology && make solvate && make em && make nvt && make npt && make md && make analysis
```

### Or run everything at once:

```bash
bash scripts/run_complete_workflow.sh
# or:
make all
```

Output stages go to `work/01_topology/`, `work/02_solvate/`, …  
Analysis results go to `results/`.  
Full log: `work/workflow.log`

---

## 4. Monitor a Running Simulation

```bash
# Watch the live log
tail -f work/06_md/md.log

# Check GPU usage
watch -n 5 nvidia-smi

# Quick energy check
gmx energy -f work/06_md/md.edr -o /tmp/pot.xvg
```

---

## HPC / SLURM Shortcut

```bash
# Edit the template job script
cp templates/slurm/gmx_gpu.slurm my_job.slurm
nano my_job.slurm    # set --partition, --account, --time, --gres

# Submit
sbatch my_job.slurm

# Monitor
squeue -u $USER
tail -f work/workflow.log
```

---

## Troubleshooting

| Problem | First step |
|---|---|
| Script fails immediately | Check `config/config.env` — are paths correct? |
| GROMACS not found | Is the conda environment active? Run `conda activate gmx2024` |
| GPU not detected | Run `nvidia-smi`; check `GPU_ID` in config |
| EM does not converge | Inspect structure for clashes in PyMOL |
| SLURM job killed | Increase `#SBATCH --time` limit |

Full troubleshooting guide: [docs/09_TROUBLESHOOTING.md](docs/09_TROUBLESHOOTING.md)  
FAQ: [docs/10_FAQ.md](docs/10_FAQ.md)

---

> ⚠️ **If you use this protocol in any capacity, you must cite it.**  
> See [README.md — Citation](README.md#-citation-mandatory) for required formats.
