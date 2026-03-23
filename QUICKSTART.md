# Quick Start

Minimum steps to go from a fresh GPU node to a running simulation.

For full explanations of each step, follow the numbered docs in `docs/`.

---

## 0. Clone and configure

```bash
git clone https://github.com/jalalkhanutmanzai/gromacs-md-protocol.git
cd gromacs-md-protocol

# Copy the example config and edit it
cp config/config.env.example config/config.env
nano config/config.env        # set GMX_BIN, NTOMP, GPU_ID, etc.
```

---

## 1. Check your environment

```bash
bash scripts/00_system_check.sh
```

This verifies GROMACS is installed and a GPU is visible.

---

## 2. Place your input files

```bash
mkdir -p input
# Copy your files here (not tracked by git):
#   input/protein_clean.pdb       — cleaned protein structure
#   input/charmm_ligand/          — CHARMM-GUI/CGenFF export folder
```

See [docs/01_PREREQUISITES.md](docs/01_PREREQUISITES.md) for how to obtain
and clean these files.

---

## 3. Build the topology

```bash
bash scripts/01_prepare_topology.sh
```

This runs `gmx pdb2gmx` on the protein and merges the ligand topology from
CHARMM-GUI. Output goes to `work/01_topology/`.

---

## 4. Solvate and add ions

```bash
bash scripts/02_solvate_ions.sh
```

Adds a water box and neutralises the system with Na⁺/Cl⁻ ions.
Output: `work/02_solvate/`.

---

## 5. Energy minimisation

```bash
bash scripts/03_em.sh
```

Removes steric clashes. Completes in ~2–5 minutes on a GPU.
Output: `work/03_em/`.

---

## 6. NVT equilibration (100 ps)

```bash
bash scripts/04_nvt.sh
```

Heats the system to 300 K at constant volume.
Output: `work/04_nvt/`.

---

## 7. NPT equilibration (100 ps)

```bash
bash scripts/05_npt.sh
```

Equilibrates pressure to 1 bar.
Output: `work/05_npt/`.

---

## 8. Production MD (100 ns)

```bash
bash scripts/06_md.sh
```

Runs the production simulation. On a V100S GPU this takes ~4–8 hours.
Output: `work/06_md/`.

---

## 9. Basic analysis

```bash
bash scripts/07_analysis.sh
```

Calculates RMSD, RMSF, Rg, hydrogen bonds, and SASA.
Output: `results/`.

---

## Run everything in one command

```bash
bash scripts/run_complete_workflow.sh
```

This calls scripts 01–07 in order and logs output to `work/workflow.log`.

---

## HPC / SLURM shortcut

```bash
cp templates/slurm/gmx_gpu.slurm my_job.slurm
# Edit partition/account/time
sbatch my_job.slurm
```

